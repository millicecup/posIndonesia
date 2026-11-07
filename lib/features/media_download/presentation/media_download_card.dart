// lib/features/media_download/presentation/media_download_card.dart
// Kartu "Unduh konten museum". Hilang sendiri jika semua file sudah tersedia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../state/media_download_controller.dart';

class MediaDownloadCard extends ConsumerWidget {
  const MediaDownloadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaDownloadProvider).valueOrNull;
    if (state == null || (state.missing == 0 && !state.isRunning)) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unduh konten museum',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (state.isRunning) ...[
              Text('Mengunduh ${state.done}/${state.total} file…'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.progress,
                color: AppColors.orange,
                backgroundColor: AppColors.lightGrey,
              ),
            ] else ...[
              Text(state.failed > 0
                  ? '${state.failed} file gagal diunduh. Periksa koneksi internet, lalu coba lagi.'
                  : 'Foto dan audio narasi (${state.missing} file) tersimpan di HP '
                      'agar bisa dipakai tanpa internet. Sebaiknya pakai Wi-Fi.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => ref.read(mediaDownloadProvider.notifier).start(),
                icon: const Icon(Icons.download),
                label: Text(state.failed > 0 ? 'Coba lagi' : 'Unduh semua konten'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
