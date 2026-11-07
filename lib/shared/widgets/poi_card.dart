// lib/shared/widgets/poi_card.dart
// Kartu POI reusable (dipakai UI03, UI04, UI09).

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/poi.dart';
import 'category_chip.dart';
import 'media_image.dart';

class PoiCard extends StatelessWidget {
  const PoiCard({
    super.key,
    required this.poi,
    this.onTap,
    this.visited = false,
    this.trailing,
  });

  final Poi poi;
  final VoidCallback? onTap;
  final bool visited;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cover = poi.coverImage;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: cover == null
                      ? const ColoredBox(
                          color: AppColors.lightGrey,
                          child: Icon(Icons.image_not_supported),
                        )
                      : MediaImage(cover, download: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${poi.id} · ${poi.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      poi.zone.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    CategoryChip(label: poi.category.label, dense: true),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (visited)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: AppColors.success),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
