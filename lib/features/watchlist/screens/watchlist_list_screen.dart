import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:ticker_sim/features/watchlist/providers/watchlist_provider.dart';
import 'package:ticker_sim/features/watchlist/widgets/stock_picker_sheet.dart';
import 'package:ticker_sim/features/watchlist/widgets/watchlist_row.dart';
import 'package:ticker_sim/features/trade/widgets/trade_bottom_sheet.dart';
import '../../../shared/theme/app_theme.dart';

class WatchlistListScreen extends ConsumerStatefulWidget {
  const WatchlistListScreen({super.key});

  @override
  ConsumerState<WatchlistListScreen> createState() => WatchlistListScreenState();
}

class WatchlistListScreenState extends ConsumerState<WatchlistListScreen> {
  int _selectedTabIndex = 0;

  // Track unsaved changes for the CURRENT tab
  List<String> _symbols = [];
  List<String> _savedSymbols = [];
  bool _hasUnsavedChanges = false;
  String? _currentWatchlistId;

  bool get hasUnsavedChanges => _hasUnsavedChanges;
  Watchlist? get currentWatchlist {
    final watchlists = ref.read(watchlistsStreamProvider).valueOrNull;
    if (watchlists == null || watchlists.isEmpty) return null;
    if (_selectedTabIndex >= watchlists.length) return watchlists.last;
    return watchlists[_selectedTabIndex];
  }

  @override
  void initState() {
    super.initState();
  }

  void _syncWithWatchlist(Watchlist watchlist) {
    if (_currentWatchlistId != watchlist.id) {
      // Switched tabs or initial load
      _currentWatchlistId = watchlist.id;
      _symbols = List.from(watchlist.symbols);
      _savedSymbols = List.from(watchlist.symbols);
      _hasUnsavedChanges = false;
    }
  }

