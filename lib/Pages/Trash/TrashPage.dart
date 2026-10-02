
import 'package:flutter/material.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Service/Activity/activity_local_storage.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({
    super.key,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage>
    with WidgetsBindingObserver {
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ScanlyActivityService.version.addListener(
      _onActivityChanged,
    );

    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(
      _onActivityChanged,
    );

    super.dispose();
  }

  void _onActivityChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  Future<void> _initialize() async {
    await _reload();
  }

  Future<void> _reload() async {
    try {
      await ScanlyActivityService.reload();
    } catch (e) {
      debugPrint(
        'Trash activity reload error: $e',
      );
    }

    try {
      await ScanlyActivityService.cleanupTrash();
    } catch (e) {
      debugPrint(
        'Trash cleanup error: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  List<TrashItem> get _filteredItems {
    final items = ScanlyActivityService.trash;

    if (_selectedType == 'all') {
      return items;
    }

    return items.where((item) {
      return _normalizeType(item.item.type) ==
          _selectedType;
    }).toList();
  }

  String _normalizeType(String type) {
    final normalized = type
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (normalized == 'qr' ||
        normalized == 'qrcode' ||
        normalized == 'qr_code') {
      return 'qr';
    }

    if (normalized == 'note' ||
        normalized == 'notes') {
      return 'note';
    }

    if (normalized == 'image_to_text' ||
        normalized == 'imagetotext' ||
        normalized == 'ocr') {
      return 'image_to_text';
    }

    return normalized;
  }

  String _typeTitle(String type) {
    switch (_normalizeType(type)) {
      case 'qr':
        return 'QR Code';

      case 'note':
        return 'Note';

      case 'image_to_text':
        return 'Image to Text';

      default:
        return 'Document';
    }
  }

  IconData _typeIcon(String type) {
    switch (_normalizeType(type)) {
      case 'qr':
        return Icons.qr_code_2_rounded;

      case 'note':
        return Icons.note_alt_rounded;

      case 'image_to_text':
        return Icons.text_snippet_rounded;

      default:
        return Icons.description_rounded;
    }
  }

  String _remainingText(TrashItem item) {
    final days = item.remainingDays;

    if (days <= 0) {
      return 'Deleting soon';
    }

    if (days == 1) {
      return '1 day left';
    }

    return '$days days left';
  }

  Future<void> _restore(
    TrashItem item,
  ) async {
    await ScanlyActivityService.restoreTrashItem(
      item.item.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Item restored successfully',
          ),
        ),
      );

    setState(() {});
  }

  Future<void> _deletePermanently(
    TrashItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete permanently?',
          ),
          content: const Text(
            'This item will be permanently deleted and cannot be restored.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ScanlyActivityService.deleteTrashItem(
      item.item.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Item deleted permanently',
          ),
        ),
      );

    setState(() {});
  }

  Future<void> _emptyTrash() async {
    if (ScanlyActivityService.trash.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Empty Trash?',
          ),
          content: const Text(
            'All items in Trash will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Empty Trash',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ScanlyActivityService.clearTrash();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Trash emptied',
          ),
        ),
      );

    setState(() {});
  }

  Widget _buildTypeFilter() {
    final filters = <String, String>{
      'all': 'All',
      'qr': 'QR',
      'note': 'Notes',
      'image_to_text': 'Image to Text',
    };

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) {
          return const SizedBox(
            width: 8,
          );
        },
        itemBuilder: (
          context,
          index,
        ) {
          final entry =
              filters.entries.elementAt(index);

          final selected =
              _selectedType == entry.key;

          return ChoiceChip(
            label: Text(
              entry.value,
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedType = entry.key;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primary
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 44,
                color: colors.primary,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Trash is empty',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Deleted items will stay here for 30 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    TrashItem trashItem,
  ) {
    final item = trashItem.item;

    final colors =
        Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant
              .withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary
                  .withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              _typeIcon(item.type),
              color: colors.primary,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty
                      ? _typeTitle(item.type)
                      : item.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _typeTitle(item.type),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _remainingText(
                    trashItem,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        trashItem.remainingDays <=
                                3
                            ? Colors.red
                            : colors.primary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restore') {
                _restore(trashItem);
              } else if (value == 'delete') {
                _deletePermanently(
                  trashItem,
                );
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(
                        Icons.restore_rounded,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Restore',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .delete_forever_rounded,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Delete permanently',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable:
          ScanlyActivityService.version,
      builder: (
        context,
        _,
        __,
      ) {
        final items = _filteredItems;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Trash',
            ),
            actions: [
              if (ScanlyActivityService
                  .trash
                  .isNotEmpty)
                IconButton(
                  onPressed: _emptyTrash,
                  tooltip: 'Empty Trash',
                  icon: const Icon(
                    Icons
                        .delete_sweep_rounded,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              _buildTypeFilter(),
              const SizedBox(
                height: 12,
              ),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child:
                            ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                            bottom: 24,
                          ),
                          itemCount:
                              items.length,
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            return _buildItem(
                              items[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
