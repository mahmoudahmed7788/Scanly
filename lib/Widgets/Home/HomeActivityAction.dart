import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/ScanlyItemOpener.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/core/ScanlyActivityService.dart';


class HomeActivitySections extends StatefulWidget {
  const HomeActivitySections({super.key});

  @override
  State<HomeActivitySections> createState() =>
      _HomeActivitySectionsState();
}

class _HomeActivitySectionsState
    extends State<HomeActivitySections>
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
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadDocuments() async {
    await DocumentStorage.syncFromDisk();

    if (!mounted) return;

    setState(() {});
  }

  List<DocumentModel> _favoriteDocuments() {
    return DocumentStorage.getDocuments()
        .where(
          (document) => document.isFavorite,
        )
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable:
          ScanlyActivityService.version,
      builder: (
        context,
        _,
        __,
      ) {
        final favorites =
            ScanlyActivityService.favoritePreview;

        final recent =
            ScanlyActivityService.recentPreview;

        final favoriteDocuments =
            _favoriteDocuments();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Favorites',
              icon: Icons.favorite_rounded,
              onViewAll: () {
                context.push('/favorites');
              },
            ),

            const SizedBox(height: 14),

            _FavoritesList(
              items: favorites,
              documents: favoriteDocuments,
            ),

            const SizedBox(height: 32),

            _SectionHeader(
              title: 'Recent',
              icon: Icons.history_rounded,
              onViewAll: () {
                context.push('/recent');
              },
            ),

            const SizedBox(height: 14),

            _ActivityList(
              items: recent,
              emptyIcon: Icons.history_rounded,
              emptyTitle: 'No Recent Items',
              emptySubtitle:
                  'Items you open will appear here.',
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

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
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 19,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: TextStyle(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FAVORITES LIST
// ============================================================

class _FavoritesList extends StatelessWidget {
  final List<ScanlyItem> items;
  final List<DocumentModel> documents;

  const _FavoritesList({
    required this.items,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty &&
        documents.isEmpty) {
      return const _EmptyActivity(
        icon: Icons.favorite_border_rounded,
        title: 'No Favorites Yet',
        subtitle:
            'Your favorite items will appear here.',
      );
    }

    final entries = <_FavoriteEntry>[
      ...items.map(
        (item) => _FavoriteEntry.item(item),
      ),
      ...documents.map(
        (document) =>
            _FavoriteEntry.document(document),
      ),
    ];

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (
          context,
          index,
        ) {
          final entry = entries[index];

          if (entry.item != null) {
            return _FavoriteItemCard(
              item: entry.item!,
            );
          }

          return _FavoriteDocumentCard(
            document: entry.document!,
          );
        },
      ),
    );
  }
}

class _FavoriteEntry {
  final ScanlyItem? item;
  final DocumentModel? document;

  const _FavoriteEntry.item(
    this.item,
  ) : document = null;

  const _FavoriteEntry.document(
    this.document,
  ) : item = null;
}

// ============================================================
// FAVORITE ITEM CARD
// ============================================================

class _FavoriteItemCard
    extends StatelessWidget {
  final ScanlyItem item;

  const _FavoriteItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return _ActivityCard(
      title: item.title,
      type: _displayType(item.type),
      icon: _iconForType(item.type),
      dateTime:
          _extractItemDateTime(item),
      onTap: () {
        ScanlyItemOpener.open(
          context,
          item,
        );
      },
    );
  }
}

// ============================================================
// FAVORITE DOCUMENT CARD
// ============================================================

