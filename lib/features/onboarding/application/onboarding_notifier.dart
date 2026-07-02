import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  const OnboardingState({this.currentIndex = 0});
  final int currentIndex;

  OnboardingState copyWith({int? currentIndex}) =>
      OnboardingState(currentIndex: currentIndex ?? this.currentIndex);
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void nextSlide(int totalSlides) {
    if (state.currentIndex < totalSlides - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void goToSlide(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);