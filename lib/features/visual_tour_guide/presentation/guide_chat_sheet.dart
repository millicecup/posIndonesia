// lib/features/visual_tour_guide/presentation/guide_chat_sheet.dart
// Ngobrol dengan pemandu (maskot) di Detail POI (DF-07): interaksi dua arah berbentuk
// chat. Pengguna memilih pertanyaan, pemandu menjawab dari data POI (pois.json); tidak
// ada fakta yang dikarang di sini.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/postman_guide.dart';
import '../../poi_detail/presentation/poi_activity_launcher.dart';
import '../../voice_guide/state/voice_guide_controller.dart';

Future<void> showGuideChat(BuildContext context, Poi poi) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => GuideChatSheet(poi: poi),
    );

enum GuideQuestion { summary, fact, activities, location, next, read }

extension on GuideQuestion {
  String get label => switch (this) {
        GuideQuestion.summary => 'Ceritakan singkat',
        GuideQuestion.fact => 'Fakta menarik',
        GuideQuestion.activities => 'Apa yang bisa kulakukan?',
        GuideQuestion.location => 'Di mana tepatnya?',
        GuideQuestion.next => 'Ke mana setelah ini?',
        GuideQuestion.read => 'Bacakan untukku',
      };
}

class _Message {
  const _Message(this.text, {required this.fromGuide});
  final String text;
  final bool fromGuide;
}

class GuideChatSheet extends ConsumerStatefulWidget {
  const GuideChatSheet({super.key, required this.poi});
  final Poi poi;

  @override
  ConsumerState<GuideChatSheet> createState() => _GuideChatSheetState();
}

class _GuideChatSheetState extends ConsumerState<GuideChatSheet> {
  final _scroll = ScrollController();
  late final List<_Message> _messages = [
    _Message(
        'Halo! Kamu sedang di ${widget.poi.name}. '
        'Mau aku jelaskan apa tentang koleksi ini?',
        fromGuide: true),
  ];
  int _factIndex = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'\[[^\]]*\]\s*'), '').trim();

  Future<String> _answer(GuideQuestion q) async {
    final poi = widget.poi;
    switch (q) {
      case GuideQuestion.summary:
        return _clean(poi.shortDescription);
      case GuideQuestion.fact:
        if (poi.keyFacts.isEmpty) {
          return 'Fakta koleksi ini sedang disiapkan bersama museum.';
        }
        final i = _factIndex % poi.keyFacts.length;
        _factIndex++;
        return 'Fakta ${i + 1} dari ${poi.keyFacts.length}: '
            '${_clean(poi.keyFacts[i])}';
      case GuideQuestion.activities:
        final acts = poi.activities.map(poiActivityLabel).toList();
        return [
          if (acts.isNotEmpty)
            'Di sini kamu bisa mencoba: ${acts.join(', ')}.'
          else
            'Baca ceritanya dan lihat galeri foto koleksi ini.',
          'Setelah selesai, tekan "Selesai & ambil prangko" untuk mengisi album.',
        ].join(' ');
      case GuideQuestion.location:
        final zone = poi.zone.description;
        return zone.isEmpty
            ? '${poi.name} ada di Zona ${poi.zone.code}.'
            : '${poi.name} ada di Zona ${poi.zone.code}: $zone.';
      case GuideQuestion.next:
        final progress = await ref.read(progressProvider.future);
        final next = await ref.read(poiRepositoryProvider).getRecommendedNextPoi(
            {...progress.visitedPoiIds, poi.id}.toList());
        return next == null
            ? 'Kamu sudah menjelajahi semua koleksi. Hebat! Jangan lupa '
                'akhiri kunjungan di tab Progres untuk mendapat cap.'
            : 'Setelah ini, coba ${next.id} ${next.name}'
                '${next.zone.description.isEmpty ? '' : ' (${next.zone.description})'}.';
      case GuideQuestion.read:
        await ref.read(voiceGuideProvider.notifier).introducePoi(poi);
        return 'Siap, aku bacakan lewat pemandu suara. Kamu bisa menjeda atau '
            'melanjutkannya di bar pemandu suara.';
    }
  }

  Future<void> _ask(GuideQuestion q) async {
    setState(() => _messages.add(_Message(q.label, fromGuide: false)));
    final reply = await _answer(q);
    if (!mounted) return;
    setState(() => _messages.add(_Message(reply, fromGuide: true)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .72;
    return SizedBox(
      key: const Key('guide-chat'),
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const PostmanGuide(size: 40),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Pemandu JejakPOS',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(message: _messages[i]),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Satu baris yang bisa digeser agar ruang chat tetap lega
                  // di layar kecil / huruf besar.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final q in GuideQuestion.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(q.label),
                              onPressed: () => _ask(q),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.tourFor(widget.poi.id));
                    },
                    icon: const Icon(Icons.route_outlined, size: 18),
                    label: const Text('Buka pemandu tur'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final guide = message.fromGuide;
    return Align(
      alignment: guide ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        decoration: BoxDecoration(
          color: guide ? AppColors.white : AppColors.orange,
          border: guide ? Border.all(color: const Color(0xFFF0C9AA)) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(guide ? 4 : 16),
            bottomRight: Radius.circular(guide ? 16 : 4),
          ),
        ),
        child: Text(message.text,
            style: TextStyle(
                color: guide ? AppColors.darkGrey : AppColors.white,
                height: 1.4)),
      ),
    );
  }
}
