import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:ticker_sim/features/watchlist/widgets/stock_picker_sheet.dart';
import 'package:ticker_sim/features/trade/widgets/trade_bottom_sheet.dart';
import 'package:ticker_sim/features/watchlist/widgets/watchlist_row.dart';
import 'package:ticker_sim/core/services/storage_service.dart';

class WatchlistDetailScreen extends ConsumerStatefulWidget {
  final Watchlist watchlist;

  const WatchlistDetailScreen({super.key, required this.watchlist});

  @override
  ConsumerState<WatchlistDetailScreen> createState() =>
      _WatchlistDetailScreenState();
}

class _WatchlistDetailScreenState extends ConsumerState<WatchlistDetailScreen> {
  late List<String> _symbols;

  @override
  void initState() {
    super.initState();
    _symbols = List<String>.from(widget.watchlist.symbols);
  }

  void _openStockPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StockPickerSheet(
        selectedSymbols: _symbols,
        onToggle: (symbol) {
          setState(() {
            if (_symbols.contains(symbol)) {
              _symbols.remove(symbol);
            } else {
              _symbols.add(symbol);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final item = _symbols.removeAt(oldIndex);
      _symbols.insert(newIndex, item);
    });
  }

  void _remove(String symbol) {
    setState(() => _symbols.remove(symbol));
  }

  void _save() {
    final updated = widget.watchlist.copyWith(symbols: _symbols);
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == widget.watchlist.id);
    if (index != -1) {
      box.putAt(index, updated);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watchlist saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.watchlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: _symbols.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Text(
                  'No stocks in this watchlist.\nTap + to add stocks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _symbols.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final symbol = _symbols[index];
                return WatchlistRow(
                  key: ValueKey(symbol),
                  symbol: symbol,
                  onRemove: () => _remove(symbol),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => TradeBottomSheet(symbol: symbol),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStockPicker,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }
}
