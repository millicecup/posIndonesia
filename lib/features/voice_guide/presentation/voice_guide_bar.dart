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
    return Material(
      color: AppColors.white,
      child: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.lightGrey))),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(s.speaking ? Icons.graphic_eq : Icons.record_voice_over_outlined,
              size: 18, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  s.speaking
                      ? (s.last?.title ?? 'Pemandu suara')
                      : 'Pemandu suara',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600))),
          if (s.last != null)
            IconButton(
                tooltip: 'Ulangi narasi',
                iconSize: 19,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.replay),
                onPressed: c.replay),
          if (s.speaking)
            IconButton(
                tooltip: 'Hentikan suara',
                iconSize: 19,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: c.stop),
          Semantics(
            label:
                s.enabled ? 'Matikan pemandu suara' : 'Nyalakan pemandu suara',
            child: Transform.scale(
              scale: 0.75,
              child: Switch(
                value: s.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.teal,
                onChanged: c.setEnabled,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
