import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
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

// Global key to access WatchlistListScreenState
final GlobalKey<WatchlistListScreenState> watchlistKey = GlobalKey<WatchlistListScreenState>();

// Root widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  int _currentIndex = 0;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    return MaterialApp(
      title: 'TickerSim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSplash
            ? SplashScreen(onComplete: () => setState(() => _showSplash = false))
            : AppShell(
                currentIndex: _currentIndex,
                isDark: isDark,
                onTabChanged: (i) async {
                  if (i == _currentIndex) return;
                  // Guard for unsaved changes in watchlist
                  final watchlistState = watchlistKey.currentState;
                  if (watchlistState != null && watchlistState.hasUnsavedChanges) {
                    final current = watchlistState.currentWatchlist;
                    if (current != null) {
                      final canProceed = await watchlistState.promptSaveIfDirty(current);
                      if (!canProceed) return;
                    }
                  }
                  setState(() => _currentIndex = i);
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
    builder: (_) => WatchlistListScreen(key: watchlistKey),
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

  const AppShell({required this.currentIndex, required this.isDark, required this.onTabChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  // Brand Name
                  const Text(
                    'TickerSim',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  // Theme Toggle
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => ref.read(themeProvider.notifier).state = !isDark,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 21,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Notification
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined, size: 21, color: cs.onSurfaceVariant),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.amber, shape: BoxShape.circle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _screens[currentIndex].builder(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant, width: 1))),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTabChanged,
          destinations: _screens
              .map((s) => NavigationDestination(icon: s.icon, selectedIcon: s.activeIcon, label: s.label))
              .toList(),
        ),
      ),
    );
  }
}
