import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/NotificationService.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Widgets/Home/HomeActivityAction.dart';
import 'package:scanly/Widgets/Home/HomeNotificationButton.dart';
import 'package:scanly/Widgets/Home/HomeToolCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  static const Color primaryPurple =
      Color(0xFF5B5FEF);

  static const Color secondaryBlue =
      Color(0xFF12B5EA);

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  String userName = 'User';

  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ==========================================================
    // ACTIVITY LISTENER
    // ==========================================================
    //
    // Whenever Recent/Favorites changes anywhere in the app:
    //
    // QR
    // Notes
    // PDF
    // Other activities
    //
    // Home will rebuild.
    //
    ScanlyActivityService.version.addListener(
      _onActivityChanged,
    );

    loadUserName();
    loadUnreadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(
      _onActivityChanged,
    );

    super.dispose();
  }

  // ==========================================================
  // ACTIVITY REFRESH
  // ==========================================================

  void _onActivityChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      loadUserName();
      loadUnreadNotifications();

      // Rebuild Home when returning to it.
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  Future<void> loadUnreadNotifications() async {
    try {
      final count =
          await NotificationService.getUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        unreadNotifications = count;
      });
    } catch (_) {}
  }

  // ==========================================================
  // USER
  // ==========================================================

  Future<void> loadUserName() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.reload();
    } catch (_) {}

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final name =
        currentUser?.displayName;

    if (name != null &&
        name.trim().isNotEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        userName = name.trim();
      });

      return;
    }

    final email =
        currentUser?.email;

    if (email != null &&
        email.isNotEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        userName =
            email.split('@').first;
      });
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> refreshHome() async {
    await loadUserName();
    await loadUnreadNotifications();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> openNotifications() async {
    await context.push(
      '/notifications',
    );

    if (!mounted) {
      return;
    }

    await loadUnreadNotifications();
  }

  void openProfile() {
    context.push('/profile');
  }

  void openQrTools() {
    context.push('/qr-tools');
  }

  void openNotes() {
    context.push('/notes');
  }

  void openPdfImages() {
    context.push('/pdf-images');
  }

  void openImageToText() {
    context.push('/image-to-text');
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color:
              colors.primary,
          onRefresh:
              refreshHome,
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  context,
                ),

                const SizedBox(
                  height: 32,
                ),

                Text(
                  'What would you like to do?',
                  style: TextStyle(
                    fontSize: 20,
                    color:
                        colors.onSurface,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                _buildToolsGrid(),

                const SizedBox(
                  height: 34,
                ),

                // IMPORTANT:
                //
                // Removed const.
                //
                // This allows HomeActivitySections
                // to rebuild whenever Home rebuilds.
                HomeActivitySections(
                  key: ValueKey(
                    ScanlyActivityService
                        .version
                        .value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
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

              const SizedBox(
                height: 4,
              ),

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

        const SizedBox(
          width: 10,
        ),

        HomeNotificationButton(
          unreadCount:
              unreadNotifications,
          onPressed:
              openNotifications,
        ),

        const SizedBox(
          width: 8,
        ),

        _buildProfileButton(
          context,
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE BUTTON
  // ==========================================================

  Widget _buildProfileButton(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
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
        onPressed:
            openProfile,
        icon: const Icon(
          Icons.person_outline,
          color: Colors.white,
        ),
        tooltip:
            'Profile',
      ),
    );
  }

  // ==========================================================
  // TOOLS GRID
  // ==========================================================

  Widget _buildToolsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        HomeToolCard(
          icon:
              Icons.qr_code_scanner,
          title:
              'QR Scanner',
          subtitle:
              'Scan QR codes',
          onTap:
              openQrTools,
        ),

        HomeToolCard(
          icon:
              Icons.note_alt_outlined,
          title:
              'Notes',
          subtitle:
              'Create notes',
          onTap:
              openNotes,
        ),

        HomeToolCard(
          icon:
              Icons.picture_as_pdf_outlined,
          title:
              'PDF & Images',
          subtitle:
              'Manage files',
          onTap:
              openPdfImages,
        ),

        HomeToolCard(
          icon:
              Icons.record_voice_over_outlined,
          title:
              'Text / Voice',
          subtitle:
              'Convert document',
          onTap:
              openImageToText,
        ),
      ],
    );
  }
}