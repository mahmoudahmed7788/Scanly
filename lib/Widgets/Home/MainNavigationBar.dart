import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationPage extends StatelessWidget {
  final Widget child;

  const MainNavigationPage({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(
    BuildContext context,
  ) {
    final location =
        GoRouterState.of(context).uri.path;

    if (location.startsWith('/documents')) {
      return 1;
    }

    if (location.startsWith('/favorites')) {
      return 2;
    }

    if (location.startsWith('/trash')) {
      return 3;
    }

    if (location.startsWith('/settings')) {
      return 4;
    }

    return 0;
  }

  void _onItemTapped(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        context.go('/home');
        break;

      case 1:
        context.go('/documents');
        break;

      case 2:
        context.go('/favorites');
        break;

      case 3:
        context.go('/trash');
        break;

      case 4:
        context.go('/settings');
        break;
    }
  }

  List<NavigationDestination>
      _buildDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(
          Icons.home_outlined,
        ),
        selectedIcon: Icon(
          Icons.home,
        ),
        label: 'Home',
      ),

      NavigationDestination(
        icon: Icon(
          Icons.folder_outlined,
        ),
        selectedIcon: Icon(
          Icons.folder,
        ),
        label: 'Documents',
      ),

      NavigationDestination(
        icon: Icon(
          Icons.favorite_border,
        ),
        selectedIcon: Icon(
          Icons.favorite,
        ),
        label: 'Favorites',
      ),

      NavigationDestination(
        icon: Icon(
          Icons.delete_outline,
        ),
        selectedIcon: Icon(
          Icons.delete,
        ),
        label: 'Trash',
      ),

      NavigationDestination(
        icon: Icon(
          Icons.settings_outlined,
        ),
        selectedIcon: Icon(
          Icons.settings,
        ),
        label: 'Settings',
      ),
    ];
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentIndex =
        _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) {
          _onItemTapped(
            context,
            index,
          );
        },
        destinations:
            _buildDestinations(),
      ),
    );
  }
}