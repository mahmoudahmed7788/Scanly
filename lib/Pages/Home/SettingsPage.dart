import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Core/App_Theme.dart';
import 'package:scanly/Core/NotificationService.dart';
import 'package:scanly/Widgets/Settings/SettingsCard.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationService.isEnabled();

    if (!mounted) return;

    setState(() {
      notifications = enabled;
    });
  }

  Future<void> _changeNotifications(bool value) async {
    setState(() {
      notifications = value;
    });

    await NotificationService.setEnabled(value);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await context.read<AuthCubit>().logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        ThemeController.mode.value == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: notifications
                ? 'Notifications are enabled'
                : 'Notifications are disabled',
            trailing: Switch(
              value: notifications,
              activeColor: theme.colorScheme.primary,
              onChanged: _changeNotifications,
            ),
          ),

          const SizedBox(height: 12),

          SettingsCard(
            icon: isDark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: 'Dark Mode',
            subtitle: isDark
                ? 'Dark theme is enabled'
                : 'Light theme is enabled',
            trailing: Switch(
              value: isDark,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                ThemeController.mode.value =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),

          const SizedBox(height: 30),

          Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          SettingsCard(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your profile',
            onTap: () {
              context.push('/profile');
            },
          ),

          const SizedBox(height: 12),

          SettingsCard(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out from your account',
            iconColor: Colors.red,
            onTap: _confirmLogout,
          ),

          const SizedBox(height: 30),

          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          SettingsCard(
            icon: Icons.info_outline,
            title: 'About Scanly',
            subtitle: 'Learn more about Scanly',
            onTap: () {
              context.push('/about');
            },
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'Scanly • 2026',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}