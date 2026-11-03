// lib/features/onboarding/presentation/onboarding_screen.dart
// UI01 Onboarding. TODO(Farella): slide 3 halaman Explore/Discover/Collect sesuai wireframe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../state/onboarding_state.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(AppConstants.onboardingImage, width: 220),
              ),
              const SizedBox(height: 24),
              Text(AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(AppConstants.tagline, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text(
                'Jelajahi Museum POS Indonesia: temukan koleksi di sekitarmu, '
                'dengarkan ceritanya, dan kumpulkan perangko digital.',
                textAlign: TextAlign.center,
              ),
              // TODO(Farella): ganti dengan PageView 3 slide (Explore, Discover, Collect).
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(onboardingSeenProvider.notifier).markSeen();
                  if (context.mounted) context.go(AppRoutes.permission);
                },
                child: const Text('Mulai Menjelajah'),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(onboardingSeenProvider.notifier).markSeen();
                  if (context.mounted) context.go(AppRoutes.permission);
                },
                child: const Text('Lewati pengantar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
