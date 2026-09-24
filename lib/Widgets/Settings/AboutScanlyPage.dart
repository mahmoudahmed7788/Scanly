import 'package:flutter/material.dart';
import 'package:scanly/Widgets/Settings/AboutFeature.dart';

class AboutScanlyPage extends StatelessWidget {
  const AboutScanlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
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
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Scan. Save. Organize.',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Scanly',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Scanly is your all-in-one utility app for scanning, organizing, saving, and sharing your digital content.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const AboutFeature(
                      icon: Icons.qr_code_2_rounded,
                      title: 'QR Tools',
                      subtitle:
                          'Create, scan, save, and share QR codes.',
                    ),

                    const SizedBox(height: 14),

                    const AboutFeature(
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      subtitle:
                          'Create and organize your PDF documents.',
                    ),

                    const SizedBox(height: 14),

                    const AboutFeature(
                      icon: Icons.text_fields_rounded,
                      title: 'Text & Voice',
                      subtitle:
                          'Extract text and listen to it with voice tools.',
                    ),

                    const SizedBox(height: 14),

                    const AboutFeature(
                      icon: Icons.note_alt_outlined,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colors.primary,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
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
                  color: colors.onSurface.withOpacity(0.45),
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