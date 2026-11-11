import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care_card/data/local/database_service.dart';
import 'package:pet_care_card/data/models/care_entities.dart';
import 'package:pet_care_card/data/models/pet.dart';
import 'package:pet_care_card/data/repositories/pet_repository.dart';
import 'package:pet_care_card/features/voice/data/apply_parsed_details.dart';
import 'package:pet_care_card/features/voice/data/parsed_care_details.dart';
import 'package:pet_care_card/features/voice/data/voice_fill_service.dart';

/// In-memory stand-in for the sqflite repository.
class FakeRepository extends PetRepository {
  FakeRepository() : super(DatabaseService.instance);

  final pets = <String, Pet>{};
  final feeding = <FeedingSchedule>[];
  final routines = <CareRoutine>[];
  final meds = <Medication>[];
  final contacts = <EmergencyContact>[];
  final vets = <Veterinarian>[];

  @override
  Future<void> insertPet(Pet pet) async => pets[pet.id] = pet;
  @override
  Future<void> updatePet(Pet pet) async => pets[pet.id] = pet;
  @override
  Future<void> insertFeedingSchedule(FeedingSchedule s) async => feeding.add(s);
  @override
  Future<void> insertCareRoutine(CareRoutine r) async => routines.add(r);
  @override
  Future<void> insertMedication(Medication m) async => meds.add(m);
  @override
  Future<void> insertEmergencyContact(EmergencyContact c) async => contacts.add(c);
  @override
  Future<void> insertVeterinarian(Veterinarian v) async => vets.add(v);
}

// The shape the web app's /api/public/voice/parse returns.
final serverReply = {
  'pet': {
    'name': 'Milo',
    'species': 'Dog',
    'breed': 'Beagle',
    'sex': 'Male',
    'approximateAge': '4 years',
    'weight': '12 kg',
    'personality': 'Friendly, loves squeaky toys',
    'thingsToKnow': null,
  },
  'feeding': {
    'foodName': 'Dry kibble',
    'amount': 'One cup',
    'times': '7am and 6pm',
    'mealsPerDay': null,
    'treats': null,
    'foodsToAvoid': 'Grapes',
    'notes': null,
  },
  'routine': {
    'walkSchedule': 'Twice a day',
    'playtime': null,
    'sleepRoutine': '  ',
    'bathroomRoutine': null,
    'crateInstructions': null,
    'indoorOutdoorNotes': null,
    'other': null,
  },
  'medications': [
    {'name': 'Apoquel', 'dosage': 'Half a tablet', 'time': 'Morning', 'frequency': 'Daily', 'notes': null},
    {'name': '', 'dosage': 'ignored'},
  ],
  'emergency': {
    'primaryName': 'Jane',
    'primaryPhone': '555 0100',
    'secondaryName': null,
    'secondaryPhone': null,
    'specialInstructions': null,
  },
  'veterinarian': {
    'vetName': null,
    'clinicName': 'Green Lane Clinic',
    'phone': '555 0134',
    'address': null,
  },
};

void main() {
  group('ParsedCareDetails.fromJson', () {
    test('reads the server reply and drops blanks', () {
      final d = ParsedCareDetails.fromJson(serverReply);
      expect(d.pet['name'], 'Milo');
      expect(d.routine['sleepRoutine'], isNull);
      expect(d.medications, hasLength(1));
      expect(d.medications.first.dosage, 'Half a tablet');
      expect(d.isEmpty, isFalse);
    });

    test('rejects unknown species and sex, tolerates junk', () {
      final d = ParsedCareDetails.fromJson({
        'pet': {'species': 'dragon', 'sex': 'female'},
        'medications': 'nope',
        'feeding': 42,
      });
      expect(d.pet['species'], isNull);
      expect(d.pet['sex'], 'Female');
      expect(d.medications, isEmpty);
      expect(d.feeding.isEmpty, isTrue);
    });
  });

  group('parseWeight', () {
    test('handles kilos, pounds and plain numbers', () {
      expect(parseWeight('12 kg'), 12);
      expect(parseWeight('about 7.5 kilos'), 7.5);
      expect(parseWeight('22 pounds'), 10.0);
      expect(parseWeight('30'), 30);
      expect(parseWeight('a bit chubby'), isNull);
      expect(parseWeight('10-12 kg'), isNull);
    });
  });

  group('applyParsedDetails', () {
    test('creates a full care card for a new pet', () async {
      final repo = FakeRepository();
      final id = await applyParsedDetails(repo, ParsedCareDetails.fromJson(serverReply));

      final pet = repo.pets[id]!;
      expect(pet.name, 'Milo');
      expect(pet.species, 'Dog');
      expect(pet.sex, 'Male');
      expect(pet.weight, 12);
      expect(pet.importantNotes, contains('Age: 4 years'));
      expect(repo.feeding.single.time, '7am and 6pm');
      expect(repo.feeding.single.instructions, contains('Avoid: Grapes'));
      expect(repo.routines.single.title, 'Walks');
      expect(repo.meds.single.name, 'Apoquel');
      expect(repo.contacts.single.phone, '555 0100');
      expect(repo.vets.single.name, 'Green Lane Clinic');
    });

    test('adds to an existing pet without overwriting its name or saved values', () async {
      final repo = FakeRepository();
      final existing = Pet(
        id: 'p1',
        name: 'Biscuit',
        species: 'Cat',
        breed: 'Tabby',
        importantNotes: 'Shy with strangers',
      );
      repo.pets['p1'] = existing;

      final details = ParsedCareDetails.empty();
      details.pet['name'] = 'Someone else';
      details.pet['personality'] = 'Sleepy';
      details.routine['playtime'] = 'Laser pointer after dinner';

      final id = await applyParsedDetails(repo, details, existing: existing);

      expect(id, 'p1');
      final pet = repo.pets['p1']!;
      expect(pet.name, 'Biscuit');
      expect(pet.species, 'Cat');
      expect(pet.breed, 'Tabby');
      expect(pet.personality, 'Sleepy');
      expect(pet.importantNotes, 'Shy with strangers');
      expect(repo.routines.single.title, 'Playtime');
      expect(repo.feeding, isEmpty);
    });
  });

  test('offline parser fills the basics', () {
    final d = VoiceFillService.offlineParse('My dog is named Max and he is playful');
    expect(d.pet['name'], 'Max');
    expect(d.pet['species'], 'Dog');
  });
}
