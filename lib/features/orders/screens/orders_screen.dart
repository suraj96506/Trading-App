import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/order.dart';
import 'package:ticker_sim/features/orders/providers/orders_provider.dart';
import 'package:ticker_sim/features/orders/state/orders_screen_notifier.dart';
import 'package:ticker_sim/features/orders/state/orders_screen_state.dart';
import '../../../shared/theme/app_theme.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final screenState = ref.watch(ordersScreenProvider);
    final notifier = ref.read(ordersScreenProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Container(
                  decoration: AppTheme.heroCard(context, radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order History',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Track all your executed trades',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: notifier.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search by symbol...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              active: screenState.filter == OrderFilter.all,
                              onTap: () => notifier.setFilter(OrderFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Buy',
                              active: screenState.filter == OrderFilter.buy,
                              activeColor: AppTheme.gainBase,
                              onTap: () => notifier.setFilter(OrderFilter.buy),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Sell',
                              active: screenState.filter == OrderFilter.sell,
                              activeColor: AppTheme.lossBase,
                              onTap: () => notifier.setFilter(OrderFilter.sell),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Recent executions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: context.isDark ? 0.65 : 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.75)),
                      ),
                      child: Text(
                        'Live archive',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ordersAsync.when(
                  data: (orders) {
                    var filtered = orders.reversed.toList();
                    if (screenState.searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where((o) => o.symbol
                              .toLowerCase()
                              .contains(screenState.searchQuery.toLowerCase()))
                          .toList();
                    }
                    if (screenState.filter == OrderFilter.buy) {
                      filtered = filtered.where((o) => o.side == 'buy').toList();
                    } else if (screenState.filter == OrderFilter.sell) {
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
                                decoration: AppTheme.glassPanel(context, radius: 24),
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _OrderBentoCard(order: filtered[i]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.86)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? Colors.transparent : cs.outlineVariant,
            width: active ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _OrderBentoCard extends StatelessWidget {
  final Order order;

  const _OrderBentoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBuy = order.side == 'buy';
    final sideColor = isBuy ? AppTheme.gainColor(context) : AppTheme.lossColor(context);
    final sideBg = isBuy ? AppTheme.gainBg(context) : AppTheme.lossBg(context);
    final sideLabel = isBuy ? 'BUY' : 'SELL';
    final totalVal = order.price * order.quantity;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppTheme.panelShadow(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: sideColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.symbol,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sideBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sideLabel,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: sideColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.quantity.toStringAsFixed(0)} shares @ ₹${order.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${totalVal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(order.timestamp),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 13, color: AppTheme.gainBase),
                const SizedBox(width: 5),
                Text(
                  'Executed',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gainBase,
                  ),
                ),
                const Spacer(),
                Text(
                  'Market Order',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today, $timeStr';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}, $timeStr';
  }
}
