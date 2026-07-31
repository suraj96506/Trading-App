# TickerSim — Architecture & Design Document

## 1. Goal

Build a Flutter trading simulator app with 4 core features — Watchlist, Live Prices Mimic, Buy/Sell Ticket, Holdings — all backed by a single mock market-data feed, with local persistence, real-time UI updates under load, and precise decimal/money handling. No real backend.

---

## 2. Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Framework | Flutter (stable channel) | Required by spec |
| State Management | **Riverpod** (`flutter_riverpod`, `riverpod_annotation`) | Compile-safe DI, granular rebuilds via fine-grained providers, native `StreamProvider` support |
| Local Persistence | **Hive** (`hive`, `hive_flutter`) | Pure Dart, no native bridge overhead, stores typed Dart objects directly |
| Money/Decimal | **decimal** package (`decimal`) | Avoids floating-point drift for currency math |
| Code generation | `build_runner`, `hive_generator`, `riverpod_generator` | Type adapters + provider codegen |
| UUID | `uuid` | Unique IDs for watchlists, orders |
| Navigation | Flutter's built-in `Navigator` | No routing package needed — app has few screens, `go_router` is overkill |
| Testing | `flutter_test`, `mocktail` | Unit tests for feed, order execution, holdings, watchlist |

---

## 3. State Management — Riverpod (Justification)

- **Bloc**: too much boilerplate (event + state + bloc class per feature) for a stream-heavy app.
- **Provider (legacy)**: lacks compile-time safety, awkward combining multiple streams.
- **GetX**: hides state via service locator, hurts readability grading.
- **Riverpod wins**: `family` providers give one scoped provider per stock symbol, so only the widget watching that symbol rebuilds on tick — this is the backbone of the whole performance strategy (see §5).

---

## 4. Architecture Style

Feature-first folder structure. Buy/Sell + wallet + holdings + orders are **one transaction domain**, so they live together under `features/trading/`, not split across unrelated folders.

```
lib/
  main.dart
  core/
    models/
      price_tick.dart         // symbol, ltp, change, changePercent, timestamp
      watchlist.dart           // id, name, List<String> symbols (ordered)
    constants/
      market_constants.dart    // the 10 stock symbols + starting prices
    services/
      price_feed_service.dart  // mock tick generator — SINGLE singleton source of truth
      storage_service.dart     // Hive box init + typed read/write helpers
    utils/
      money.dart                // Decimal helpers, INR formatting
  features/
    watchlist/
      providers/watchlist_provider.dart
      screens/watchlist_list_screen.dart
      screens/watchlist_detail_screen.dart
      widgets/stock_picker_sheet.dart
      widgets/watchlist_row.dart
    market/
      providers/price_provider.dart
      screens/market_screen.dart
      widgets/price_cell.dart
      widgets/flash_price_text.dart
    trading/
      domain/
        order.dart
        wallet.dart
        holding.dart
      providers/
        wallet_provider.dart
        holdings_provider.dart
        order_history_provider.dart
      services/
        order_execution_service.dart   // atomic buy/sell entry point
      screens/
        buy_sell_screen.dart
        order_confirmation_screen.dart
      widgets/
        holding_row.dart
    holdings/
      screens/holdings_screen.dart      // reads trading providers, own screen-level sort/UI
  shared/
    widgets/
      empty_state.dart
      section_header.dart
test/
  price_feed_service_test.dart
  order_execution_service_test.dart
  holdings_test.dart
  watchlist_test.dart
```

---

## 5. Data Flow

### 5.1 Price Feed — single stream, not a shared Map

Official design (not optional): the feed emits **individual ticks**, not a giant `Map<String, PriceTick>`. A shared map, even watched with `select()`, risks over-rebuilding if not handled carefully. A per-symbol stream/provider avoids that risk entirely.

```
PriceFeedService (singleton, Timer.periodic, configurable interval)
        │  emits individual PriceTick(symbol, ltp, change, changePercent)
        ▼
priceStreamProvider  (StreamProvider<PriceTick>, broadcast)
        │
        ▼
priceProvider(symbol)  ── Provider.family, derived/filtered from the one stream
        │
        ├──> Watchlist row (ref.watch(priceProvider('RELIANCE')))
        ├──> Market screen cell
        ├──> Buy/Sell ticket live LTP
        └──> Holdings row (P&L calc)
```

Critical point: there is **one** `PriceFeedService` instance, created once (e.g. via `main.dart` / top-level provider), started once. It must **not** be created inside individual screens — otherwise Market screen, Watchlist, and Ticket could each spin up independent feeds and prices would diverge between screens. `priceProvider(symbol)` for every symbol all derive from that same single stream, which is what guarantees identical LTP when the same stock appears in two watchlists.

