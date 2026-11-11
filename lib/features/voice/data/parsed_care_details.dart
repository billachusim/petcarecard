/// Care-card details pulled out of a spoken description.
///
/// Mirrors `ParsedCareDetails` in the Pet Care Cards web app
/// (src/features/voice/voice-types.ts), so the phone and the website share
/// one shape. Every field is optional: null means "not mentioned".
library;

const voiceSpecies = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];
const voiceSexes = ['Male', 'Female', 'Unknown'];

/// A labelled group of text fields (pet, feeding, routine, ...).
///
/// Kept as an ordered map so the review screen can show and edit every
/// field without a hand-written form per section.
class FieldGroup {
  final Map<String, String?> values;

  FieldGroup(Map<String, String?> values) : values = Map.of(values);

  FieldGroup.empty(List<String> keys)
      : values = {for (final key in keys) key: null};

  String? operator [](String key) => values[key];

  void operator []=(String key, String? value) {
    final trimmed = value?.trim();
    values[key] = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  bool get isEmpty => values.values.every((v) => v == null);
  bool get isNotEmpty => !isEmpty;

  static FieldGroup fromJson(Object? json, List<String> keys) {
    final source = json is Map ? json : const {};
    final group = FieldGroup.empty(keys);
    for (final key in keys) {
      group[key] = cleanString(source[key]);
    }
    return group;
  }

  Map<String, String?> toJson() => Map.of(values);
}

class ParsedMedication {
  String name;
  String? dosage;
  String? time;
  String? frequency;
  String? notes;

  ParsedMedication({
    required this.name,
    this.dosage,
    this.time,
    this.frequency,
    this.notes,
  });

  factory ParsedMedication.fromJson(Map json) => ParsedMedication(
        name: cleanString(json['name']) ?? '',
        dosage: cleanString(json['dosage']),
        time: cleanString(json['time']),
        frequency: cleanString(json['frequency']),
        notes: cleanString(json['notes']),
      );

  Map<String, String?> toJson() => {
        'name': name,
        'dosage': dosage,
        'time': time,
        'frequency': frequency,
        'notes': notes,
      };
}

class ParsedCareDetails {
  static const petKeys = [
    'name',
    'species',
    'breed',
    'sex',
    'approximateAge',
    'weight',
    'personality',
    'thingsToKnow',
  ];
  static const feedingKeys = [
    'foodName',
    'amount',
    'times',
    'mealsPerDay',
    'treats',
    'foodsToAvoid',
    'notes',
  ];
  static const routineKeys = [
    'walkSchedule',
    'playtime',
    'sleepRoutine',
    'bathroomRoutine',
    'crateInstructions',
    'indoorOutdoorNotes',
    'other',
  ];
  static const emergencyKeys = [
    'primaryName',
    'primaryPhone',
    'secondaryName',
    'secondaryPhone',
    'specialInstructions',
  ];
  static const veterinarianKeys = ['vetName', 'clinicName', 'phone', 'address'];

  final FieldGroup pet;
  final FieldGroup feeding;
  final FieldGroup routine;
  final List<ParsedMedication> medications;
  final FieldGroup emergency;
  final FieldGroup veterinarian;

  ParsedCareDetails({
    required this.pet,
    required this.feeding,
    required this.routine,
    required this.medications,
    required this.emergency,
    required this.veterinarian,
  });

  factory ParsedCareDetails.empty() => ParsedCareDetails(
        pet: FieldGroup.empty(petKeys),
        feeding: FieldGroup.empty(feedingKeys),
        routine: FieldGroup.empty(routineKeys),
        medications: [],
        emergency: FieldGroup.empty(emergencyKeys),
        veterinarian: FieldGroup.empty(veterinarianKeys),
      );

  /// Reads the JSON the web app's parser returns, tolerating missing or
  /// malformed parts the same way the server's `normalize()` does.
  factory ParsedCareDetails.fromJson(Map json) {
    final details = ParsedCareDetails(
      pet: FieldGroup.fromJson(json['pet'], petKeys),
      feeding: FieldGroup.fromJson(json['feeding'], feedingKeys),
      routine: FieldGroup.fromJson(json['routine'], routineKeys),
      medications: [
        if (json['medications'] is List)
          for (final med in json['medications'] as List)
            if (med is Map) ParsedMedication.fromJson(med),
      ]..removeWhere((med) => med.name.isEmpty),
      emergency: FieldGroup.fromJson(json['emergency'], emergencyKeys),
      veterinarian: FieldGroup.fromJson(json['veterinarian'], veterinarianKeys),
    );
    details.pet['species'] = oneOf(details.pet['species'], voiceSpecies);
    details.pet['sex'] = oneOf(details.pet['sex'], voiceSexes);
    return details;
  }

  Map<String, Object?> toJson() => {
        'pet': pet.toJson(),
        'feeding': feeding.toJson(),
        'routine': routine.toJson(),
        'medications': [for (final med in medications) med.toJson()],
        'emergency': emergency.toJson(),
        'veterinarian': veterinarian.toJson(),
      };

  bool get isEmpty =>
      pet.isEmpty &&
      feeding.isEmpty &&
      routine.isEmpty &&
      medications.isEmpty &&
      emergency.isEmpty &&
      veterinarian.isEmpty;
}

String? cleanString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? oneOf(String? value, List<String> allowed) {
  if (value == null) return null;
  for (final option in allowed) {
    if (option.toLowerCase() == value.toLowerCase()) return option;
  }
  return null;
}
