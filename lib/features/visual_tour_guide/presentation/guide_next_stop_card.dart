// lib/features/visual_tour_guide/presentation/guide_next_stop_card.dart
// Satu kartu "Saran pemandu" yang sama untuk Jelajah, Pemandu tur, dan Progres (DF-07).
// Sumbernya satu: recommendedNextPoiProvider, jadi rekomendasi di semua layar selalu sinkron.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/postman_guide.dart';

class GuideNextStopCard extends StatelessWidget {
  const GuideNextStopCard({super.key, required this.next, this.margin});

  /// null = semua koleksi sudah dikunjungi.
  final Poi? next;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final next = this.next;
    return Card(
      key: const Key('guide-next-stop'),
      margin: margin ?? EdgeInsets.zero,
      color: AppColors.orangeLight,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.orange),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: next == null
            ? null
            : () => context.push(AppRoutes.poiDetail(next.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              const PostmanGuide(size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Saran pemandu',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange)),
                    const SizedBox(height: 2),
                    Text(
                      next == null
                          ? 'Semua koleksi sudah dikunjungi. Akhiri kunjungan '
                              'di tab Progres untuk mendapat cap.'
                          : 'Berikutnya: ${next.id} ${next.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                          height: 1.35),
                    ),
                    if (next != null)
                      Text(next.zone.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
              if (next != null)
                IconButton.filled(
                  tooltip: 'Tunjukkan arah',
                  icon: const Icon(Icons.directions_walk),
                  onPressed: () => context.push(AppRoutes.navigateTo(next.id)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