class _FavoriteDocumentCard
    extends StatelessWidget {
  final DocumentModel document;

  const _FavoriteDocumentCard({
    required this.document,
  });

  Future<void> _openDocument(
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    // =======================================================
    // IMPORTANT:
    // Router expects DocumentModel in state.extra.
    // Do NOT send a Map here.
    // =======================================================

    await context.push(
      '/pdf-preview',
      extra: document,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ActivityCard(
      title: document.title,
      type: _displayType(document.type),
      icon: _iconForType(document.type),
      dateTime:
          _extractDocumentDateTime(
        document,
      ),
      onTap: () {
        _openDocument(context);
      },
    );
  }
}

// ============================================================
// RECENT LIST
// ============================================================

class _ActivityList
    extends StatelessWidget {
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
    if (items.isEmpty) {
      return _EmptyActivity(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (
          context,
          index,
        ) {
          final item = items[index];

          return _ActivityCard(
            title: item.title,
            type: _displayType(item.type),
            icon: _iconForType(item.type),
            dateTime:
                _extractItemDateTime(item),
            onTap: () {
              ScanlyItemOpener.open(
                context,
                item,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// ACTIVITY CARD
// ============================================================

class _ActivityCard
    extends StatelessWidget {
  final String title;
  final String type;
  final IconData icon;
  final String dateTime;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.type,
    required this.icon,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return SizedBox(
      width: 285,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant
                    .withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface
                      .withOpacity(
                    theme.brightness ==
                            Brightness.dark
                        ? 0.10
                        : 0.045,
                  ),
                  blurRadius: 14,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              child: Row(
                children: [
                  _TypeIcon(
                    icon: icon,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trim().isEmpty
                              ? 'Untitled'
                              : title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                colors.onSurface,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: colors
                                    .primary
                                    .withOpacity(
                                  0.09,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(7),
                              ),
                              child: Text(
                                type,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  color:
                                      colors.primary,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(width: 7),

                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .access_time_rounded,
                                    size: 12,
                                    color: colors
                                        .onSurfaceVariant,
                                  ),

                                  const SizedBox(
                                    width: 3,
                                  ),

                                  Expanded(
                                    child: Text(
                                      dateTime,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          TextStyle(
                                        color: colors
                                            .onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(
                      color: colors.primary
                          .withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons
                          .chevron_right_rounded,
                      color:
                          colors.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TYPE ICON
// ============================================================

class _TypeIcon
    extends StatelessWidget {
  final IconData icon;

  const _TypeIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            colors.primary
                .withOpacity(0.14),
            colors.secondary
                .withOpacity(0.08),
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: colors.primary,
        size: 27,
      ),
    );
  }
}

// ============================================================
// EMPTY ACTIVITY
// ============================================================

class _EmptyActivity
    extends StatelessWidget {
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
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration:
          BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colors
              .outlineVariant
              .withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
                BoxDecoration(
              color: colors.primary
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        colors.onSurface,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        colors.onSurfaceVariant,
                    fontSize: 12,
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

// ============================================================
// TYPE
// ============================================================

String _displayType(String type) {
  final normalized =
      type.trim().toLowerCase();

  switch (normalized) {
    case 'qr':
    case 'qrcode':
    case 'qr_code':
    case 'qr code':
      return 'QR Code';

    case 'pdf':
      return 'PDF';

    case 'image':
    case 'images':
      return 'Image';

    case 'note':
    case 'notes':
      return 'Note';

    case 'document':
    case 'doc':
      return 'Document';

    case 'voice':
    case 'audio':
      return 'Voice';

    case 'text':
      return 'Text';

    default:
      return type.trim().isEmpty
          ? 'Item'
          : type.trim();
  }
}

IconData _iconForType(String type) {
  final normalized =
      type.trim().toLowerCase();

  switch (normalized) {
    case 'qr':
    case 'qrcode':
    case 'qr_code':
    case 'qr code':
      return Icons.qr_code_2_rounded;

    case 'pdf':
      return Icons.picture_as_pdf_rounded;

    case 'image':
    case 'images':
      return Icons.image_rounded;

    case 'note':
    case 'notes':
      return Icons.note_alt_rounded;

    case 'document':
    case 'doc':
      return Icons.description_rounded;

    case 'voice':
    case 'audio':
      return Icons.mic_rounded;

    case 'text':
      return Icons.text_snippet_rounded;

    default:
      return Icons.folder_rounded;
  }
}

// ============================================================
// DATE / TIME
// ============================================================

String _formatDateTime(dynamic value) {
  if (value == null) {
    return 'Recently';
  }

  DateTime? date;

  if (value is DateTime) {
    date = value;
  } else if (value is String) {
    final text = value.trim();

    if (text.isEmpty) {
      return 'Recently';
    }

    final number = int.tryParse(text);

    if (number != null) {
      date =
          _timestampToDateTime(number);
    } else {
      date =
          DateTime.tryParse(text);
    }
  } else if (value is int) {
    date =
        _timestampToDateTime(value);
  } else if (value is double) {
    date =
        _timestampToDateTime(
      value.toInt(),
    );
  }

  if (date == null) {
    return 'Recently';
  }

  final local = date.toLocal();
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final itemDay = DateTime(
    local.year,
    local.month,
    local.day,
  );

  final difference =
      today.difference(itemDay).inDays;

  final hour =
      local.hour % 12 == 0
          ? 12
          : local.hour % 12;

  final minute =
      local.minute
          .toString()
          .padLeft(2, '0');

  final period =
      local.hour >= 12
          ? 'PM'
          : 'AM';

  final time =
      '$hour:$minute $period';

  if (difference == 0) {
    return 'Today • $time';
  }

  if (difference == 1) {
    return 'Yesterday • $time';
  }

  if (difference > 1 &&
      difference < 7) {
    return '${_weekday(local.weekday)} • $time';
  }

  final day =
      local.day
          .toString()
          .padLeft(2, '0');

  final month =
      local.month
          .toString()
          .padLeft(2, '0');

  return '$day/$month/${local.year} • $time';
}

// ============================================================
// TIMESTAMP CONVERTER
// ============================================================

DateTime _timestampToDateTime(
  int timestamp,
) {
  if (timestamp.abs() >=
      100000000000) {
    return DateTime
        .fromMillisecondsSinceEpoch(
      timestamp,
    );
  }

  return DateTime
      .fromMillisecondsSinceEpoch(
    timestamp * 1000,
  );
}

// ============================================================
// WEEKDAY
// ============================================================

String _weekday(int day) {
  switch (day) {
    case DateTime.monday:
      return 'Mon';

    case DateTime.tuesday:
      return 'Tue';

    case DateTime.wednesday:
      return 'Wed';

    case DateTime.thursday:
      return 'Thu';

    case DateTime.friday:
      return 'Fri';

    case DateTime.saturday:
      return 'Sat';

    case DateTime.sunday:
      return 'Sun';

    default:
      return '';
  }
}

// ============================================================
// DOCUMENT DATE
// ============================================================

String _extractDocumentDateTime(
  DocumentModel document,
) {
  return _formatDateTime(
    document.date,
  );
}

// ============================================================
// SCANLY ITEM DATE
// ============================================================

String _extractItemDateTime(
  ScanlyItem item,
) {
  final dynamic rawItem = item;

  try {
    final value = rawItem.dateTime;

    if (value != null) {
      return _formatDateTime(value);
    }
  } catch (_) {}

  try {
    final value = rawItem.date;

    if (value != null) {
      return _formatDateTime(value);
    }
  } catch (_) {}

  try {
    final value = rawItem.createdAt;

    if (value != null) {
      return _formatDateTime(value);
    }
  } catch (_) {}

  try {
    final value = rawItem.openedAt;

    if (value != null) {
      return _formatDateTime(value);
    }
  } catch (_) {}

  return 'Recently';
}