import 'package:flutter/material.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    this.isLastSlide = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final bool isLastSlide;
}

const List<OnboardingSlide> kOnboardingSlides = [
  OnboardingSlide(
    title: 'Discover Gyms Around You',
    subtitle:
        'Find gyms, yoga centers, sports facilities and fitness studios near your location.',
    icon: Icons.location_on,
    iconBgColor: Color(0xFFFF6B00),
  ),
  OnboardingSlide(
    title: 'Train Anywhere',
    subtitle: 'One app. Multiple gyms. Unlimited flexibility.',
    icon: Icons.auto_awesome,
    iconBgColor: Color(0xFFFFFFFF),
    isLastSlide: true,
  ),
];