import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'shared/theme/app_theme.dart';
import 'core/agents/theme_agent.dart';
import 'core/constants/market_constants.dart';
import 'core/models/wallet.dart';
import 'core/services/storage_service.dart';
import 'features/market/screens/market_screen.dart';
import 'features/orders/screens/orders_screen.dart';
import 'features/portfolio/screens/portfolio_screen.dart';
import 'features/watchlist/screens/watchlist_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  final walletBox = StorageService.instance.box<Wallet>('wallet');
  if (walletBox.isEmpty) {
    walletBox.add(Wallet(balance: Decimal.parse(kInitialWalletBalance)));
  }
  runApp(const ProviderScope(child: MyApp()));
}

class _Screen {
  final String label;
  final Widget icon;
  final Widget activeIcon;
  final WidgetBuilder builder;
  const _Screen({required this.label, required this.icon, required this.activeIcon, required this.builder});
}

final _screens = [
  _Screen(
    label: 'Market',
    icon: const Icon(Icons.show_chart_outlined),
    activeIcon: const Icon(Icons.show_chart),
    builder: (_) => const MarketScreen(),
  ),
  _Screen(
    label: 'Watchlist',
    icon: const Icon(Icons.list_outlined),
    activeIcon: const Icon(Icons.list),
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    return MaterialApp(
      title: 'TickerSim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: _screens[_currentIndex].builder(context),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _screens
              .map((s) => NavigationDestination(
                    icon: s.icon,
                    selectedIcon: s.activeIcon,
                    label: s.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
