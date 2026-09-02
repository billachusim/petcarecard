import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database_service.dart';
import 'pet_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PetRepository(dbService);
});
