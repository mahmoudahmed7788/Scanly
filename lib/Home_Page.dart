import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/HomeActivityAction.dart';

import 'package:scanly/NotificationsService.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color primaryPurple = Color(0xFF5B5FEF);
  static const Color secondaryBlue = Color(0xFF12B5EA);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  String userName = 'User';
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadUserName();
    loadUnreadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      loadUserName();
      loadUnreadNotifications();
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final count =
          await NotificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        unreadNotifications = count;
      });
    } catch (_) {}
  }

  Future<void> loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.reload();
    } catch (_) {}

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final name = currentUser?.displayName;

    if (name != null && name.trim().isNotEmpty) {
      if (!mounted) return;

      setState(() {
        userName = name.trim();
      });

      return;
    }

    final email = currentUser?.email;

    if (email != null && email.isNotEmpty) {
      if (!mounted) return;

      setState(() {
        userName = email.split('@').first;
      });
    }
  }

  Future<void> refreshHome() async {
    await loadUserName();
    await loadUnreadNotifications();
  }

  Future<void> openNotifications() async {
    await context.push('/notifications');

    if (!mounted) return;

    await loadUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: refreshHome,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back 👋',
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.onSurface
                                  .withOpacity(0.55),
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 25,
                              color:
                                  colors.onSurface,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    _NotificationButton(
                      unreadCount:
                          unreadNotifications,
                      onPressed:
                          openNotifications,
                    ),

                    const SizedBox(width: 8),

                    Container(
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            HomePage.primaryPurple,
                            HomePage.secondaryBlue,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: HomePage
                                .primaryPurple
                                .withOpacity(0.25),
                            blurRadius: 10,
                            offset:
                                const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          context.push('/profile');
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                        tooltip: 'Profile',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'What would you like to do?',
                  style: TextStyle(
                    fontSize: 20,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    _ToolCard(
                      icon:
                          Icons.qr_code_scanner,
                      title: 'QR Scanner',
                      subtitle:
                          'Scan QR codes',
                      onTap: () {
                        context.push(
                          '/qr-tools',
                        );
                      },
                    ),

                    _ToolCard(
                      icon:
                          Icons.note_alt_outlined,
                      title: 'Notes',
                      subtitle:
                          'Create notes',
                      onTap: () {
                        context.push(
                          '/notes',
                        );
                      },
                    ),

                    _ToolCard(
                      icon:
                          Icons.picture_as_pdf_outlined,
                      title: 'PDF & Images',
                      subtitle:
                          'Manage files',
                      onTap: () {
                        context.push(
                          '/pdf-images',
                        );
                      },
                    ),

                    _ToolCard(
                      icon:
                          Icons.record_voice_over_outlined,
                      title: 'Text / Voice',
                      subtitle:
                          'Convert document',
                      onTap: () {
                        context.push(
                          '/image-to-text',
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 34),

                const HomeActivitySections(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton
    extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface
                    .withOpacity(
                  theme.brightness ==
                          Brightness.dark
                      ? 0.20
                      : 0.06,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications
                  : Icons
                      .notifications_none_rounded,
              color: colors.primary,
            ),
            tooltip: 'Notifications',
          ),
        ),

        if (unreadCount > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints:
                  const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color: theme
                      .scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99
                    ? '99+'
                    : unreadCount.toString(),
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToolCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Ink(
          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                HomePage.primaryPurple,
                HomePage.secondaryBlue,
              ],
            ),
            borderRadius:
                BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.18),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  subtitle,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(0.70),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
