import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/location/location_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/account/presentation/account_screen.dart';
import 'features/auth/presentation/auth_flow_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/location/presentation/location_permission_screen.dart';
import 'features/navigation/providers/navigation_provider.dart';
import 'features/orders/presentation/orders_screen.dart';

void main() {
  runApp(const SwiftShopperApp());
}

class SwiftShopperApp extends StatelessWidget {
  const SwiftShopperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootNavigation(),
      ),
    );
  }
}

class _RootNavigation extends ConsumerWidget {
  const _RootNavigation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const AuthFlowScreen();
    }

    final locationState = ref.watch(locationProvider);
    if (locationState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!locationState.promptSeen) {
      return const LocationPermissionScreen();
    }

    final currentIndex = ref.watch(selectedTabProvider);
    final screens = [
      const HomeScreen(),
      const OrdersScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
