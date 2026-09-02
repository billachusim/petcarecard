import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pet_management/presentation/add_pet_screen.dart';
import '../../features/care_card/presentation/care_card_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

import '../../features/care_card/presentation/qr_code_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-pet',
        builder: (context, state) => const AddPetScreen(),
      ),
      GoRoute(
        path: '/care-card/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return CareCardScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/qr/:petId/:petName',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final petName = state.pathParameters['petName']!;
          return QrCodeScreen(petId: petId, petName: petName);
        },
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
