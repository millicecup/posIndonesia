// lib/features/media_download/state/media_download_controller.dart
// State tombol "Unduh konten museum" di UI03.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';

class MediaDownloadState {
  const MediaDownloadState({
    required this.missing,
    this.isRunning = false,
    this.done = 0,
    this.total = 0,
    this.failed = 0,
  });

  /// Jumlah file yang belum tersedia di HP.
  final int missing;
  final bool isRunning;
  final int done;
  final int total;
  final int failed;

  double? get progress => total == 0 ? null : done / total;
}

class MediaDownloadController extends AsyncNotifier<MediaDownloadState> {
  Future<List<String>> _paths() async {
    final pois = await ref.read(poisProvider.future);
    return [for (final poi in pois) ...poi.mediaPaths];
  }

  Future<int> _countMissing(List<String> paths) async {
    final media = ref.read(mediaServiceProvider);
    if (!media.isRemoteEnabled) return 0;
    return (await media.missing(paths)).length;
  }

  @override
  Future<MediaDownloadState> build() async =>
      MediaDownloadState(missing: await _countMissing(await _paths()));

  Future<void> start() async {
    final current = state.valueOrNull;
    if (current == null || current.isRunning) return;
    final paths = await _paths();
    state = AsyncData(MediaDownloadState(
        missing: current.missing, isRunning: true, total: current.missing));

    final result = await ref.read(mediaServiceProvider).downloadAll(
      paths,
      onProgress: (done, total) => state = AsyncData(MediaDownloadState(
          missing: total - done, isRunning: true, done: done, total: total)),
    );

    // Gambar yang tadinya placeholder dimuat ulang dari cache.
    ref.invalidate(mediaSourceProvider);
    state = AsyncData(MediaDownloadState(
      missing: await _countMissing(paths),
      failed: result.failed.length,
    ));
  }
}

final mediaDownloadProvider =
    AsyncNotifierProvider<MediaDownloadController, MediaDownloadState>(
        MediaDownloadController.new);
