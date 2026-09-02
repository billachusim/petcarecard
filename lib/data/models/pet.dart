import 'dart:convert';

class Pet {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final double? weight;
  final String? photoPath;
  final String? personality;
  final String? importantNotes;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.weight,
    this.photoPath,
    this.personality,
    this.importantNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'birthDate': birthDate?.toIso8601String(),
      'weight': weight,
      'photoPath': photoPath,
      'personality': personality,
      'importantNotes': importantNotes,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      sex: map['sex'],
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      weight: map['weight']?.toDouble(),
      photoPath: map['photoPath'],
      personality: map['personality'],
      importantNotes: map['importantNotes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Pet.fromJson(String source) => Pet.fromMap(json.decode(source));
}
