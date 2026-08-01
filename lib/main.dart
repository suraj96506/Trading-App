import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'dart:ui';
import 'package:ticker_sim/features/splash/screens/splash_screen.dart';
import 'package:ticker_sim/features/watchlist/screens/watchlist_list_screen.dart';
import 'shared/theme/app_theme.dart';
import 'core/agents/theme_agent.dart';
import 'core/constants/market_constants.dart';
import 'core/models/wallet.dart';
import 'core/services/storage_service.dart';
import 'features/market/screens/market_screen.dart';
import 'features/orders/screens/orders_screen.dart';
import 'features/portfolio/screens/portfolio_screen.dart';
import 'package:ticker_sim/features/watchlist/state/watchlist_notifier.dart';
import 'package:ticker_sim/features/watchlist/providers/watchlist_provider.dart';
import 'package:collection/collection.dart';

// State providers for main app shell
final splashProvider = StateProvider<bool>((ref) => !const bool.fromEnvironment('FLUTTER_TEST'));
final currentTabProvider = StateProvider<int>((ref) => 0);

class MyApp extends ConsumerWidget {
  // Global navigator key to provide a context under MaterialApp for dialogs
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final showSplash = ref.watch(splashProvider);
    final currentIndex = ref.watch(currentTabProvider);

    return MaterialApp(
      title: 'TickerSim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      navigatorKey: MyApp.navigatorKey,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: showSplash
            ? SplashScreen(onComplete: () => ref.read(splashProvider.notifier).state = false)
            : AppShell(
                currentIndex: currentIndex,
                isDark: isDark,
                onTabChanged: (i) async {
                  if (i == currentIndex) return;
                  // Guard for unsaved changes in watchlist
                  final watchlistState = ref.read(watchlistScreenProvider);
                  if (watchlistState.hasUnsavedChanges) {
                    final watchlists = ref.read(watchlistsStreamProvider).valueOrNull;
                    if (watchlists != null) {
                      final current = watchlists.firstWhereOrNull((w) => w.id == watchlistState.currentWatchlistId);
                      if (current != null && MyApp.navigatorKey.currentContext != null) {
                        final canProceed = await ref
                            .read(watchlistScreenProvider.notifier)
                            .promptSaveIfDirty(current, MyApp.navigatorKey.currentContext!);
                        if (!canProceed) return;
                      }
                    }
                  }
                  ref.read(currentTabProvider.notifier).state = i;
                },
              ),
      ),
    );
  }
}

class _Screen {
  final String label;
  final Widget icon;
  final Widget activeIcon;
  final WidgetBuilder builder;
  const _Screen({required this.label, required this.icon, required this.activeIcon, required this.builder});
}

final List<_Screen> _screens = [
  _Screen(
    label: 'Market',
    icon: const Icon(Icons.trending_up_outlined),
    activeIcon: const Icon(Icons.trending_up),
    builder: (_) => const MarketScreen(),
  ),
  _Screen(
    label: 'Watchlist',
    icon: const Icon(Icons.star_outline_rounded),
    activeIcon: const Icon(Icons.star_rounded),
    builder: (_) => const WatchlistListScreen(),
  ),
  _Screen(
    label: 'Portfolio',
    icon: const Icon(Icons.account_balance_wallet_outlined),
    activeIcon: const Icon(Icons.account_balance_wallet),
    builder: (_) => const PortfolioScreen(),
  ),
  _Screen(
    label: 'Orders',
    icon: const Icon(Icons.receipt_long_outlined),
    activeIcon: const Icon(Icons.receipt_long),
    builder: (_) => const OrdersScreen(),
  ),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  final walletBox = StorageService.instance.box<Wallet>('wallet');
  if (walletBox.isEmpty) {
    walletBox.add(Wallet(balance: Decimal.parse(kInitialWalletBalance)));
  }
  runApp(const ProviderScope(child: MyApp()));
}

class AppShell extends ConsumerWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTabChanged;

  const AppShell({super.key, required this.currentIndex, required this.isDark, required this.onTabChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withValues(alpha: isDark ? 0.82 : 0.92),
                        cs.surface.withValues(alpha: isDark ? 0.72 : 0.88),
                      ],
                    ),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
                    boxShadow: AppTheme.panelShadow(context),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlueMid.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.trending_up_rounded, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TickerSim',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                letterSpacing: -0.5,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Mock market, live feel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10.5,
                                height: 1.0,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _TopBarAction(
                        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        onTap: () => ref.read(themeProvider.notifier).state = !isDark,
                      ),
                      const SizedBox(width: 6),
                      _TopBarAction(
                        icon: Icons.notifications_outlined,
                        badge: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No new notifications')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _screens[currentIndex].builder(context),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: isDark ? 0.82 : 0.9),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.panelShadow(context),
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onTabChanged,
                  backgroundColor: Colors.transparent,
                  destinations: _screens
                      .map((s) => NavigationDestination(icon: s.icon, selectedIcon: s.activeIcon, label: s.label))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _TopBarAction({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, size: 20, color: cs.onSurfaceVariant)),
              if (badge)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
