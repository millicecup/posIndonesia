import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/poi.dart';
import 'media_image.dart';

class PoiCard extends StatelessWidget {
  const PoiCard(
      {super.key,
      required this.poi,
      this.onTap,
      this.visited = false,
      this.trailing});
  final Poi poi;
  final VoidCallback? onTap;
  final bool visited;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 94,
                      height: 136,
                      child: poi.coverImage == null
                          ? const ColoredBox(
                              color: AppColors.lightGrey,
                              child: Icon(Icons.image_not_supported))
                          : MediaImage(poi.coverImage!,
                              download: false, alignment: Alignment.topCenter),
                    )),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(poi.id,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        if (visited) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle,
                              size: 14, color: AppColors.teal)
                        ],
                      ]),
                      const SizedBox(height: 6),
                      Text(poi.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 7),
                      Text(poi.zone.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(poi.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ])),
                if (trailing != null) trailing!,
              ]),
            )),
      );
}
