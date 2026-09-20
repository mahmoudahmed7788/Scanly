import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// MAIN PAGES
// ============================================================

import 'package:scanly/Home_Page.dart';
import 'package:scanly/DocumentsPage.dart';
import 'package:scanly/FavouritesPage.dart';
import 'package:scanly/Notes_Page.dart';
import 'package:scanly/NotificationPage.dart';
import 'package:scanly/QR_Tools_Page.dart';
import 'package:scanly/SettingsPage.dart';

// ============================================================
// AUTH
// ============================================================

import 'package:scanly/Login_Page.dart';
import 'package:scanly/Register_page.dart';
import 'package:scanly/Verfication_Page.dart';
import 'package:scanly/ForgotPasswordVerficationPage.dart';
import 'package:scanly/OnBourding_Page.dart';

// ============================================================
// DOCUMENTS
// ============================================================

import 'package:scanly/DocumentModel.dart';
import 'package:scanly/EditDocumentPage.dart';
import 'package:scanly/PDFPreviewPage.dart';
import 'package:scanly/DocumentViewerPage.dart';

// ============================================================
// NOTES
// ============================================================

import 'package:scanly/Note_Model.dart';

// ============================================================
// OTHER
// ============================================================

import 'package:scanly/PDFImagesPage.dart';
import 'package:scanly/ImageToTextPage.dart';
import 'package:scanly/ProfilePage.dart';
import 'package:scanly/create_note_page.dart';
import 'package:scanly/view_note_page.dart';

