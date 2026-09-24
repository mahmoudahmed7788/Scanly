import 'package:flutter/material.dart';
import 'package:scanly/Core/HomeActivityUtils.dart';
import 'package:scanly/Core/ScanlyItemOpener.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Widgets/Home/HomeActivityCard.dart';
import 'package:scanly/Widgets/Home/HomeEmptyActivity.dart';



class HomeFavoritesList extends StatelessWidget {
  final List<ScanlyItem> items;
  final List<DocumentModel> documents;

  const HomeFavoritesList({
    super.key,
    required this.items,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && documents.isEmpty) {
      return const HomeEmptyActivity(
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
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (
          context,
          index,
        ) {
          final entry = entries[index];

          if (entry.item != null) {
            return HomeActivityCard(
              title: entry.item!.title,
              type: HomeActivityUtils.displayType(
                entry.item!.type,
              ),
              icon: HomeActivityUtils.iconForType(
                entry.item!.type,
              ),
              dateTime:
                  HomeActivityUtils.extractItemDateTime(
                entry.item!,
              ),
              onTap: () {
                ScanlyItemOpener.open(
                  context,
                  entry.item!,
                );
              },
            );
          }

          final document = entry.document!;

          return HomeActivityCard(
            title: document.title,
            type: HomeActivityUtils.displayType(
              document.type,
            ),
            icon: HomeActivityUtils.iconForType(
              document.type,
            ),
            dateTime:
                HomeActivityUtils.extractDocumentDateTime(
              document,
            ),
            onTap: () async {
              if (!context.mounted) return;

              await Navigator.of(context).pushNamed(
                '/pdf-preview',
                arguments: document,
              );
            },
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