import 'package:flutter/material.dart';
import 'package:scanly/Core/HomeActivityUtils.dart';
import 'package:scanly/Core/ScanlyItemOpener.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Widgets/Home/HomeActivityCard.dart';
import 'package:scanly/Widgets/Home/HomeEmptyActivity.dart';

class HomeActivityList extends StatelessWidget {
  final List<ScanlyItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const HomeActivityList({
    super.key,
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return HomeEmptyActivity(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return HomeActivityCard(
            title: item.title,
            type: HomeActivityUtils.displayType(item.type),
            icon: HomeActivityUtils.iconForType(item.type),
            dateTime: HomeActivityUtils.extractItemDateTime(item),
            onTap: () {
              ScanlyItemOpener.open(context, item);
            },
          );
        },
      ),
    );
  }
}
