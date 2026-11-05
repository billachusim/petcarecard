import 'package:uuid/uuid.dart';
import '../../data/models/pet.dart';
import '../../data/models/care_entities.dart';
import '../../data/repositories/pet_repository.dart';
import '../../features/premium/data/premium_repository.dart';

class DataSeeder {
  static Future<void> seed(PetRepository repository, PremiumRepository premiumRepository) async {
    // Force premium for demo
    await premiumRepository.setPremiumUnlocked(true);

    final pets = await repository.getAllPets();
    if (pets.isNotEmpty) return; // Already seeded or has data

    final uuid = const Uuid();

    // --- Luna (Golden Retriever) ---
    final lunaId = uuid.v4();
    final luna = Pet(
      id: lunaId,
      name: 'Luna',
      species: 'Dog',
      breed: 'Golden Retriever',
      sex: 'Female',
      birthDate: DateTime(2021, 5, 12),
      weight: 28.5,
      photoPath: 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&q=80&w=400',
      personality: 'Super friendly, loves tennis balls, but afraid of vacuum cleaners.',
      importantNotes: 'Needs 30 mins walk twice a day. Very food motivated.',
    );
    await repository.insertPet(luna);

    await repository.insertFeedingSchedule(FeedingSchedule(
      id: uuid.v4(),
      petId: lunaId,
      name: 'Breakfast',
      time: '08:00 AM',
      amount: '2 cups dry food',
      instructions: 'Mix with a little warm water.',
    ));

    await repository.insertFeedingSchedule(FeedingSchedule(
      id: uuid.v4(),
      petId: lunaId,
      name: 'Dinner',
      time: '06:00 PM',
      amount: '2 cups dry food',
    ));

    await repository.insertCareRoutine(CareRoutine(
      id: uuid.v4(),
      petId: lunaId,
      title: 'Morning Walk',
      instructions: 'At least 20 minutes around the park.',
      schedule: 'Daily',
    ));

    await repository.insertMedication(Medication(
      id: uuid.v4(),
      petId: lunaId,
      name: 'Heartworm Pill',
      instructions: 'Give with a piece of cheese.',
      time: 'Morning',
      frequency: 'Once a month (1st of month)',
    ));

    await repository.insertEmergencyContact(EmergencyContact(
      id: uuid.v4(),
      petId: lunaId,
      name: 'Jane Doe',
      phone: '555-0123',
      relationship: 'Neighbor',
    ));

    // --- Oliver (Maine Coon) ---
    final oliverId = uuid.v4();
    final oliver = Pet(
      id: oliverId,
      name: 'Oliver',
      species: 'Cat',
      breed: 'Maine Coon',
      sex: 'Male',
      birthDate: DateTime(2022, 10, 5),
      weight: 7.2,
      photoPath: 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&q=80&w=400',
      personality: 'Majestic but lazy. Vocal in the morning.',
      importantNotes: 'Brush daily to prevent matting.',
    );
    await repository.insertPet(oliver);

    await repository.insertFeedingSchedule(FeedingSchedule(
      id: uuid.v4(),
      petId: oliverId,
      name: 'All Day',
      time: 'Continuous',
      amount: 'Free feed dry food',
    ));

    await repository.insertFeedingSchedule(FeedingSchedule(
      id: uuid.v4(),
      petId: oliverId,
      name: 'Wet Food Treat',
      time: '07:00 PM',
      amount: '1/2 can',
    ));

    await repository.insertCareRoutine(CareRoutine(
      id: uuid.v4(),
      petId: oliverId,
      title: 'Brushing',
      instructions: 'Use the long-hair comb for 5-10 minutes.',
      schedule: 'Daily',
    ));

    await repository.insertVeterinarian(Veterinarian(
      id: uuid.v4(),
      petId: oliverId,
      name: 'Dr. Smith',
      clinic: 'Happy Paws Vet',
      phone: '555-9876',
      address: '123 Main St, Anytown',
    ));
  }
}