  // ── Name Dialog ─────────────────────────────────────────────
  Future<void> _createNewWatchlist(int currentCount) async {
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
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final newList = Watchlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        symbols: [],
      );
      StorageService.instance.box<Watchlist>('watchlist').add(newList);
      // Select the newly created watchlist (it will be the last one)
      setState(() {
        _selectedTabIndex = currentCount;
      });
    }
  }

  Future<void> _deleteWatchlist(Watchlist watchlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: Text('Are you sure you want to delete "${watchlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossBase),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final box = StorageService.instance.box<Watchlist>('watchlist');
      final index = box.values.toList().indexWhere((w) => w.id == watchlist.id);
      if (index != -1) {
        box.deleteAt(index);
        setState(() {
          _hasUnsavedChanges = false;
          _selectedTabIndex = 0; // Reset tab to first
        });
      }
    }
  }

  // ── Save & Switch Logic ─────────────────────────────────────
  void _save(Watchlist watchlist) {
    final updated = watchlist.copyWith(symbols: _symbols);
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == watchlist.id);
    if (index != -1) box.putAt(index, updated);

    setState(() {
      _savedSymbols = List.from(_symbols);
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watchlist saved')),
    );
  }

  Future<bool> _promptSaveIfDirty(Watchlist currentWatchlist) async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Save before switching?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      _save(currentWatchlist);
      return true;
    } else if (result == 'discard') {
      setState(() {
        _hasUnsavedChanges = false;
        _currentWatchlistId = null; // force reload on next sync
      });
      return true;
    }
    return false; // cancel
  }

  // Public wrapper for navigation guard
  Future<bool> promptSaveIfDirty(Watchlist currentWatchlist) async {
    return await _promptSaveIfDirty(currentWatchlist);
  }

  Future<void> _onTabTapped(int newIndex, Watchlist currentWatchlist) async {
    if (newIndex == _selectedTabIndex) return;
    final canSwitch = await _promptSaveIfDirty(currentWatchlist);
    if (canSwitch && mounted) {
      setState(() => _selectedTabIndex = newIndex);
    }
  }

  // ── Stock Management ────────────────────────────────────────
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
          selectedSymbols: _symbols,
          onConfirm: (newSymbols) {
            setState(() {
              _symbols = newSymbols;
              _hasUnsavedChanges = !_listEquals(_symbols, _savedSymbols);
            });
          },
        ),
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final item = _symbols.removeAt(oldIndex);
      _symbols.insert(newIndex, item);
      _hasUnsavedChanges = !_listEquals(_symbols, _savedSymbols);
    });
  }

  void _remove(String symbol) {
    setState(() {
      _symbols.remove(symbol);
      _hasUnsavedChanges = !_listEquals(_symbols, _savedSymbols);
    });
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final watchlistsAsync = ref.watch(watchlistsStreamProvider);

    return WillPopScope(
      onWillPop: () async {
        final watchlist = currentWatchlist;
        if (watchlist == null) return true;
        if (!_hasUnsavedChanges) return true;
        // Show the same dialog as tab switching
        final canProceed = await _promptSaveIfDirty(watchlist);
        return canProceed;
      },
      child: Scaffold(
        body: SafeArea(
          child: watchlistsAsync.when(
            data: (watchlists) {
            // No Watchlists -> Empty State
            if (watchlists.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 52,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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

            // Fix index if it's out of bounds after deletion
            if (_selectedTabIndex >= watchlists.length) {
              _selectedTabIndex = watchlists.length - 1;
            }

            final currentWatchlist = watchlists[_selectedTabIndex];
            // Sync state with selected watchlist
            _syncWithWatchlist(currentWatchlist);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header & Tabs ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Watchlists', style: Theme.of(context).textTheme.headlineMedium),
                      // Save / Delete Row
                      Row(
                        children: [
                          if (_hasUnsavedChanges)
                            FilledButton(
                              onPressed: () => _save(currentWatchlist),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlueMid,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _deleteWatchlist(currentWatchlist),
                            icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.lossBase),
                            tooltip: 'Delete Watchlist',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tabs
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: watchlists.length,
                    itemBuilder: (context, i) {
                      final sel = _selectedTabIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _onTabTapped(i, currentWatchlist),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.primaryBlueMid.withValues(alpha: 0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppTheme.primaryBlueMid : cs.outlineVariant,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                watchlists[i].name,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? AppTheme.primaryBlueMid : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: cs.outlineVariant, height: 1),

                // ── Body: Stocks ──────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Table Header
                      if (_symbols.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text('SYMBOL',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                      color: cs.onSurfaceVariant)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('LTP', textAlign: TextAlign.right,
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                      color: cs.onSurfaceVariant)),
                              ),
                              const SizedBox(width: 12),
                              Text('Δ%',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                    fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                    color: cs.onSurfaceVariant)),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),

                      Expanded(
                        child: _symbols.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.star_border_rounded, size: 40, color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('No stocks yet', style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                      Text('Tap "Add Stocks" to build your watchlist.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodyMedium),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _symbols.length,
                                onReorder: _reorder,
                                itemBuilder: (context, index) {
                                  final symbol = _symbols[index];
                                  return WatchlistRow(
                                    key: ValueKey(symbol),
                                    symbol: symbol,
                                    onRemove: () => _remove(symbol),
                                    onTap: () => _openTradeSheet(symbol),
                                  );
                                },
                              ),
                      ),
                      
                      // Footer Add Stocks
                      if (_symbols.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: cs.outlineVariant)),
                          ),
                          child: OutlinedButton.icon(
                            onPressed: _openStockPicker,
                            icon: const Icon(Icons.playlist_add_rounded, size: 18),
                            label: const Text('Add / Remove Stocks'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
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
      floatingActionButton: ref.watch(watchlistsStreamProvider).maybeWhen(
        data: (watchlists) => watchlists.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _createNewWatchlist(watchlists.length),
                backgroundColor: AppTheme.primaryBlueMid,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('New Watchlist', style: TextStyle(fontWeight: FontWeight.w600)),
              )
            : null,
        orElse: () => null,
      ),
    ));
  }
}
