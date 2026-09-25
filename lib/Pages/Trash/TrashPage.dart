import 'package:flutter/material.dart';

import 'package:scanly/Models/TrashItem.dart';
import 'package:scanly/Service/Trash/TrashService.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({
    super.key,
  });

  @override
  State<TrashPage> createState() =>
      _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<TrashItem> _items = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    await TrashService.cleanupExpiredItems();

    final items =
        await TrashService.getItems();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _restore(
    TrashItem item,
  ) async {
    await TrashService.restore(item);

    await _loadTrash();
  }

  Future<void> _permanentDelete(
    TrashItem item,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete permanently?',
          ),
          content: Text(
            '"${item.title}" will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete permanently',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await TrashService.permanentlyDelete(
      item,
    );

    await _loadTrash();
  }

  Future<void> _emptyTrash() async {
    if (_items.isEmpty) return;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
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
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
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

    await TrashService.emptyTrash();

    await _loadTrash();
  }

  IconData _iconForType(
    TrashItemType type,
  ) {
    switch (type) {
      case TrashItemType.document:
        return Icons.description_outlined;

      case TrashItemType.note:
        return Icons.notes_outlined;

      case TrashItemType.pdf:
        return Icons.picture_as_pdf_outlined;

      case TrashItemType.image:
        return Icons.image_outlined;

      case TrashItemType.qr:
        return Icons.qr_code_2_outlined;

      case TrashItemType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _typeName(
    TrashItemType type,
  ) {
    switch (type) {
      case TrashItemType.document:
        return 'Document';

      case TrashItemType.note:
        return 'Note';

      case TrashItemType.pdf:
        return 'PDF';

      case TrashItemType.image:
        return 'Image';

      case TrashItemType.qr:
        return 'QR Code';

      case TrashItemType.other:
        return 'Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trash',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Empty Trash',
              onPressed: _emptyTrash,
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  onRefresh: _loadTrash,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      30,
                    ),
                    itemCount: _items.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 10,
                    ),
                    itemBuilder:
                        (context, index) {
                      return _buildTrashItem(
                        _items[index],
                        colors,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colors,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 80,
              color: colors.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Trash is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deleted documents, notes, PDFs, images and QR codes will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashItem(
    TrashItem item,
    ColorScheme colors,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(item.type),
                color:
                    colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_typeName(item.type)} • '
                    '${item.remainingDays} '
                    '${item.remainingDays == 1 ? 'day' : 'days'} left',
                    style: TextStyle(
                      color:
                          colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'restore') {
                  _restore(item);
                }

                if (value == 'delete') {
                  _permanentDelete(item);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Icon(
                        Icons.restore,
                      ),
                      title: Text('Restore'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_forever,
                      ),
                      title: Text(
                        'Delete permanently',
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}