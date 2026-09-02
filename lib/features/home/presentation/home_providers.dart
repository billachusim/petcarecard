import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/pet_repository.dart';

final petsListProvider = AsyncNotifierProvider<PetsListNotifier, List<Pet>>(
  () => PetsListNotifier(),
  isAutoDispose: true,
);

class PetsListNotifier extends AsyncNotifier<List<Pet>> {
  PetRepository get _repository => ref.read(petRepositoryProvider);

  @override
  FutureOr<List<Pet>> build() async {
    return _repository.getAllPets();
  }

  Future<void> loadPets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllPets());
  }

  Future<void> deletePet(String id) async {
    await _repository.deletePet(id);
    await loadPets();
  }
}
