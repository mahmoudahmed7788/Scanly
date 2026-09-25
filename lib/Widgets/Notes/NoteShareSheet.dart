import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Service/Notes/NoteShareService.dart';

class NoteShareSheet extends StatefulWidget {
  final NoteModel note;

  const NoteShareSheet({
    super.key,
    required this.note,
  });

  static Future<void> show(
    BuildContext context,
    NoteModel note,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return NoteShareSheet(
          note: note,
        );
      },
    );
  }

  @override
  State<NoteShareSheet> createState() => _NoteShareSheetState();
}

class _NoteShareSheetState extends State<NoteShareSheet> {
  bool _isSharing = false;

  Future<void> _sharePdf() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      Navigator.of(context).pop();

      await NoteShareService.shareAsPdf(widget.note);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not share note: $e'),
          ),
        );
    }
  }

  Future<void> _shareText() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      Navigator.of(context).pop();

      await NoteShareService.shareAsText(widget.note);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not share note: $e'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title = widget.note.title.trim().isEmpty
        ? 'Untitled Note'
        : widget.note.title.trim();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withValues(
                    alpha: .25,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(
                      alpha: .10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    color: colors.primary,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share Note',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface.withValues(
                            alpha: .60,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _ShareOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Share as PDF',
              subtitle:
                  'Professional formatted document',
              color: colors.primary,
              onTap: _sharePdf,
            ),

            const SizedBox(height: 12),

            _ShareOption(
              icon: Icons.text_snippet_outlined,
              title: 'Share as Text',
              subtitle:
                  'Share the note content directly',
              color: colors.secondary,
              onTap: _shareText,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(
        alpha: .45,
      ),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(
                          alpha: .55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: colors.onSurface.withValues(
                  alpha: .35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
