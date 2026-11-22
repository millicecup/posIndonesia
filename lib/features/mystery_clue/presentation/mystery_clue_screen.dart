// lib/features/mystery_clue/presentation/mystery_clue_screen.dart
// UI18 Mystery Clue: Siapa aku? (A05, POI P08 Mas Soeharto). Wireframe: PRD Gambar 5.6 kanan.
// Petunjuk dan pertanyaan HANYA dari materi tervalidasi (pois.json "mysteryClues" & "quiz",
// sumber Dokumen Sprint 2 PB06). Alur: buka petunjuk satu per satu -> tebak tokoh ->
// lihat biografi -> jawab tiga pertanyaan pilihan ganda (layar kuis) dengan penjelasan jawaban.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/media_image.dart';
import '../state/mystery_state.dart';

class MysteryClueScreen extends ConsumerStatefulWidget {
  const MysteryClueScreen({super.key, required this.poiId, this.onOpenDetail});

  final String poiId;
  final VoidCallback? onOpenDetail;

  @override
  ConsumerState<MysteryClueScreen> createState() => _MysteryClueScreenState();
}

class _MysteryClueScreenState extends ConsumerState<MysteryClueScreen> {
  int _revealed = 1;
  String? _guess;

  /// Nama tokoh lain di dataset sebagai pengecoh tebakan.
  static const _otherFigures = [
    'R. Dijar',
    'Sir Rowland Hill',
    'Mohammad Hatta'
  ];

  String _figureName(Poi poi) =>
      poi.name.replaceFirst(RegExp(r'^Tokoh\s+'), '');

  @override
  Widget build(BuildContext context) {
    final poi = ref.watch(poiByIdProvider(widget.poiId)).valueOrNull;
    if (poi == null) {
      return Scaffold(
          appBar: JejakAppBar(title: const Text('Mystery Clue')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final clues = poi.mysteryClues;
    final answer = _figureName(poi);
    final options = [answer, ..._otherFigures]..sort();
    final solved = _guess == answer;

    return Scaffold(
      appBar: JejakAppBar(
        title: const Text('Mystery Clue'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.explore);
          }
        }),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Petunjuk $_revealed dari ${clues.length}',
                  style: const TextStyle(color: AppColors.grey)),
              Chip(label: Text('POI ${poi.id}')),
            ],
          ),
          for (var i = 0; i < _revealed && i < clues.length; i++)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EADB),
                border: Border.all(color: const Color(0xFFC9B98F)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i == 0 ? 'Siapa aku?' : 'Petunjuk ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('"${clues[i]}"'),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (solved && poi.coverImage != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaImage(poi.coverImage!,
                    height: (MediaQuery.sizeOf(context).height * .55)
                        .clamp(260.0, 420.0),
                    fit: BoxFit.contain),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                height: 200,
                child: ColoredBox(
                    color: AppColors.lightGrey,
                    child: Center(
                        child: Icon(Icons.person_search,
                            size: 72, color: AppColors.grey))),
              ),
            ),
          const SizedBox(height: 12),
          if (!solved) ...[
            const Text('Tebak tokohnya:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor:
                        _guess == o ? const Color(0xFFFFEBEE) : null,
                  ),
                  onPressed: () => setState(() => _guess = o),
                  child: Text(o),
                ),
              ),
            if (_guess != null && !solved)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Belum tepat. Buka petunjuk lain lalu coba lagi!',
                    style: TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _revealed < clues.length
                  ? () => setState(() => _revealed++)
                  : null,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_revealed < clues.length
                  ? 'Petunjuk lain'
                  : 'Semua petunjuk terbuka'),
            ),
          ] else ...[
            Text('Benar, aku $answer!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.success)),
            const SizedBox(height: 6),
            const Text(
                'Tebakanmu tepat! Buka detail koleksi untuk mengenal kisah tokoh ini.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(mysterySolvedPoiIdsProvider.notifier)
                    .update((ids) => {...ids, poi.id});
                if (widget.onOpenDetail != null) {
                  widget.onOpenDetail!();
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.poiDetail(poi.id));
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Lihat detail koleksi'),
            ),
          ],
        ],
      ),
    );
  }
}
