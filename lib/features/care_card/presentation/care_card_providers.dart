import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/care_entities.dart';
import '../../../data/repositories/providers.dart';

class PetDetails {
  final Pet pet;
  final List<FeedingSchedule> feeding;
  final List<CareRoutine> routines;
  final List<Medication> medications;
  final List<EmergencyContact> emergencyContacts;
  final List<Veterinarian> veterinarians;

  PetDetails({
    required this.pet,
    required this.feeding,
    required this.routines,
    required this.medications,
    required this.emergencyContacts,
    required this.veterinarians,
  });
}

final petDetailsProvider = FutureProvider.family<PetDetails, String>((ref, petId) async {
  final repository = ref.watch(petRepositoryProvider);
  
  final pet = await repository.getPetById(petId);
  if (pet == null) throw Exception('Pet not found');

  final feeding = await repository.getFeedingSchedulesForPet(petId);
  final routines = await repository.getCareRoutinesForPet(petId);
  final medications = await repository.getMedicationsForPet(petId);
  final emergencyContacts = await repository.getEmergencyContactsForPet(petId);
  final veterinarians = await repository.getVeterinariansForPet(petId);

  return PetDetails(
    pet: pet,
    feeding: feeding,
    routines: routines,
    medications: medications,
    emergencyContacts: emergencyContacts,
    veterinarians: veterinarians,
  );
});
