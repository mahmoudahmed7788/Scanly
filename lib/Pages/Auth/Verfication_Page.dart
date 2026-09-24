import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool isChecking = false;
  bool isResending = false;

  // =========================
  // CHECK EMAIL VERIFICATION
  // =========================

  Future<void> checkVerification() async {
    setState(() {
      isChecking = true;
    });

    final verified =
        await context.read<AuthCubit>().checkEmailVerified();

    if (!mounted) return;

    setState(() {
      isChecking = false;
    });

    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email verified successfully!',
          ),
        ),
      );

      // New User Flow:
      // Verification → Onboarding
      //
      // DON'T logout here.
      // The user should remain logged in.
      context.go('/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your email is not verified yet. Please check your inbox.',
          ),
        ),
      );
    }
  }

  // =========================
  // RESEND VERIFICATION EMAIL
  // =========================

  Future<void> resendEmail() async {
    setState(() {
      isResending = true;
    });

    await context
        .read<AuthCubit>()
        .resendVerificationEmail();

    if (!mounted) return;

    setState(() {
      isResending = false;
    });

    final state = context.read<AuthCubit>().state;

    if (state.status == AuthStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage ?? 'Could not send email.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification email sent again. Check your inbox.',
        ),
      ),
    );
  }

  // =========================
  // CHANGE EMAIL
  // =========================

  Future<void> changeEmail() async {
    await context.read<AuthCubit>().logout();

    if (!mounted) return;

    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B5FEF),
              Color(0xFF7C5CFC),
              Color(0xFF00C2FF),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 50),

              // =========================
              // EMAIL ICON
              // =========================

              Container(
                width: 100,
                height: 100,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),

                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // TITLE
              // =========================

              const Text(
                'Verify Your Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 35,
                ),

                child: Text(
                  'We sent a verification link to your email address.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // =========================
              // BOTTOM CARD
              // =========================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.fromLTRB(
                  25,
                  30,
                  25,
                  25,
                ),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),

                child: Column(
                  children: [
                    // =========================
                    // CARD TITLE
                    // =========================

                    const Text(
                      'Check your inbox',

                      style: TextStyle(
                        color: Color(0xFF292653),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Click the verification link in the email, then come back and tap the button below.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Color(0xFF6F6B98),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =========================
                    // I'VE VERIFIED
                    // =========================

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed:
                            isChecking
                                ? null
                                : checkVerification,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),

                        child: isChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "I've Verified",

                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =========================
                    // RESEND
                    // =========================

                    TextButton(
                      onPressed:
                          isResending
                              ? null
                              : resendEmail,

                      child: isResending
                          ? const Text(
                              'Sending...',
                            )
                          : const Text(
                              'Resend Verification Email',

                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 5),

                    // =========================
                    // CHANGE EMAIL
                    // =========================

                    TextButton(
                      onPressed: changeEmail,

                      child: const Text(
                        'Use a different email',

                        style: TextStyle(
                          color: Color(0xFF6F6B98),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
