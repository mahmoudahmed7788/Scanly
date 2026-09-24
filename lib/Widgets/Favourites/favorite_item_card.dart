import 'package:flutter/material.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Widgets/Favourites/favorites_utils.dart';

class FavoriteItemCard extends StatelessWidget {
  final ScanlyItem item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const FavoriteItemCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Dismissible(
      key: ValueKey(
        'favorite_${item.id}',
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        onRemove();
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                colors.outlineVariant.withValues(
              alpha: 0.35,
            ),
          ),
          boxShadow: [
            if (theme.brightness ==
                Brightness.light)
              BoxShadow(
                color:
                    colors.onSurface.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 5),
              ),
          ],
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration:
                      BoxDecoration(
                    color:
                        colors.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Icon(
                    FavoritesUtils.iconForType(
                      item.type,
                    ),
                    color:
                        colors.primary,
                    size: 30,
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
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              colors.onSurface,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              colors.primary.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius:
                              BorderRadius.circular(7),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            color:
                                colors.primary,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                IconButton(
                  tooltip:
                      'Remove from favorites',
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: colors.error,
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