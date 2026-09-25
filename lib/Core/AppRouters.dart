import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/Note_Model.dart';

import 'package:scanly/Pages/Auth/ForgotPasswordVerficationPage.dart';
import 'package:scanly/Pages/Auth/Login_Page.dart';
import 'package:scanly/Pages/Auth/OnBourding_Page.dart';
import 'package:scanly/Pages/Auth/Register_page.dart';
import 'package:scanly/Pages/Auth/Verfication_Page.dart';

import 'package:scanly/Pages/Documents/DocumentsPage.dart';
import 'package:scanly/Pages/Documents/EditDocumentPage.dart';
import 'package:scanly/Pages/Home/FavouritesPage.dart';

import 'package:scanly/Pages/Home/Home_Page.dart';
import 'package:scanly/Pages/Home/NotificationPage.dart';
import 'package:scanly/Pages/Home/ProfilePage.dart';
import 'package:scanly/Pages/Home/Recent_Page.dart';
import 'package:scanly/Pages/Home/SettingsPage.dart';

import 'package:scanly/Pages/Notes/Notes_Page.dart';
import 'package:scanly/Pages/Notes/create_note_page.dart';
import 'package:scanly/Pages/Notes/view_note_page.dart';

import 'package:scanly/Pages/Pdf/PDFPreviewPage.dart';

import 'package:scanly/Pages/QR/QR_Tools_Page.dart';

import 'package:scanly/Pages/Text/ImageToTextPage.dart';

import 'package:scanly/Pages/Trash/TrashPage.dart';

import 'package:scanly/Widgets/Documents/DocumentViewerPage.dart';
import 'package:scanly/Widgets/Home/MainNavigationBar.dart';
import 'package:scanly/Pages/Pdf/PDFImagesPage.dart';
import 'package:scanly/Widgets/Settings/AboutScanlyPage.dart';

// ============================================================
// APP ROUTES
// ============================================================

class AppRoutes {
  // ==========================================================
  // ALL ROUTES
  // ==========================================================

  static List<RouteBase> get routes {
    return [
      // ======================================================
      // AUTH ROUTES
      // ======================================================

      _rootRoute(),
      _loginRoute(),
      _registerRoute(),
      _verificationRoute(),
      _forgotPasswordRoute(),
      _onboardingRoute(),

      // ======================================================
      // MAIN APP
      // ======================================================

      _mainShell(),

      // ======================================================
      // HOME / SECONDARY
      // ======================================================

      _profileRoute(),
      _recentRoute(),
      _notificationsRoute(),
      _aboutRoute(),

      // ======================================================
      // DOCUMENTS
      // ======================================================

      _pdfPreviewRoute(),
      _editDocumentRoute(),
      _documentViewerRoute(),

      // ======================================================
      // NOTES
      // ======================================================

      _notesRoute(),
      _createNoteRoute(),
      _viewNoteRoute(),

      // ======================================================
      // TOOLS
      // ======================================================

      _qrToolsRoute(),
      _pdfImagesRoute(),
      _imageToTextRoute(),
    ];
  }

  // ==========================================================
  // ROOT
  // ==========================================================