// ============================================================
// GO ROUTER AUTH REFRESH
// ============================================================

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  GoRouterRefreshStream(Stream<User?> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ============================================================
// MAIN NAVIGATION PAGE
// ============================================================

class MainNavigationPage extends StatelessWidget {
  final Widget child;

  const MainNavigationPage({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/documents')) {
      return 1;
    }

    if (location.startsWith('/favorites')) {
      return 2;
    }

    if (location.startsWith('/settings')) {
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
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          _onItemTapped(
            context,
            index,
          );
        },
        destinations: const [
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
              Icons.settings_outlined,
            ),
            selectedIcon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APP ROUTER
// ============================================================

class AppRouter {
  static final GoRouter router = GoRouter(
    // ========================================================
    // STARTING POINT
    // ========================================================

    initialLocation: '/',

    // ========================================================
    // AUTH STATE LISTENER
    // ========================================================

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),

    // ========================================================
    // REDIRECT
    // ========================================================

    redirect: (context, state) {
      final User? user =
          FirebaseAuth.instance.currentUser;

      final String location =
          state.uri.path;

      // ======================================================
      // ROOT
      // ======================================================

      if (location == '/') {
        if (user != null) {
          return '/home';
        }

        return '/login';
      }

      // ======================================================
      // AUTH PAGES
      // ======================================================

      final bool isLogin =
          location == '/login';

      final bool isRegister =
          location == '/register';

      final bool isVerification =
          location == '/verification';

      final bool isForgotPassword =
          location ==
              '/forgot-password-verification';

      final bool isOnboarding =
          location == '/onboarding';

      final bool isAuthPage =
          isLogin ||
          isRegister ||
          isVerification ||
          isForgotPassword;

      // ======================================================
      // USER NOT LOGGED IN
      // ======================================================

      if (user == null) {
        if (isAuthPage || isOnboarding) {
          return null;
        }

        return '/login';
      }

      // ======================================================
      // USER LOGGED IN
      // ======================================================

      // ------------------------------------------------------
      // IMPORTANT:
      //
      // Do NOT redirect /verification here.
      //
      // LoginPage decides:
      //
      // Email + not verified
      //       -> /verification
      //
      // Google/Facebook
      //       -> /home
      //
      // ------------------------------------------------------

      if (isLogin || isRegister) {
        return '/home';
      }

      return null;
    },

    // ========================================================
    // ROUTES
    // ========================================================

    routes: [

      // ======================================================
      // ROOT
      // ======================================================

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const SizedBox.shrink();
        },
      ),

      // ======================================================
      // LOGIN
      // ======================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // ======================================================
      // REGISTER
      // ======================================================

      GoRoute(
        path: '/register',
        builder: (context, state) {
          return const RegisterPage();
        },
      ),

      // ======================================================
      // EMAIL VERIFICATION
      // ======================================================

      GoRoute(
        path: '/verification',
        builder: (context, state) {
          return const VerificationPage();
        },
      ),

      // ======================================================
      // FORGOT PASSWORD
      // ======================================================

      GoRoute(
        path: '/forgot-password-verification',
        builder: (context, state) {
          return const ForgotPasswordVerificationPage(
            email: '',
          );
        },
      ),

      // ======================================================
      // ONBOARDING
      // ======================================================

      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          return const OnboardingPage();
        },
      ),

      // ======================================================
      // MAIN APP
      // ======================================================

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

          // ==================================================
          // HOME
          // ==================================================

          GoRoute(
            path: '/home',
            builder: (context, state) {
              return const HomePage();
            },
          ),

          // ==================================================
          // DOCUMENTS
          // ==================================================

          GoRoute(
            path: '/documents',
            builder: (context, state) {
              return const DocumentsPage();
            },
          ),

          // ==================================================
          // FAVORITES
          // ==================================================

          GoRoute(
            path: '/favorites',
            builder: (context, state) {
              return const FavoritesPage();
            },
          ),

          // ==================================================
          // SETTINGS
          // ==================================================

          GoRoute(
            path: '/settings',
            builder: (context, state) {
              return const SettingsPage();
            },
          ),
        ],
      ),

      // ======================================================
      // PROFILE
      // ======================================================

      GoRoute(
        path: '/profile',
        builder: (context, state) {
          return const ProfilePage();
        },
      ),

      // ======================================================
      // NOTIFICATIONS
      // ======================================================

      GoRoute(
        path: '/notifications',
        builder: (context, state) {
          return const NotificationsPage();
        },
      ),

      // ======================================================
      // ABOUT SCANLY
      // ======================================================

      GoRoute(
        path: '/about',
        builder: (context, state) {
          return const AboutScanlyPage();
        },
      ),

      // ======================================================
      // PDF PREVIEW
      // ======================================================

      GoRoute(
        path: '/pdf-preview',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is DocumentModel) {
            return PDFPreviewPage(
              document: extra,
              pdfBytes: Uint8List(0),
              fileName: '',
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Document not found',
              ),
            ),
          );
        },
      ),

      // ======================================================
      // EDIT DOCUMENT
      // ======================================================

      GoRoute(
        path: '/edit-document',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is DocumentModel) {
            return EditDocumentPage(
              document: extra,
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Document not found',
              ),
            ),
          );
        },
      ),

      // ======================================================
      // DOCUMENT VIEWER
      // ======================================================

      GoRoute(
        path: '/document-viewer',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is DocumentModel) {
            return DocumentViewerPage(
              document: extra,
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Document not found',
              ),
            ),
          );
        },
      ),

      // ======================================================
      // NOTES
      // ======================================================

      GoRoute(
        path: '/notes',
        builder: (context, state) {
          return const NotesPage();
        },
      ),

      // ======================================================
      // CREATE NOTE
      // ======================================================

      GoRoute(
        path: '/create-note',
        builder: (context, state) {
          return const CreateNotePage();
        },
      ),

      // ======================================================
      // VIEW NOTE
      // ======================================================

      GoRoute(
        path: '/view-note',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is NoteModel) {
            return ViewNotePage(
              note: extra,
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Note not found',
              ),
            ),
          );
        },
      ),

      // ======================================================
      // QR TOOLS
      // ======================================================

      GoRoute(
        path: '/qr-tools',
        builder: (context, state) {
          return const QRToolsPage();
        },
      ),

      // ======================================================
      // PDF & IMAGES
      // ======================================================

      GoRoute(
        path: '/pdf-images',
        builder: (context, state) {
          return const PDFImagesPage();
        },
      ),

      // ======================================================
      // IMAGE TO TEXT
      // ======================================================

      GoRoute(
        path: '/image-to-text',
        builder: (context, state) {
          return const ImageToTextPage();
        },
      ),
    ],
  );
}
