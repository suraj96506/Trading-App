import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/features/watchlist/providers/watchlist_provider.dart';
import 'package:ticker_sim/features/watchlist/state/watchlist_notifier.dart';
import 'package:ticker_sim/features/watchlist/widgets/stock_picker_sheet.dart';
import 'package:ticker_sim/features/watchlist/widgets/watchlist_row.dart';
import 'package:ticker_sim/features/trade/widgets/trade_bottom_sheet.dart';
import '../../../shared/theme/app_theme.dart';

class WatchlistListScreen extends ConsumerWidget {
  const WatchlistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistState = ref.watch(watchlistScreenProvider);
    final notifier = ref.read(watchlistScreenProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final watchlistsAsync = ref.watch(watchlistsStreamProvider);

    Future<void> _createNewWatchlist(int currentCount) async {
      await notifier.createNewWatchlist(currentCount, context);
    }

    Future<void> _deleteWatchlist(Watchlist watchlist) async {
      await notifier.deleteWatchlist(watchlist, context);
    }

    void _save(Watchlist watchlist) {
      notifier.save(watchlist);
    }

    Future<bool> _promptSaveIfDirty(Watchlist currentWatchlist) async {
      return await notifier.promptSaveIfDirty(currentWatchlist, context);
    }

    Future<void> _onTabTapped(int newIndex, Watchlist currentWatchlist) async {
      await notifier.onTabTapped(newIndex, currentWatchlist, context);
    }

    void _openStockPicker() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, sc) => StockPickerSheet(
            selectedSymbols: watchlistState.symbols,
            onConfirm: (newSymbols) {
              notifier.setSymbols(newSymbols);
            },
          ),
        ),
      );
    }

    void _reorder(int oldIndex, int newIndex) {
      notifier.reorder(oldIndex, newIndex);
    }

    void _remove(String symbol) {
      notifier.removeSymbol(symbol);
    }

    void _openTradeSheet(String symbol) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, sc) => TradeBottomSheet(symbol: symbol, scrollController: sc),
        ),
      );
    }

    return PopScope(
      canPop: !watchlistState.hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final watchlist = watchlistState.currentWatchlistId != null
            ? watchlistsAsync.when(
                data: (list) => list.firstWhereOrNull(
                    (w) => w.id == watchlistState.currentWatchlistId),
                loading: () => null,
                error: (_, __) => null,
              )
            : null;
        if (watchlist != null && watchlistState.hasUnsavedChanges) {
          final shouldPop = await _promptSaveIfDirty(watchlist);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
          child: SafeArea(
            child: watchlistsAsync.when(
              data: (watchlists) {
                if (watchlists.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: AppTheme.glassPanel(context, radius: 28),
                            child: Icon(
                              Icons.star_outline_rounded,
                              size: 52,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No watchlists found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a watchlist to start tracking your favorite stocks and ETFs.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _createNewWatchlist(0),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Watchlist'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (watchlistState.selectedTabIndex >= watchlists.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifier.setSelectedTabIndex(watchlists.length - 1);
                  });
                }

                final currentWatchlist = watchlists[watchlistState.selectedTabIndex];
                // Defer sync to avoid modifying provider during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notifier.syncWithWatchlist(currentWatchlist);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: AppTheme.heroCard(context, radius: 28),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: const LinearGradient(
                                            colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(Icons.star_rounded, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Watchlists',
                                            style: Theme.of(context).textTheme.headlineMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${watchlists.length} lists, ${watchlistState.symbols.length} symbols active',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (watchlistState.hasUnsavedChanges)
                                        FilledButton(
                                          onPressed: () => _save(currentWatchlist),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlueMid,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text(
                                            'Save',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _deleteWatchlist(currentWatchlist),
                                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.lossBase),
                                        tooltip: 'Delete Watchlist',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 42,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: watchlists.length,
                                  itemBuilder: (context, i) {
                                    final sel = watchlistState.selectedTabIndex == i;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () => _onTabTapped(i, currentWatchlist),
                                        borderRadius: BorderRadius.circular(999),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: sel
                                                ? const LinearGradient(
                                                    colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            color: sel ? null : cs.surface.withValues(alpha: context.isDark ? 0.55 : 0.72),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: sel ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                watchlists[i].name,
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 13,
                                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                                                  color: sel ? Colors.white : cs.onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_rounded,
                                                  size: 16,
                                                  color: sel ? Colors.white : cs.onSurfaceVariant,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Rename Watchlist',
                                                onPressed: () async {
                                                  final renameCtrl = TextEditingController(text: watchlists[i].name);
                                                  final newName = await showDialog<String>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Rename Watchlist'),
                                                      content: TextField(
                                                        controller: renameCtrl,
                                                        autofocus: true,
                                                        decoration: const InputDecoration(labelText: 'New name'),
                                                        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(ctx).pop(),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () => Navigator.of(ctx).pop(renameCtrl.text.trim()),
                                                          child: const Text('Rename'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (newName != null && newName.isNotEmpty && context.mounted) {
                                                    final box = StorageService.instance.box<Watchlist>('watchlist');
                                                    final idx = box.values.toList().indexWhere((w) => w.id == watchlists[i].id);
                                                    if (idx != -1) {
                                                      final updated = watchlists[i].copyWith(name: newName);
                                                      box.putAt(idx, updated);
                                                      ref.refresh(watchlistsStreamProvider);
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Current list',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Column(
                        children: [
                          if (watchlistState.symbols.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.38 : 0.55),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                border: Border(
                                  bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: const Text(
                                      'SYMBOL',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: const Text(
                                      'LTP',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Δ%',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 46),
                                ],
                              ),
                            ),
                          Expanded(
                            child: watchlistState.symbols.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: AppTheme.glassPanel(context, radius: 26),
                                            child: Icon(
                                              Icons.star_border_rounded,
                                              size: 40,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No stocks yet',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tap "Add Stocks" to build your watchlist.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 20),
                                          FilledButton.icon(
                                            onPressed: _openStockPicker,
                                            icon: const Icon(Icons.playlist_add_rounded, size: 18),
                                            label: const Text('Add Stocks'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    itemCount: watchlistState.symbols.length,
                                    onReorder: _reorder,
                                    itemBuilder: (context, index) {
                                      final symbol = watchlistState.symbols[index];
                                      return WatchlistRow(
                                        key: ValueKey(symbol),
                                        symbol: symbol,
                                        onRemove: () => _remove(symbol),
                                        onTap: () => _openTradeSheet(symbol),
                                      );
                                    },
                                  ),
                          ),
                          if (watchlistState.symbols.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                              child: OutlinedButton.icon(
                                onPressed: _openStockPicker,
                                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                                label: const Text('Add / Remove Stocks'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
        floatingActionButton: watchlistsAsync.maybeWhen(
          data: (watchlists) => watchlists.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _createNewWatchlist(watchlists.length),
                  backgroundColor: AppTheme.primaryBlueMid,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('New Watchlist', style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }
}