Lifecycle:
```
ProviderScope
    ↓
priceFeedServiceProvider (singleton)
    ↓
.start() called once at app boot
    ↓
Timer.periodic ticks continuously
    ↓
disposed only when app/ProviderScope dies
```

### 5.2 Buy/Sell Flow — atomic via OrderExecutionService

Wallet, holdings, and order history must update as **one transaction**, not three independent notifier calls — otherwise a partial failure (e.g. wallet deducted but holding update fails) leaves inconsistent state.

```
User taps row (Watchlist/Holdings)
   → navigate to BuySellScreen(prefilledSymbol)
   → screen watches priceProvider(symbol) for live LTP
   → user enters side + qty
   → on submit → OrderExecutionService.executeOrder(symbol, side, qty)
        1. validate (qty > 0, integer, balance/holding check) — Decimal math
        2. calculate order value = qty * ltp (at submit time)
        3. persist first: write updated wallet/holding/order to Hive
        4. only after persist succeeds → update in-memory Riverpod state
        5. publish updated state → UI reacts
   → navigate to ConfirmationScreen
```

Persist-then-update-state ordering avoids the UI ever showing a "successful" order that didn't actually get saved.

### 5.3 Startup Hydration (explicit sequence)

```
StorageService.init()
        ↓
Hive boxes opened
        ↓
load persisted watchlists / holdings / wallet / orders
        ↓
hydrate corresponding providers with loaded data
        ↓
PriceFeedService.start()
        ↓
render App UI (splash/loading gate until hydration completes)
```

This avoids a race where UI briefly shows a default wallet balance before the real persisted balance loads in.

---

## 6. Feature-by-Feature Notes

### Watchlist
- `Watchlist` model stores an ordered list of symbols. Reorder just reorders this list.
- Each row wrapped with `KeyedSubtree(key: ValueKey(symbol), child: WatchlistRow(...))` — **explicit stable key by symbol**, not by list index. This is what prevents the exact bug the assignment tests for: a price appearing on the wrong row after drag-reorder, because Flutter reused an element keyed by position instead of identity.
- Stock picker shows all 10 constants from `market_constants.dart`; checkmark ones already added.
- Empty state shown when `symbols.isEmpty`.

### Live Prices Mimic (Market screen)
- `PriceFeedService` uses `Timer.periodic(Duration(milliseconds: tickIntervalMs))`.
- Random walk: `newPrice = lastPrice * (1 + randomDelta)`, delta bounded (e.g. ±0.5%).
- **Day-open price is fixed at each stock's defined starting price** (from `market_constants.dart`), kept in memory only — not persisted, not recomputed on restart. `change = ltp - dayOpen`, `change% = change / dayOpen * 100`. This keeps change% deterministic and meaningful within a session; day-open resetting on restart is acceptable since the assignment doesn't require persisting it.
- Flash color logic compares **tick-to-tick**, not sign of change%: `newLtp.compareTo(previousLtp)` — a stock can be up overall (positive change%) but tick down on a given update, and the flash must reflect the immediate tick direction, not the cumulative change.
- Tick rate configurable via a constant (`kTickIntervalMs`).

### Buy/Sell Ticket
- All money math via `Decimal` — never raw `double`.
- Quantity rule stated explicitly: **required, > 0, integer only, no fractional quantities** (documented in README as an intentional design choice for a stock-trading simulator).
- Order value recalculated at submit time, not at form-open time.
- Average cost on repeat buys: `newAvgCost = ((oldQty * oldAvgCost) + (buyQty * buyPrice)) / (oldQty + buyQty)`.
- Inline validation errors under each field; submit disabled until valid.
- Entire mutation goes through `OrderExecutionService.executeOrder(...)` — screen/UI never calls wallet/holdings notifiers directly.

### Holdings
- P&L (₹) = `(ltp - avgCost) * qty`; P&L (%) = `((ltp - avgCost) / avgCost) * 100`.
- Sorting via a `sortOption` provider (enum: byPnl, bySymbol, byValue), re-sort happens reactively as prices tick.
- With a max of 10 holdings, re-sorting on every tick is cheap — no extra optimization needed here.
- Aggregate summary computed by folding over the current holdings list + live prices on every rebuild, so it's always consistent with individual rows.
- Holding removed automatically when qty reaches 0 after a Sell.

---

## 7. Performance Strategy

- Per-symbol `priceProvider(symbol)` scoping — a tick for RELIANCE never rebuilds the TCS row.
- `const` constructors wherever static (icons, row chrome).
- No `setState` at screen level for price updates — only Riverpod-managed granular providers trigger rebuilds.
- `ListView.builder` (lazy) everywhere.
- Stable `ValueKey(symbol)` on all rows so Flutter's element reuse never mismatches a row with the wrong stock's data during reorder/remove/insert.

