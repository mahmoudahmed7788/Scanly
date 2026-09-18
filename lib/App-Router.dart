import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/DocumentModel.dart';
import 'package:scanly/DocumentsPage.dart';
import 'package:scanly/EditDocumentPage.dart';
import 'package:scanly/FavouritesPage.dart';
import 'package:scanly/ForgotPasswordVerficationPage.dart';
import 'package:scanly/Home_Page.dart';
import 'package:scanly/ImageToTextPage.dart';
import 'package:scanly/Login_Page.dart';
import 'package:scanly/Note_Model.dart';
import 'package:scanly/Notes_Page.dart';
import 'package:scanly/NotificationPage.dart';
import 'package:scanly/OnBourding_Page.dart';
import 'package:scanly/PDFImagesPage.dart';
import 'package:scanly/PDFPreviewPage.dart';
import 'package:scanly/ProfilePage.dart';
import 'package:scanly/QR_Tools_Page.dart';
import 'package:scanly/Recent_Page.dart';
import 'package:scanly/Register_page.dart';
import 'package:scanly/SettingsPage.dart';
import 'package:scanly/Verfication_Page.dart';
import 'package:scanly/create_note_page.dart';
import 'package:scanly/view_note_page.dart';
import 'package:scanly/DocumentViewerPage.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    // =========================================
    // START APP
    // =========================================
    // No SplashPage anymore.
    // Native Launch Screen handles the startup screen.
    initialLocation: '/login',

    routes: [

      // =========================================
      // LOGIN
      // =========================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // =========================================
      // REGISTER
      // =========================================
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          return const RegisterPage();
        },
      ),

      // =========================================
      // VERIFICATION
      // =========================================
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) {
          return const VerificationPage();
        },
      ),

      // =========================================
      // FORGOT PASSWORD
      // =========================================
      GoRoute(
        path: '/forgot-password-verification',
        name: 'forgot-password-verification',
        builder: (context, state) {
          final email = state.extra is String
              ? state.extra as String
              : '';

          return ForgotPasswordVerificationPage(
            email: email,
          );
        },
      ),

      // =========================================
      // ONBOARDING
      // =========================================
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) {
          return const OnboardingPage();
        },
      ),

      // =========================================
      // MAIN NAVIGATION
      // HOME / DOCUMENTS / FAVORITES / SETTINGS
      // =========================================
      ShellRoute(
        builder: (
          context,
          state,
          child,
        ) {
          return MainNavigationPage(
            child: child,
          );
        },
        routes: [

          // =========================================
          // HOME
          // =========================================
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (
              context,
              state,
            ) {
              return const NoTransitionPage(
                child: HomePage(),
              );
            },
          ),

          // =========================================
          // DOCUMENTS
          // =========================================
          GoRoute(
            path: '/documents',
            name: 'documents',
            pageBuilder: (
              context,
              state,
            ) {
              return const NoTransitionPage(
                child: DocumentsPage(),
              );
            },
          ),

          // =========================================
          // FAVORITES
          // =========================================
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            pageBuilder: (
              context,
              state,
            ) {
              return const NoTransitionPage(
                child: FavoritesPage(),
              );
            },
          ),

          // =========================================
          // SETTINGS
          // =========================================
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (
              context,
              state,
            ) {
              return const NoTransitionPage(
                child: SettingsPage(),
              );
            },
          ),
        ],
      ),

      // =========================================
      // ABOUT
      // =========================================
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (
          context,
          state,
        ) {
          return const AboutScanlyPage();
        },
      ),

      // =========================================
      // PDF PREVIEW
      // =========================================
      GoRoute(
        path: '/pdf-preview',
        name: 'pdf-preview',
        pageBuilder: (
          context,
          state,
        ) {
          debugPrint(
            '🔥🔥🔥 PDF PREVIEW ROUTE MATCHED 🔥🔥🔥',
          );

          final data = state.extra;

          debugPrint(
            'PDF ROUTE EXTRA TYPE: ${data.runtimeType}',
          );

          if (data is! Map) {
            debugPrint(
              '❌ PDF ROUTE DATA IS NOT MAP',
            );

            return const NoTransitionPage(
              child: Scaffold(
                body: Center(
                  child: Text(
                    'PDF data not found',
                  ),
                ),
              ),
            );
          }

          final pdfBytes = data['pdfBytes'];
          final fileName = data['fileName'];
          final filePath = data['filePath'];
          final imagePathsRaw = data['imagePaths'];

          final imagePaths = <String>[];

          if (imagePathsRaw is List) {
            for (final path in imagePathsRaw) {
              if (path is String &&
                  path.isNotEmpty) {
                imagePaths.add(path);
              }
            }
          }

          debugPrint(
            'PDF ROUTE BYTES: ${pdfBytes is Uint8List}',
          );

          debugPrint(
            'PDF ROUTE FILE NAME: $fileName',
          );

          debugPrint(
            'PDF ROUTE FILE PATH: $filePath',
          );

          debugPrint(
            'PDF ROUTE IMAGE PATHS: ${imagePaths.length}',
          );

          if (pdfBytes is! Uint8List ||
              fileName is! String) {
            debugPrint(
              '❌ INVALID PDF ROUTE DATA',
            );

            return const NoTransitionPage(
              child: Scaffold(
                body: Center(
                  child: Text(
                    'Invalid PDF data',
                  ),
                ),
              ),
            );
          }

          debugPrint(
            '✅ OPENING PDF PREVIEW PAGE',
          );

          return NoTransitionPage(
            child: PDFPreviewPage(
              pdfBytes: pdfBytes,
              fileName: fileName,
              filePath: filePath is String
                  ? filePath
                  : null,
              imagePaths: imagePaths,
            ),
          );
        },
      ),

      // =========================================
      // EDIT DOCUMENT
      // =========================================
      GoRoute(
        path: '/edit-document',
        name: 'edit-document',
        builder: (
          context,
          state,
        ) {
          final document = state.extra;

          if (document is! DocumentModel) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Document not found',
                ),
              ),
            );
          }

          return EditDocumentPage(
            document: document,
          );
        },
      ),

      // =========================================
      // DOCUMENT VIEWER
      // =========================================
      GoRoute(
        path: '/document-viewer',
        name: 'document-viewer',
        builder: (
          context,
          state,
        ) {
          final document = state.extra;

          if (document is! DocumentModel) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Document not found',
                ),
              ),
            );
          }

          return DocumentViewerPage(
            document: document,
          );
        },
      ),

      // =========================================
      // NOTES
      // =========================================
      GoRoute(
        path: '/notes',
        name: 'notes',
        builder: (
          context,
          state,
        ) {
          return const NotesPage();
        },
      ),

      // =========================================
      // CREATE NOTE
      // =========================================
      GoRoute(
        path: '/create-note',
        name: 'create-note',
        builder: (
          context,
          state,
        ) {
          final note = state.extra as NoteModel?;

          return CreateNotePage(
            note: note,
          );
        },
      ),

      // =========================================
      // VIEW NOTE
      // =========================================
      GoRoute(
        path: '/view-note',
        name: 'view-note',
        builder: (
          context,
          state,
        ) {
          final note = state.extra;

          if (note is! NoteModel) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Note not found',
                ),
              ),
            );
          }

          return ViewNotePage(
            note: note,
          );
        },
      ),

      // =========================================
      // QR TOOLS
      // =========================================
      GoRoute(
        path: '/qr-tools',
        name: 'qr-tools',
        builder: (
          context,
          state,
        ) {
          return const QRToolsPage();
        },
      ),

      // =========================================
      // PDF & IMAGES
      // =========================================
      GoRoute(
        path: '/pdf-images',
        name: 'pdf-images',
        builder: (
          context,
          state,
        ) {
          return const PDFImagesPage();
        },
      ),

      // =========================================
      // RECENT
      // =========================================
      GoRoute(
        path: '/recent',
        name: 'recent',
        pageBuilder: (
          context,
          state,
        ) {
          return const NoTransitionPage(
            child: RecentPage(),
          );
        },
      ),

      // =========================================
      // IMAGE TO TEXT
      // =========================================
      GoRoute(
        path: '/image-to-text',
        name: 'image-to-text',
        builder: (
          context,
          state,
        ) {
          return const ImageToTextPage();
        },
      ),

      // =========================================
      // PROFILE
      // =========================================
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (
          context,
          state,
        ) {
          return const ProfilePage();
        },
      ),

      // =========================================
      // NOTIFICATIONS
      // =========================================
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (
          context,
          state,
        ) {
          return const NotificationsPage();
        },
      ),
    ],
  );
}


