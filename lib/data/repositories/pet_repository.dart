import 'package:sqflite/sqflite.dart';
import '../models/pet.dart';
import '../models/care_entities.dart';
import '../local/database_service.dart';

class PetRepository {
  final DatabaseService _dbService;

  PetRepository(this._dbService);

  // --- Pet ---

  Future<void> insertPet(Pet pet) async {
    final db = await _dbService.database;
    await db.insert('pets', pet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Pet>> getAllPets() async {
    final db = await _dbService.database;
    final maps = await db.query('pets');
    return maps.map((map) => Pet.fromMap(map)).toList();
  }

  Future<Pet?> getPetById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('pets', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Pet.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updatePet(Pet pet) async {
    final db = await _dbService.database;
    await db.update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<void> deletePet(String id) async {
    final db = await _dbService.database;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Feeding Schedule ---

  Future<void> insertFeedingSchedule(FeedingSchedule schedule) async {
    final db = await _dbService.database;
    await db.insert('feeding_schedules', schedule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FeedingSchedule>> getFeedingSchedulesForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('feeding_schedules', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => FeedingSchedule.fromMap(map)).toList();
  }

  Future<void> deleteFeedingSchedule(String id) async {
    final db = await _dbService.database;
    await db.delete('feeding_schedules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Care Routine ---

  Future<void> insertCareRoutine(CareRoutine routine) async {
    final db = await _dbService.database;
    await db.insert('care_routines', routine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CareRoutine>> getCareRoutinesForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('care_routines', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => CareRoutine.fromMap(map)).toList();
  }

  Future<void> deleteCareRoutine(String id) async {
    final db = await _dbService.database;
    await db.delete('care_routines', where: 'id = ?', whereArgs: [id]);
  }

  // --- Medication ---

  Future<void> insertMedication(Medication medication) async {
    final db = await _dbService.database;
    await db.insert('medications', medication.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Medication>> getMedicationsForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('medications', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  Future<void> deleteMedication(String id) async {
    final db = await _dbService.database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reminder ---

  Future<void> insertReminder(Reminder reminder) async {
    final db = await _dbService.database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Reminder>> getRemindersForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('reminders', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<void> deleteReminder(String id) async {
    final db = await _dbService.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Emergency Contact ---

  Future<void> insertEmergencyContact(EmergencyContact contact) async {
    final db = await _dbService.database;
    await db.insert('emergency_contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EmergencyContact>> getEmergencyContactsForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('emergency_contacts', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => EmergencyContact.fromMap(map)).toList();
  }

  // --- Veterinarian ---

  Future<void> insertVeterinarian(Veterinarian vet) async {
    final db = await _dbService.database;
    await db.insert('veterinarians', vet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Veterinarian>> getVeterinariansForPet(String petId) async {
    final db = await _dbService.database;
    final maps = await db.query('veterinarians', where: 'petId = ?', whereArgs: [petId]);
    return maps.map((map) => Veterinarian.fromMap(map)).toList();
  }
}
