import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Leaving your pet with someone?',
      subtitle: 'Create a simple care card with everything they need to know.',
      imagePath: 'assets/petcover.png',
      icon: Icons.pets_rounded,
    ),
    OnboardingData(
      title: 'Everything in one place.',
      subtitle:
          'Feeding, medication, routine, emergency contacts, and vet information.',
      icon: Icons.assignment_rounded,
    ),
    OnboardingData(
      title: 'Share it in seconds.',
      subtitle: 'Share the card, print it, or give the caregiver a QR code.',
      icon: Icons.qr_code_2_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        context.go('/home');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Create My Pet Care Card'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Colors.grey.shade300,
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imagePath;

  OnboardingData({
    required this.title,
    required this.subtitle,
    this.icon,
    this.imagePath,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Scrollable so the page fits short screens instead of overflowing.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (data.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  data.imagePath!,
                  height: 180,
                  width: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      data.icon ?? Icons.pets_rounded,
                      size: 120,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              )
            else if (data.icon != null)
              Icon(data.icon, size: 120, color: AppTheme.primaryColor),
            const SizedBox(height: 48),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
