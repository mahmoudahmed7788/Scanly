import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/DocumentModel.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';
import 'package:scanly/ScanlyItemOpener.dart';

class HomeActivitySections extends StatefulWidget {
  const HomeActivitySections({super.key});

  @override
  State<HomeActivitySections> createState() => _HomeActivitySectionsState();
}

class _HomeActivitySectionsState extends State<HomeActivitySections>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ScanlyActivityService.version.addListener(_refresh);

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(_refresh);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDocuments() async {
    await DocumentStorage.syncFromDisk();

    if (!mounted) return;

    setState(() {});
  }

  List<DocumentModel> _favoriteDocuments() {
    return DocumentStorage.getDocuments()
        .where(
          (document) =>
              document.isFavorite && document.type.toLowerCase() == 'pdf',
        )
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ScanlyActivityService.version,
      builder: (context, _, __) {
        final favorites = ScanlyActivityService.favoritePreview;

        final recent = ScanlyActivityService.recentPreview;

        final favoriteDocuments = _favoriteDocuments();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Favorites',
              icon: Icons.favorite_rounded,
              onViewAll: () {
                context.push('/favorites');
              },
            ),
            const SizedBox(height: 12),
            _FavoritesList(items: favorites, documents: favoriteDocuments),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Recent',
              icon: Icons.history_rounded,
              onViewAll: () {
                context.push('/recent');
              },
            ),
            const SizedBox(height: 12),
            _ActivityList(
              items: recent,
              emptyIcon: Icons.history_rounded,
              emptyTitle: 'No Recent Items',
              emptySubtitle: 'Items you open will appear here.',
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final List<ScanlyItem> items;
  final List<DocumentModel> documents;

  const _FavoritesList({required this.items, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && documents.isEmpty) {
      return const _EmptyActivity(
        icon: Icons.favorite_border_rounded,
        title: 'No Favorites Yet',
        subtitle: 'Your favorite items will appear here.',
      );
    }

    final entries = <_FavoriteEntry>[
      ...items.map((item) => _FavoriteEntry.item(item)),
      ...documents.map((document) => _FavoriteEntry.document(document)),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = entries[index];

          if (entry.item != null) {
            return _FavoriteItemCard(item: entry.item!);
          }

          return _FavoriteDocumentCard(document: entry.document!);
        },
      ),
    );
  }
}

class _FavoriteEntry {
  final ScanlyItem? item;
  final DocumentModel? document;

  const _FavoriteEntry.item(this.item) : document = null;

  const _FavoriteEntry.document(this.document) : item = null;
}

class _FavoriteItemCard extends StatelessWidget {
  final ScanlyItem item;

  const _FavoriteItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 250,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScanlyItemOpener.open(context, item);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: colors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteDocumentCard extends StatelessWidget {
  final DocumentModel document;

  const _FavoriteDocumentCard({required this.document});

  Future<void> _openDocument(BuildContext context) async {
    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      return;
    }

    if (!context.mounted) return;

    await context.push(
      '/pdf-preview',
      extra: {
        'pdfBytes': bytes,
        'fileName': '${document.title}.pdf',
        'filePath': path,
        'imagePaths': <String>[],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 250,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDocument(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: colors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'PDF Document',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<ScanlyItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _ActivityList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return _EmptyActivity(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return SizedBox(
            width: 250,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ScanlyItemOpener.open(context, item);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _iconForType(item.type),
                          color: colors.primary,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyActivity({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'qr':
      return Icons.qr_code_2_rounded;
    case 'note':
      return Icons.note_alt_rounded;
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'document':
      return Icons.description_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.folder_rounded;
  }
}
