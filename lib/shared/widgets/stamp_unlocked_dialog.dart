// lib/shared/widgets/stamp_unlocked_dialog.dart
// UI13 Prangko Digital Terbuka (F08): popup setelah aktivitas POI selesai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'random_stamp_art.dart';

/// Tampilkan popup prangko baru. [isNew] false = prangko sudah ada (tidak diduplikasi).
Future<void> showStampUnlockedDialog(BuildContext context,
    {required Poi poi, required bool isNew}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: isNew ? AppColors.orange : AppColors.grey,
                borderRadius: BorderRadius.circular(4)),
            child: Text(isNew ? 'Prangko baru' : 'Sudah ada di album',
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(height: 16),
          StampFrame(
              image: poi.stamp.image,
              random: poi.stamp.isRandom,
              label: '${poi.id}: ${poi.stamp.title}'),
          const SizedBox(height: 12),
          Text(poi.name,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(poi.stamp.trivia,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.qrScanner);
                },
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Scan koleksi lain'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.album);
                },
                icon: const Icon(Icons.collections_bookmark_outlined, size: 20),
                label: const Text('Lihat album'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.explore);
                },
                child: const Text('Kembali ke jelajah'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Bingkai prangko bergerigi sederhana (garis putus) di sekitar gambar prangko.
class StampFrame extends ConsumerWidget {
  const StampFrame(
      {super.key,
      this.image,
      this.label,
      this.size = 130,
      this.locked = false,
      this.random = false});

  final String? image;
  final String? label;
  final double size;
  final bool locked;

  /// true = prangko acak P11; desain dari seed yang tersimpan.
  final bool random;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed =
        random ? ref.watch(activityStatsProvider).randomStampSeed : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size * 1.15,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
                color: locked ? AppColors.lightGrey : AppColors.grey,
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside),
            borderRadius: BorderRadius.circular(4),
            boxShadow: locked
                ? null
                : const [
                    BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
          ),
          child: locked
              ? const ColoredBox(
                  color: AppColors.lightGrey,
                  child: Center(
                      child: Text('?',
                          style:
                              TextStyle(fontSize: 32, color: AppColors.grey))))
              : seed != null
                  ? RandomStampArt(seed: seed)
                  : (image != null
                      ? Image.asset(
                          image!,
                          fit: image == 'assets/images/stamps/stamp_p09.jpg'
                              ? BoxFit.contain
                              : BoxFit.cover,
                        )
                      : const Icon(Icons.local_post_office, size: 48)),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