---

## 8. Error & Edge Case Handling Summary

| Case | Handling |
|---|---|
| Empty watchlist | Empty-state widget |
| Insufficient balance | Inline error, submit blocked |
| Oversell | Inline error, submit blocked |
| Zero/negative/fractional qty | Validation blocks submit before any mutation |
| App restart | Hive hydration completes before UI renders (loading gate) |
| Same stock, multiple watchlists | Single feed instance, single stream → identical price everywhere |
| Navigate away and back | Feed keeps running in background (singleton, not screen-scoped) — returning shows current tick, never stale |
| Partial transaction failure | Persist-then-update-state ordering in `OrderExecutionService` prevents inconsistent state |

---

## 9. Testing Plan

Not optional — directly demonstrates "correct realtime behavior," "money/decimal handling," and "error/edge-case handling" from the grading rubric.

```
test/
  price_feed_service_test.dart
    - same stock → same LTP across multiple subscribers
  order_execution_service_test.dart
    - buy → wallet decreases by qty*ltp
    - buy → avg price calculated correctly on repeat buy
    - sell → holding qty decreases
    - sell more than held → rejected
    - insufficient balance → rejected
    - zero qty → rejected
    - negative qty → rejected
    - fractional qty → rejected
    - qty reduced to zero → holding removed
  holdings_test.dart
    - aggregate summary equals sum of rows
    - sort order updates correctly as prices move
  watchlist_test.dart
    - reorder → price stays bound to correct symbol
```

Run with: `flutter test`

---

## 10. Stock Constants (example)

```dart
// core/constants/market_constants.dart
final Map<String, Decimal> kStartingPrices = {
  'RELIANCE': Decimal.parse('1400'),
  'TCS': Decimal.parse('3200'),
  'INFY': Decimal.parse('1500'),
  'HDFCBANK': Decimal.parse('1650'),
  'ICICIBANK': Decimal.parse('1100'),
  'SBIN': Decimal.parse('780'),
  'ITC': Decimal.parse('420'),
  'LT': Decimal.parse('3500'),
  'BHARTIARTL': Decimal.parse('1300'),
  'AXISBANK': Decimal.parse('1050'),
};

const kInitialWalletBalance = '100000'; // ₹1,00,000, parsed as Decimal at wallet init
```

Not real market prices — reasonable mock values, as the assignment allows.

---

## 11. Commands

```
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
flutter test
```

## 12. Packages (pubspec.yaml summary)

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  hive: ^2.x
  hive_flutter: ^1.x
  decimal: ^2.x
  uuid: ^4.x

dev_dependencies:
  build_runner: ^2.x
  hive_generator: ^2.x
  riverpod_generator: ^2.x
  mocktail: ^1.x
  flutter_test:
    sdk: flutter
```

---

## 13. README.md Outline (required for submission)

```
# TickerSim

## Features
Watchlist / Market / Buy-Sell / Holdings — one line each

## Architecture
Feature-first, Riverpod, single price feed, Hive persistence

## Tech Stack
Flutter, Riverpod, Hive, decimal

## How to Run
flutter pub get
flutter run

## Generate Code
flutter pub run build_runner build --delete-conflicting-outputs

## Mock Market Feed
tick frequency, starting prices, random-walk logic

## Wallet
initial balance (₹1,00,000)

## Money Precision
Decimal used everywhere for currency math

## Performance
per-symbol providers, tested at 50+ ticks/sec

## Testing
flutter test

## Screens
Watchlist, Market, Buy/Sell, Holdings

## Demo Video
[Loom link]
```

---

## 14. Interview Talking Points (quick recall)

- **Why Riverpod**: `family` providers give per-symbol scoped rebuilds — critical for a stream-heavy, high-tick-rate app.
- **Why Hive**: pure Dart, fast, typed objects, no schema migration overhead for this data shape.
- **Why Decimal not double**: currency math needs exact base-10 precision; binary floats drift on repeated arithmetic.
- **Single source of truth**: one `PriceFeedService` singleton, one stream, all screens derive from it — guarantees consistent prices everywhere.
- **Atomic transactions**: `OrderExecutionService` is the only path that mutates wallet/holdings/orders — persist-then-update-state ordering avoids inconsistent state on partial failure.
- **Stable keys**: `ValueKey(symbol)` on every row prevents Flutter element reuse from misbinding price data during reorder.
- **Perf under load**: per-symbol providers + `ListView.builder` + `const` widgets = only what changed re-renders, tested at 50+ ticks/sec.
