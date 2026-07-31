import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/order.dart';
import 'package:ticker_sim/features/orders/providers/orders_provider.dart';
import '../../../shared/theme/app_theme.dart';

enum _OrderFilter { all, buy, sell }

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _searchQuery = '';
  _OrderFilter _filter = _OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order History',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Track all your executed trades',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Search
                  TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search by symbol…',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Tabs
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        active: _filter == _OrderFilter.all,
                        onTap: () => setState(() => _filter = _OrderFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Buy',
                        active: _filter == _OrderFilter.buy,
                        activeColor: AppTheme.gainBase,
                        onTap: () => setState(() => _filter = _OrderFilter.buy),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sell',
                        active: _filter == _OrderFilter.sell,
                        activeColor: AppTheme.lossBase,
                        onTap: () => setState(() => _filter = _OrderFilter.sell),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: cs.outlineVariant, height: 1),

            // ── Order List ───────────────────────────────────
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  var filtered = orders.reversed.toList();
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered
                        .where((o) => o.symbol
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();
                  }
                  if (_filter == _OrderFilter.buy) {
                    filtered = filtered.where((o) => o.side == 'buy').toList();
                  } else if (_filter == _OrderFilter.sell) {
                    filtered = filtered.where((o) => o.side == 'sell').toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
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
                              child: Icon(Icons.receipt_long_outlined,
                                  size: 40, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              orders.isEmpty
                                  ? 'No orders yet'
                                  : 'No matching orders',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              orders.isEmpty
                                  ? 'Your executed trades will appear here.'
                                  : 'Try a different filter or search.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _OrderBentoCard(order: filtered[i]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = activeColor ?? AppTheme.primaryBlueMid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.13) : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.6) : cs.outlineVariant,
            width: active ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Order Bento Card ─────────────────────────────────────────────────────────
class _OrderBentoCard extends StatelessWidget {
  final Order order;

  const _OrderBentoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBuy = order.side == 'buy';
    final sideColor = isBuy ? AppTheme.gainColor(context) : AppTheme.lossColor(context);
    final sideBg    = isBuy ? AppTheme.gainBg(context) : AppTheme.lossBg(context);
    final sideLabel = isBuy ? 'BUY' : 'SELL';
    final totalVal  = order.price * order.quantity;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Side indicator pill
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sideColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                // Symbol info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(order.symbol,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 17,
                            fontWeight: FontWeight.w700, color: cs.onSurface)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sideBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(sideLabel,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                              fontWeight: FontWeight.w700, color: sideColor,
                              letterSpacing: 0.5)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${order.quantity.toStringAsFixed(0)} shares @ ₹${order.price.toStringAsFixed(2)}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                          color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${totalVal.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                      fontWeight: FontWeight.w700, color: cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  const SizedBox(height: 2),
                  Text(_formatTime(order.timestamp),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                      color: cs.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          // ── Status bar ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 13, color: AppTheme.gainBase),
              const SizedBox(width: 5),
              Text('Executed', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w600, color: AppTheme.gainBase)),
              const Spacer(),
              Text('Market Order', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today, $timeStr';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}, $timeStr';
  }
}
