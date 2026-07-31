import 'package:flutter/material.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';

/// Multi-select stock picker bottom sheet.
/// User checks/unchecks stocks and taps "Done" to confirm.
/// Closes without saving if tapped outside.
class StockPickerSheet extends StatefulWidget {
  final List<String> selectedSymbols;

  /// Called with the final confirmed list of symbols.
  final void Function(List<String> symbols) onConfirm;

  const StockPickerSheet({
    super.key,
    required this.selectedSymbols,
    required this.onConfirm,
  });

  @override
  State<StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends State<StockPickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedSymbols);
  }

  @override
  Widget build(BuildContext context) {
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 44, height: 4.5,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // ── Title Row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Stocks',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${_selected.length} selected',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Done button
                FilledButton(
                  onPressed: () {
                    widget.onConfirm(_selected.toList());
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlueMid,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // ── Search ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search stocks…',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),

          Divider(color: cs.outlineVariant, height: 12),

          // ── Select All Row ────────────────────────────────────────
          InkWell(
            onTap: () {
              setState(() {
                if (_selected.length == allSymbols.length) {
                  _selected.clear();
                } else {
                  _selected = Set.from(allSymbols);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
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
                      setState(() {
                        if (_selected.length == allSymbols.length) {
                          _selected.clear();
                        } else {
                          _selected = Set.from(allSymbols);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryBlueMid,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Select All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stock List ────────────────────────────────────────────
          Flexible(
            child: ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final symbol = filtered[index];
                final isSelected = _selected.contains(symbol);
                final companyName = kStockCompanyNames[symbol] ?? symbol;
                final price = kStartingPrices[symbol];

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(symbol);
                      } else {
                        _selected.add(symbol);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    color: isSelected
                        ? AppTheme.primaryBlueMid.withValues(alpha: 0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(symbol);
                              } else {
                                _selected.add(symbol);
                              }
                            });
                          },
                          activeColor: AppTheme.primaryBlueMid,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Symbol Avatar
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            symbol[0],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(symbol,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  )),
                              Text(companyName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                        if (price != null)
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
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
