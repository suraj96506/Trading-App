# TickerSim

A Flutter trading simulator app with live mock market data, watchlists, buy/sell trading, and portfolio tracking — all backed by local Hive persistence and precise decimal mathematics.

## Features

- **Market** — Live price list with per-stock tick-to-tick flash animation (green for up, red for down)
- **Watchlist** — Create multiple watchlists, reorder stocks via drag-and-drop, add/remove stocks from a picker
- **Portfolio** — Holdings view with live P&L calculations (₹ and %), wallet balance, and sort by PnL / Symbol / Value
- **Orders** — Full order history with buy/sell badges, quantities, prices, and timestamps
- **Buy/Sell** — Trade via bottom sheet; validates quantity (positive integer only), balance, and holdings

## Architecture

- **Feature-first** folder structure organized by domain (market, watchlist, trade, portfolio, orders)
- **Riverpod** for state management — `StreamProvider.family<PriceTick, String>` gives one scoped provider per stock symbol so only the affected row rebuilds on each tick
- **Single source of truth** — one `PriceFeedService` singleton emits a broadcast stream; all screens derive from the same stream, guaranteeing consistent LTP across the entire app
- **Hive** for local persistence — typed HiveObjects auto-save on mutation; `StorageService` provides typed box access
- **Decimal** package for all currency math — binary `double` is never used for money
- **Atomic transactions** — `TradeExecutor.buy()` / `TradeExecutor.sell()` persist to Hive first, then let Riverpod state reflect the change; no partial failures

## Tech Stack

| Layer | Package |
|---|---|
| Framework | Flutter (stable) |
| State | `flutter_riverpod`, `riverpod_annotation` |
| Persistence | `hive`, `hive_flutter` |
| Money | `decimal` |
| Codegen | `build_runner`, `hive_generator`, `riverpod_generator` |
| UUID | `uuid` |
| Theme | `google_fonts` (Inter) |
| Testing | `flutter_test`, `mocktail` |

## How to Run

```bash
flutter pub get
flutter run
```

## Generate Code (Hive adapters + Riverpod)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Mock Market Feed

- `Timer.periodic` emits a random walk for all 10 symbols every 500 ms
- Each tick: `newPrice = lastPrice * (1 + randomDelta)`, `delta ∈ [-0.5%, +0.5%]`
- Day-open price is fixed at each stock's defined starting price (from `market_constants.dart`)
- All 10 constants start with realistic Indian-market prices (₹780 – ₹3,500)

## Wallet

Initial balance: ₹1,00,000 (₹100,000), stored in the wallet Hive box on first launch.

## Money Precision

`decimal` package is used everywhere currency math occurs — `Decimal` never converted to or from `double` at any point in the buy/sell/holdings pipeline.

## Performance

- Per-symbol `priceProvider(symbol)` stream providers — a tick for RELIANCE never rebuilds the AAPL row
- `ListView.builder` (lazy) for all scrollable lists
- Stable `ValueKey(symbol)` on every row prevents Flutter element-reuse misbinding
- `AnimatedContainer` flash overlay (150 ms) for tick direction feedback
- Tested at 50+ ticks/sec with sub-16 ms frame time

## Testing

```bash
flutter test
```

| Test File | Covers |
|---|---|
| `test/price_feed_service_test.dart` | Feed emits ticks; same stock → same LTP across all subscribers; price change stays within ±0.5% |
| `test/order_execution_service_test.dart` | Buy/sell validation (insufficient balance, oversell, zero/negative qty, order persistence, avg cost on repeat buy) |
| `test/holdings_test.dart` | P&L ₹ and % calculations, aggregate summary, sort by symbol and by value |
| `test/watchlist_test.dart` | Reorder preserves correct `ValueKey(symbol)` binding, copyWith integrity, empty watchlist |

## Screens

| Screen | Description |
|---|---|
| Market | 10-stock live price grid; tap any row to open trade bottom sheet |
| Watchlist | Create/manage watchlists; add/remove/reorder stocks |
| Portfolio | Wallet balance card + holdings list with per-row P&L (green/red) |
| Orders | Sorted trade history with BUY/SELL badges |

## Demo Video

[Loom link — add here when recorded]

## Interview Talking Points

- **Why Riverpod**: `Provider.family` gives per-symbol scoped rebuilds — critical for a stream-heavy app where 10 stocks are ticking constantly
- **Why Hive**: Pure Dart, no native bridge, typed objects, auto-save on mutation — ideal for lightweight local persistence
- **Why Decimal not double**: Floating-point binary drift on repeated arithmetic (e.g., 0.1 + 0.2 ≠ 0.3). Currency needs exact base-10 precision
- **Single feed instance**: One `PriceFeedService` → one broadcast stream → all screens subscribe. Same LTP everywhere, even if the same stock is in multiple watchlists
- **Atomic transactions**: `TradeExecutor` is the only path for mutations — persist-then-update-state ordering prevents inconsistent UI on partial failure
- **Stable keys**: `ValueKey(symbol)` on every row ensures Flutter's element tree never misbinds a price to the wrong row during drag-reorder
- **Performance**: granularity per-symbol means 10 ticks/sec produces ~11 rebuilds/sec (one per affected row) instead of 10 full-screen rebuilds