// =========================================================
// MAIN NAVIGATION PAGE
// =========================================================

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

    if (location == '/documents') {
      return 1;
    }

    if (location == '/favorites') {
      return 2;
    }

    if (location == '/settings') {
      return 3;
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
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final currentIndex =
        _getCurrentIndex(context);

    return Scaffold(
      body: child,

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(24),

          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,

              borderRadius:
                  BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color:
                      colors.onSurface.withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 18,
                  offset: const Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),

            child: NavigationBar(
              selectedIndex: currentIndex,

              onDestinationSelected: (
                index,
              ) {
                _onItemTapped(
                  context,
                  index,
                );
              },

              backgroundColor:
                  Colors.transparent,

              surfaceTintColor:
                  Colors.transparent,

              shadowColor:
                  Colors.transparent,

              elevation: 0,

              height: 68,

              indicatorColor:
                  colors.primary.withValues(
                alpha: 0.14,
              ),

              labelBehavior:
                  NavigationDestinationLabelBehavior
                      .alwaysShow,

              destinations: [

                // =========================================
                // HOME
                // =========================================
                NavigationDestination(
                  icon: Icon(
                    Icons.home_outlined,
                    color:
                        colors.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  selectedIcon: Icon(
                    Icons.home_rounded,
                    color: colors.primary,
                  ),
                  label: 'Home',
                ),

                // =========================================
                // DOCUMENTS
                // =========================================
                NavigationDestination(
                  icon: Icon(
                    Icons.description_outlined,
                    color:
                        colors.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  selectedIcon: Icon(
                    Icons.description_rounded,
                    color: colors.primary,
                  ),
                  label: 'Documents',
                ),

                // =========================================
                // FAVORITES
                // =========================================
                NavigationDestination(
                  icon: Icon(
                    Icons.star_border_rounded,
                    color:
                        colors.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  selectedIcon: Icon(
                    Icons.star_rounded,
                    color: colors.primary,
                  ),
                  label: 'Favorites',
                ),

                // =========================================
                // SETTINGS
                // =========================================
                NavigationDestination(
                  icon: Icon(
                    Icons.settings_outlined,
                    color:
                        colors.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  selectedIcon: Icon(
                    Icons.settings_rounded,
                    color: colors.primary,
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}