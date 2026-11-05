import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/reminders/service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PetCareCardApp(),
    ),
  );

  // Set up reminders after the first frame so a slow or failing plugin
  // can't block app start.
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
}

class PetCareCardApp extends ConsumerWidget {
  const PetCareCardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pet Care Card',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
