// lib/features/onboarding/presentation/onboarding_screen.dart
// UI01 Welcome / Onboarding: 3 slide Explore, Discover, Collect (PRD 1.3, Gambar 5.1 kiri).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/postman_guide.dart';
import '../state/onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      'Explore',
      Icons.map_outlined,
      'Jelajahi denah museum. Saat kamu mendekati koleksi, informasinya muncul otomatis.'
    ),
    (
      'Discover',
      Icons.headphones_outlined,
      'Pahami sejarah lewat ringkasan, fakta penting, gambar, narasi audio, dan pemandu virtual.'
    ),
    (
      'Collect',
      Icons.local_post_office_outlined,
      'Kumpulkan perangko digital, berfoto dengan seragam petugas pos, dan dapatkan cap kunjunganmu.'
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(AppRoutes.permission);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _welcome(context),
                    for (final s in _slides) _slide(context, s.$1, s.$2, s.$3),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.darkGrey : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGrey),
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(last ? 'Mulai Menjelajah' : 'Lanjut'),
              ),
              TextButton(onPressed: _finish, child: const Text('Lewati pengantar')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(AppConstants.onboardingImage, width: 96),
          ),
          const SizedBox(height: 16),
          Text('Jejak Pos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.darkGrey, fontWeight: FontWeight.bold)),
          const Text('Museum Pos Indonesia', style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 8),
          const Chip(label: Text(AppConstants.tagline)),
          const SizedBox(height: 24),
          const PostmanGuide(size: 150),
        ],
      );

  Widget _slide(BuildContext context, String title, IconData icon, String text) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.orangeLight,
            child: Icon(icon, size: 64, color: AppColors.orange),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ],
      );
}
