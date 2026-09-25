import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ========================================================
        // LOGO
        // ========================================================

        Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: Image.asset(
            'assets/images/Scanly_Splash.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 18),

        // ========================================================
        // TITLE
        // ========================================================

        const Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Login to continue to Scanly',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}