  static GoRoute _rootRoute() {
    return GoRoute(
      path: '/',
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    );
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static GoRoute _loginRoute() {
    return GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    );
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  static GoRoute _registerRoute() {
    return GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterPage();
      },
    );
  }

  // ==========================================================
  // VERIFICATION
  // ==========================================================

  static GoRoute _verificationRoute() {
    return GoRoute(
      path: '/verification',
      builder: (context, state) {
        return const VerificationPage();
      },
    );
  }

  // ==========================================================
  // FORGOT PASSWORD
  // ==========================================================

  static GoRoute _forgotPasswordRoute() {
    return GoRoute(
      path: '/forgot-password-verification',
      builder: (context, state) {
        return const ForgotPasswordVerificationPage(
          email: '',
        );
      },
    );
  }

  // ==========================================================
  // ONBOARDING
  // ==========================================================

  static GoRoute _onboardingRoute() {
    return GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        return const OnboardingPage();
      },
    );
  }

  // ==========================================================
  // MAIN SHELL
  // ==========================================================

  static ShellRoute _mainShell() {
    return ShellRoute(
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
        // ====================================================
        // HOME
        // ====================================================

        GoRoute(
          path: '/home',
          builder: (context, state) {
            return const HomePage();
          },
        ),

        // ====================================================
        // DOCUMENTS
        // ====================================================

        GoRoute(
          path: '/documents',
          builder: (context, state) {
            return const DocumentsPage();
          },
        ),

        // ====================================================
        // FAVORITES
        // ====================================================

        GoRoute(
          path: '/favorites',
          builder: (context, state) {
            return const FavoritesPage();
          },
        ),

        // ====================================================
        // TRASH
        // ====================================================

        GoRoute(
          path: '/trash',
          builder: (context, state) {
            return const TrashPage();
          },
        ),

        // ====================================================
        // SETTINGS
        // ====================================================

        GoRoute(
          path: '/settings',
          builder: (context, state) {
            return const SettingsPage();
          },
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE
  // ==========================================================

  static GoRoute _profileRoute() {
    return GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfilePage();
      },
    );
  }

  // ==========================================================
  // RECENT
  // ==========================================================

  static GoRoute _recentRoute() {
    return GoRoute(
      path: '/recent',
      builder: (context, state) {
        return const RecentPage();
      },
    );
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  static GoRoute _notificationsRoute() {
    return GoRoute(
      path: '/notifications',
      builder: (context, state) {
        return const NotificationsPage();
      },
    );
  }

  // ==========================================================
  // ABOUT
  // ==========================================================

  static GoRoute _aboutRoute() {
    return GoRoute(
      path: '/about',
      builder: (context, state) {
        return const AboutScanlyPage();
      },
    );
  }

  // ==========================================================
  // PDF PREVIEW
  // ==========================================================

  static GoRoute _pdfPreviewRoute() {
    return GoRoute(
      path: '/pdf-preview',
      builder: (context, state) {
        final Object? extra = state.extra;

        if (extra is DocumentModel) {
          return PDFPreviewPage(
            document: extra,
            pdfBytes: Uint8List(0),
            fileName: '',
          );
        }

        return _documentNotFound();
      },
    );
  }

  // ==========================================================
  // EDIT DOCUMENT
  // ==========================================================

  static GoRoute _editDocumentRoute() {
    return GoRoute(
      path: '/edit-document',
      builder: (context, state) {
        final Object? extra = state.extra;

        if (extra is DocumentModel) {
          return EditDocumentPage(
            document: extra,
          );
        }

        return _documentNotFound();
      },
    );
  }

  // ==========================================================
  // DOCUMENT VIEWER
  // ==========================================================

  static GoRoute _documentViewerRoute() {
    return GoRoute(
      path: '/document-viewer',
      builder: (context, state) {
        final Object? extra = state.extra;

        if (extra is DocumentModel) {
          return DocumentViewerPage(
            document: extra,
          );
        }

        return _documentNotFound();
      },
    );
  }

  // ==========================================================
  // NOTES
  // ==========================================================

  static GoRoute _notesRoute() {
    return GoRoute(
      path: '/notes',
      builder: (context, state) {
        return const NotesPage();
      },
    );
  }

  // ==========================================================
  // CREATE NOTE
  // ==========================================================

  static GoRoute _createNoteRoute() {
    return GoRoute(
      path: '/create-note',
      builder: (context, state) {
        return const CreateNotePage();
      },
    );
  }

  // ==========================================================
  // VIEW NOTE
  // ==========================================================

  static GoRoute _viewNoteRoute() {
    return GoRoute(
      path: '/view-note',
      builder: (context, state) {
        final Object? extra = state.extra;

        if (extra is NoteModel) {
          return ViewNotePage(
            note: extra,
          );
        }

        return _noteNotFound();
      },
    );
  }

  // ==========================================================
  // QR TOOLS
  // ==========================================================

  static GoRoute _qrToolsRoute() {
    return GoRoute(
      path: '/qr-tools',
      builder: (context, state) {
        return const QRToolsPage();
      },
    );
  }

  // ==========================================================
  // PDF & IMAGES
  // ==========================================================

  static GoRoute _pdfImagesRoute() {
    return GoRoute(
      path: '/pdf-images',
      builder: (context, state) {
        return const PDFImagesPage();
      },
    );
  }

  // ==========================================================
  // IMAGE TO TEXT
  // ==========================================================

  static GoRoute _imageToTextRoute() {
    return GoRoute(
      path: '/image-to-text',
      builder: (context, state) {
        return const ImageToTextPage();
      },
    );
  }

  // ==========================================================
  // ERROR WIDGETS
  // ==========================================================

  static Widget _documentNotFound() {
    return const Scaffold(
      body: Center(
        child: Text(
          'Document not found',
        ),
      ),
    );
  }

  static Widget _noteNotFound() {
    return const Scaffold(
      body: Center(
        child: Text(
          'Note not found',
        ),
      ),
    );
  }
}