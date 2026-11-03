// lib/features/onboarding/state/onboarding_state.dart
// Menyimpan flag "onboarding sudah dilihat" di shared_preferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/providers.dart';

class OnboardingSeenController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(AppConstants.prefOnboardingSeen) ??
      false;

  Future<void> markSeen() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.prefOnboardingSeen, true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenController, bool>(OnboardingSeenController.new);
