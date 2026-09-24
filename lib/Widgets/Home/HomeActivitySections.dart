import 'package:flutter/material.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Widgets/Home/HomeActivityList.dart';
import 'package:scanly/Widgets/Home/HomeFavoritesList.dart';
import 'package:scanly/Widgets/Home/HomeSectionHeader.dart';
import 'package:scanly/core/ScanlyActivityService.dart';


class HomeActivitySections extends StatefulWidget {
  const HomeActivitySections({
    super.key,
  });

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

    ScanlyActivityService.version.addListener(
      _refresh,
    );

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(
      _refresh,
    );

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
      valueListenable: ScanlyActivityService.version,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: 'Favorites',
              icon: Icons.favorite_rounded,
              onViewAll: () {
                HomeSectionHeader.openFavorites(
                  context,
                );
              },
            ),
            const SizedBox(height: 14),
            HomeFavoritesList(
              items: favorites,
              documents: favoriteDocuments,
            ),
            const SizedBox(height: 32),
            HomeSectionHeader(
              title: 'Recent',
              icon: Icons.history_rounded,
              onViewAll: () {
                HomeSectionHeader.openRecent(
                  context,
                );
              },
            ),
            const SizedBox(height: 14),
            HomeActivityList(
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