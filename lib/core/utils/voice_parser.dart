class ParsedPetInfo {
  final String? name;
  final String? species;
  final String? breed;
  final String? personality;

  ParsedPetInfo({this.name, this.species, this.breed, this.personality});

  @override
  String toString() => 'Name: $name, Species: $species, Breed: $breed, Personality: $personality';
}

class VoiceParser {
  static ParsedPetInfo parse(String text) {
    final lowerText = text.toLowerCase();
    
    String? name;
    String? species;
    String? breed;
    String? personality;

    // Extract Species
    if (lowerText.contains('dog')) {
      species = 'Dog';
    } else if (lowerText.contains('cat')) {
      species = 'Cat';
    } else if (lowerText.contains('bird')) {
      species = 'Bird';
    } else if (lowerText.contains('rabbit')) {
      species = 'Rabbit';
    }

    // Extract Name (looking for "name is X", "named X", "called X")
    final nameRegex = RegExp(r'\b(?:name is|named|called)\s+([a-zA-Z]+)\b');
    final nameMatch = nameRegex.firstMatch(lowerText);
    if (nameMatch != null) {
      name = _capitalize(nameMatch.group(1)!);
    }

    // Extract Breed (simplified: look for "a [breed] [species]")
    if (species != null) {
      final breedRegex = RegExp('a\\s+(.+?)\\s+${species.toLowerCase()}\\b');
      final breedMatch = breedRegex.firstMatch(lowerText);
      if (breedMatch != null) {
        breed = _capitalize(breedMatch.group(1)!);
      }
    }

    // Extract Personality (looking for "is [personality]")
    final personalityRegex = RegExp(r'\b(?:is|seems|very)\s+([a-zA-Z\s]+?)(?:\.|$|\band\b)');
    final matches = personalityRegex.allMatches(lowerText);
    if (matches.isNotEmpty) {
      // Pick the last one if there are multiple (e.g. "is a cat and is majestic")
      personality = matches.last.group(1)!.trim();
      // Clean up common fillers
      personality = personality.replaceFirst(RegExp(r'\b(a|very|extremely|super)\b\s*'), '').trim();
    }

    return ParsedPetInfo(
      name: name,
      species: species,
      breed: breed,
      personality: personality,
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
