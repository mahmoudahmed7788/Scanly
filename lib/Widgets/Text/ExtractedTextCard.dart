import 'package:flutter/material.dart';

class ExtractedTextCard extends StatelessWidget {
  final String text;
  final bool isSpeaking;
  final VoidCallback onCopy;
  final VoidCallback onSpeech;

  const ExtractedTextCard({
    super.key,
    required this.text,
    required this.isSpeaking,
    required this.onCopy,
    required this.onSpeech,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Extracted Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                onPressed: onCopy,
                icon: const Icon(
                  Icons.copy_outlined,
                  color: Color(0xFF5B5FEF),
                ),
                tooltip: 'Copy',
              ),

              IconButton(
                onPressed: onSpeech,
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_outlined,
                  color: const Color(0xFF12B5EA),
                ),
                tooltip: isSpeaking ? 'Stop' : 'Read',
              ),
            ],
          ),

          const Divider(),

          const SizedBox(height: 10),

          SelectableText(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}