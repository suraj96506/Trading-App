import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'watchlist_screen_state.dart';

/// StateNotifier that manages the state of the Watchlist screen.
class WatchlistScreenNotifier extends StateNotifier<WatchlistScreenState> {
  WatchlistScreenNotifier() : super(const WatchlistScreenState());

  /// Synchronize provider state with the given [watchlist].
  void syncWithWatchlist(Watchlist watchlist) {
    if (state.currentWatchlistId != watchlist.id) {
      state = state.copyWith(
        currentWatchlistId: watchlist.id,
        symbols: List.from(watchlist.symbols),
        savedSymbols: List.from(watchlist.symbols),
        hasUnsavedChanges: false,
      );
    }
  }

  /// Create a new watchlist with a default name.
  Future<void> createNewWatchlist(int currentCount, BuildContext context) async {
    final nameCtrl = TextEditingController(text: 'Watchlist ${currentCount + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Watchlist'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Watchlist Name',
            hintText: 'Enter name',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      final newList = Watchlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        symbols: [],
      );
      StorageService.instance.box<Watchlist>('watchlist').add(newList);
      state = state.copyWith(selectedTabIndex: currentCount);
    }
  }

  /// Delete the given [watchlist].
  Future<void> deleteWatchlist(Watchlist watchlist, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: Text('Are you sure you want to delete "${watchlist.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final box = StorageService.instance.box<Watchlist>('watchlist');
      final index = box.values.toList().indexWhere((w) => w.id == watchlist.id);
      if (index != -1) {
        box.deleteAt(index);
        state = state.copyWith(
          hasUnsavedChanges: false,
          selectedTabIndex: 0,
        );
      }
    }
  }

  /// Save changes for the current watchlist.
  void save(Watchlist watchlist) {
    final updated = watchlist.copyWith(symbols: state.symbols);
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == watchlist.id);
    if (index != -1) box.putAt(index, updated);
    state = state.copyWith(
      savedSymbols: List.from(state.symbols),
      hasUnsavedChanges: false,
    );
  }

  /// Helper to compare symbol lists.
  bool _listEquals(List<String> a, List<String> b) => const ListEquality().equals(a, b);

  /// Prompt user to save if there are unsaved changes.
  Future<bool> promptSaveIfDirty(Watchlist currentWatchlist, BuildContext context) async {
    if (!state.hasUnsavedChanges) return true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Save before switching?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('cancel'), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('save'), child: const Text('Save')),
        ],
      ),
    );
    if (result == 'save') {
      save(currentWatchlist);
      return true;
    } else if (result == 'discard') {
      state = state.copyWith(hasUnsavedChanges: false, currentWatchlistId: null);
      return true;
    }
    return false;
  }

  /// Switch tab.
  Future<void> onTabTapped(int newIndex, Watchlist currentWatchlist, BuildContext context) async {
    if (newIndex == state.selectedTabIndex) return;
    final canSwitch = await promptSaveIfDirty(currentWatchlist, context);
    if (canSwitch && context.mounted) {
      state = state.copyWith(selectedTabIndex: newIndex);
    }
  }

  /// Reorder symbols.
  void reorder(int oldIndex, int newIndex) {
    final symbols = List<String>.from(state.symbols);
    if (oldIndex < newIndex) newIndex--;
    final item = symbols.removeAt(oldIndex);
    symbols.insert(newIndex, item);
    state = state.copyWith(
      symbols: symbols,
      hasUnsavedChanges: !_listEquals(symbols, state.savedSymbols),
    );
  }

  /// Add/remove symbols.
  void setSymbols(List<String> newSymbols) {
    state = state.copyWith(
      symbols: newSymbols,
      hasUnsavedChanges: !_listEquals(newSymbols, state.savedSymbols),
    );
  }

  /// Remove a single symbol.
  void removeSymbol(String symbol) {
    final symbols = List<String>.from(state.symbols)..remove(symbol);
    state = state.copyWith(
      symbols: symbols,
      hasUnsavedChanges: !_listEquals(symbols, state.savedSymbols),
    );
  }

  /// Set selected tab index directly (used by UI when out of range).
  void setSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}

// Provider for the notifier.
final watchlistScreenProvider = StateNotifierProvider<WatchlistScreenNotifier, WatchlistScreenState>(
  (ref) => WatchlistScreenNotifier(),
);

