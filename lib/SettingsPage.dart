import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/Auth_Cubit.dart';
import 'package:scanly/App_Theme.dart';
import 'package:scanly/NotificationsService.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled =
        await NotificationService.isEnabled();

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
        ThemeController.mode.value ==
            ThemeMode.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
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
              color:
                  theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          _SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: notifications
                ? 'Notifications are enabled'
                : 'Notifications are disabled',
            trailing: Switch(
              value: notifications,
              activeColor:
                  theme.colorScheme.primary,
              onChanged:
                  _changeNotifications,
            ),
          ),

          const SizedBox(height: 12),

          _SettingsCard(
            icon: isDark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: 'Dark Mode',
            subtitle: isDark
                ? 'Dark theme is enabled'
                : 'Light theme is enabled',
            trailing: Switch(
              value: isDark,
              activeColor:
                  theme.colorScheme.primary,
              onChanged: (value) {
                ThemeController.mode.value =
                    value
                        ? ThemeMode.dark
                        : ThemeMode.light;
              },
            ),
          ),

          const SizedBox(height: 30),

          Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          _SettingsCard(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your profile',
            onTap: () {
              context.push('/profile');
            },
          ),

          const SizedBox(height: 12),

          _SettingsCard(
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
              color:
                  theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          _SettingsCard(
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
                color: theme.colorScheme.onSurface
                    .withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color =
        iconColor ??
        theme.colorScheme.primary;

    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 16,
                        color: theme
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class AboutScanlyPage extends StatelessWidget {
  const AboutScanlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'About Scanly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B5FEF),
                      Color(0xFF7C5CFC),
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary
                          .withOpacity(0.25),
                      blurRadius: 25,
                      offset:
                          const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/Scanly_Splash.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Scanly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Scan. Save. Organize.',
                style: TextStyle(
                  fontSize: 15,
                  color:
                      colors.onSurfaceVariant,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: colors
                        .surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Scanly',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Scanly is your all-in-one utility app for scanning, organizing, saving, and sharing your digital content.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colors
                            .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _AboutFeature(
                      icon:
                          Icons.qr_code_2_rounded,
                      title: 'QR Tools',
                      subtitle:
                          'Create, scan, save, and share QR codes.',
                    ),

                    const SizedBox(height: 14),

                    _AboutFeature(
                      icon:
                          Icons.description_outlined,
                      title: 'Documents',
                      subtitle:
                          'Create and organize your PDF documents.',
                    ),

                    const SizedBox(height: 14),

                    _AboutFeature(
                      icon:
                          Icons.text_fields_rounded,
                      title: 'Text & Voice',
                      subtitle:
                          'Extract text and listen to it with voice tools.',
                    ),

                    const SizedBox(height: 14),

                    _AboutFeature(
                      icon:
                          Icons.note_alt_outlined,
                      title: 'Notes',
                      subtitle:
                          'Create and organize your notes in one place.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: colors.primary
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color:
                          colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Version',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Scanly • 2026',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface
                      .withOpacity(0.45),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary
                .withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 22,
            color: colors.primary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}