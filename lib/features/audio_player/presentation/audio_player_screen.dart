// lib/features/audio_player/presentation/audio_player_screen.dart
// UI11 Audio Storytelling & Mars Pos Indonesia: putar, jeda, lanjut, seek (F04).
// TODO(Belinda): tampilan sesuai wireframe (cover besar, lirik/transkrip jika tersedia).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/audio_service.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../state/audio_player_state.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({super.key, required this.poiId});

  final String poiId;

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  late final AudioService _audio;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioServiceProvider);
  }

  @override
  void dispose() {
    // Hentikan audio saat keluar layar.
    _audio.stop();
    super.dispose();
  }

  Future<void> _play(Poi poi) async {
    try {
      setState(() => _error = null);
      await _audio.play(poi.audio!);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final poiAsync = ref.watch(poiByIdProvider(widget.poiId));
    final status = ref.watch(audioStatusProvider).valueOrNull ?? AudioPlaybackStatus.idle;
    final position = ref.watch(audioPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(audioDurationProvider).valueOrNull ?? Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Storytelling')),
      body: AsyncValueView<Poi?>(
        value: poiAsync,
        data: (poi) {
          if (poi == null) return const Center(child: Text('POI tidak ditemukan'));
          if (!poi.hasAudio) {
            return const Center(child: Text('Audio belum tersedia untuk POI ini.'));
          }
          final maxMs = duration.inMilliseconds.toDouble();
          final posMs = position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
          final playing = status == AudioPlaybackStatus.playing;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (poi.coverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(poi.coverImage!, height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                Text(poi.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                Text(poi.id == 'P05' ? 'Mars Pos Indonesia' : 'Narasi ${poi.id}',
                    style: const TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),
                Slider(
                  value: maxMs <= 0 ? 0 : posMs,
                  max: maxMs <= 0 ? 1 : maxMs,
                  onChanged: maxMs <= 0
                      ? null
                      : (v) => _audio.seek(Duration(milliseconds: v.round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(_fmt(position)), Text(_fmt(duration))],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      tooltip: 'Mundur 10 detik',
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final target = position - const Duration(seconds: 10);
                        _audio.seek(target.isNegative ? Duration.zero : target);
                      },
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.large(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      onPressed: () {
                        if (playing) {
                          _audio.pause();
                        } else if (status == AudioPlaybackStatus.paused &&
                            _audio.currentAsset == poi.audio) {
                          _audio.resume();
                        } else {
                          _play(poi);
                        }
                      },
                      child: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 36,
                      tooltip: 'Stop',
                      icon: const Icon(Icons.stop),
                      onPressed: _audio.stop,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Status: ${status.name}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                const Spacer(),
                const Text(
                  'Audio saat ini adalah placeholder. Rekaman asli menunggu izin museum.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
