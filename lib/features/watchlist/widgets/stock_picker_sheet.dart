import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../state/stock_picker_state.dart';

/// Multi-select stock picker bottom sheet.
/// User checks/unchecks stocks and taps "Done" to confirm.
/// Closes without saving if tapped outside.
class StockPickerSheet extends ConsumerWidget {
  final List<String> selectedSymbols;

  /// Called with the final confirmed list of symbols.
  final void Function(List<String> symbols) onConfirm;

  const StockPickerSheet({
    super.key,
    required this.selectedSymbols,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockPickerProvider(selectedSymbols));
    final notifier = ref.read(stockPickerProvider(selectedSymbols).notifier);
    final _selected = state.selected;
    final _query = state.query;

    final cs = Theme.of(context).colorScheme;
    final allSymbols = kStartingPrices.keys.toList();
    final filtered = _query.isEmpty
        ? allSymbols
        : allSymbols
            .where((s) =>
                s.toLowerCase().contains(_query.toLowerCase()) ||
                (kStockCompanyNames[s] ?? '').toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Stocks', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${_selected.length} selected',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    onConfirm(_selected.toList());
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlueMid,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search stocks...',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
              ),
              onChanged: (v) => notifier.setQuery(v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.4 : 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
              ),
              child: InkWell(
                onTap: () {
                  notifier.toggleAll(allSymbols);
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selected.length == allSymbols.length
                            ? true
                            : _selected.isEmpty
                                ? false
                                : null,
                        tristate: true,
                        onChanged: (_) {
                          notifier.toggleAll(allSymbols);
                        },
                        activeColor: AppTheme.primaryBlueMid,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Select all stocks',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${allSymbols.length}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.separated(
              itemCount: filtered.length,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final symbol = filtered[index];
                final isSelected = _selected.contains(symbol);
                final companyName = kStockCompanyNames[symbol] ?? symbol;
                final price = kStartingPrices[symbol];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      notifier.toggleSymbol(symbol);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlueMid.withValues(alpha: 0.08)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlueMid.withValues(alpha: 0.4)
                              : cs.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              notifier.toggleSymbol(symbol);
                            },
                            activeColor: AppTheme.primaryBlueMid,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              symbol[0],
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  symbol,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  companyName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (price != null)
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
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
    );
  }
}
