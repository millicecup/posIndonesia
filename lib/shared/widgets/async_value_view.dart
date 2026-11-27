// lib/shared/widgets/async_value_view.dart
// Helper tampilan loading/error untuk AsyncValue Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // skipLoadingOnReload: saat provider dihitung ulang (mis. progres berubah
    // setelah ambil prangko) tetap tampilkan data lama, jangan spinner. Tanpa ini
    // seluruh isi layar dibongkar dan tombol/dialog yang terbuka kehilangan context.
    return value.when(
      skipLoadingOnReload: true,
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('Terjadi kesalahan:\n$error', textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
