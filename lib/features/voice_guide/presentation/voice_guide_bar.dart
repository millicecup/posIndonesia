// lib/features/voice_guide/presentation/voice_guide_bar.dart
// Bar kontrol pemandu suara: nyala/mati, Ulangi narasi terakhir, dan Stop.
// Ditampilkan di atas navigasi bawah dan di layar pemandu/detail POI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../state/voice_guide_controller.dart';

class VoiceGuideBar extends ConsumerWidget {
  const VoiceGuideBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(voiceGuideProvider);
    final c = ref.read(voiceGuideProvider.notifier);
    final subtitle = s.speaking
        ? 'Sedang berbicara: ${s.last?.title ?? ''}'
        : s.last != null
            ? 'Terakhir: ${s.last!.title}'
            : (s.enabled
                ? 'Aktif: pemandu berbicara saat kamu tiba di koleksi'
                : 'Mati: narasi otomatis tidak diputar');

    return Material(
      color: s.enabled ? AppColors.orangeLight : AppColors.lightGrey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        child: Row(
          children: [
            Tooltip(
              message: s.enabled
                  ? 'Matikan pemandu suara'
                  : 'Nyalakan pemandu suara',
              child: Switch(
                value: s.enabled,
                activeThumbColor: AppColors.orange,
                onChanged: c.setEnabled,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                        s.speaking ? Icons.graphic_eq : Icons.record_voice_over,
                        size: 16,
                        color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    const Text('Pemandu suara',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkGrey)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ulangi narasi',
              icon: const Icon(Icons.replay),
              onPressed: s.last == null ? null : c.replay,
            ),
            IconButton(
              tooltip: 'Hentikan suara',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: s.speaking ? c.stop : null,
            ),
          ],
        ),
      ),
    );
  }
}
