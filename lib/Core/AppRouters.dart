import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/Note_Model.dart';

import 'package:scanly/Pages/Auth/ForgotPasswordVerficationPage.dart';
import 'package:scanly/Pages/Auth/Login_Page.dart';
import 'package:scanly/Pages/Auth/OnBourding_Page.dart';
import 'package:scanly/Pages/Auth/Register_page.dart';
import 'package:scanly/Pages/Auth/ResetPasswordPage.dart';
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

class AppRoutes {
  static List<RouteBase> get routes {
    return [
      _rootRoute(),
      _loginRoute(),
      _registerRoute(),
      _verificationRoute(),
      _forgotPasswordRoute(),
      _forgotPasswordVerificationRoute(),
      _resetPasswordRoute(),
      _onboardingRoute(),
      _mainShell(),
      _profileRoute(),
      _recentRoute(),
      _notificationsRoute(),
      _aboutRoute(),
      _pdfPreviewRoute(),
      _editDocumentRoute(),
      _documentViewerRoute(),
      _notesRoute(),
      _createNoteRoute(),
      _viewNoteRoute(),
      _qrToolsRoute(),
      _pdfImagesRoute(),
      _imageToTextRoute(),
    ];
  }

  static GoRoute _rootRoute() {
    return GoRoute(
      path: '/',
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    );
  }

  static GoRoute _loginRoute() {
    return GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    );
  }

  static GoRoute _registerRoute() {
    return GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterPage();
      },
    );
  }

  static GoRoute _verificationRoute() {
    return GoRoute(
      path: '/verification',
      builder: (context, state) {
        return const VerificationPage();
      },
    );
  }

  static GoRoute _forgotPasswordRoute() {
    return GoRoute(
      path: '/forgot-password',
      builder: (context, state) {
        final Object? extra = state.extra;

        final String email =
            extra is String ? extra : '';

        return ForgotPasswordPage(
          initialEmail:
              email.isEmpty ? null : email, email: '',
        );
      },
    );
  }

  static GoRoute _forgotPasswordVerificationRoute() {
    return GoRoute(
      path: '/forgot-password-verification',
      builder: (context, state) {
        final Object? extra = state.extra;

        final String email =
            extra is String ? extra : '';

        return ForgotPasswordPage(
          email: email,
        );
      },
    );
  }

  static GoRoute _resetPasswordRoute() {
    return GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final String? code =
            state.uri.queryParameters['oobCode'];

        if (code == null || code.isEmpty) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Invalid or expired password reset link.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return ResetPasswordPage(
          code: code,
        );
      },
    );
  }

  static GoRoute _onboardingRoute() {
    return GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        return const OnboardingPage();
      },
    );
  }

  static ShellRoute _mainShell() {
    return ShellRoute(
      builder: (context, state, child) {
        return MainNavigationPage(
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) {
            return const DocumentsPage();
          },
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) {
            return const FavoritesPage();
          },
        ),
        GoRoute(
          path: '/trash',
          builder: (context, state) {
            return const TrashPage();
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            return const SettingsPage();
          },
        ),
      ],
    );
  }

  static GoRoute _profileRoute() {
    return GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfilePage();
      },
    );
  }

  static GoRoute _recentRoute() {
    return GoRoute(
      path: '/recent',
      builder: (context, state) {
        return const RecentPage();
      },
    );
  }

  static GoRoute _notificationsRoute() {
    return GoRoute(
      path: '/notifications',
      builder: (context, state) {
        return const NotificationsPage();
      },
    );
  }

  static GoRoute _aboutRoute() {
    return GoRoute(
      path: '/about',
      builder: (context, state) {
        return const AboutScanlyPage();
      },
    );
  }

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

  static GoRoute _notesRoute() {
    return GoRoute(
      path: '/notes',
      builder: (context, state) {
        return const NotesPage();
      },
    );
  }

  static GoRoute _createNoteRoute() {
    return GoRoute(
      path: '/create-note',
      builder: (context, state) {
        return const CreateNotePage();
      },
    );
  }

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

  static GoRoute _qrToolsRoute() {
    return GoRoute(
      path: '/qr-tools',
      builder: (context, state) {
        return const QRToolsPage();
      },
    );
  }

  static GoRoute _pdfImagesRoute() {
    return GoRoute(
      path: '/pdf-images',
      builder: (context, state) {
        return const PDFImagesPage();
      },
    );
  }

  static GoRoute _imageToTextRoute() {
    return GoRoute(
      path: '/image-to-text',
      builder: (context, state) {
        return const ImageToTextPage();
      },
    );
  }

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