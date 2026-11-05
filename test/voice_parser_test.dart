import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care_card/core/utils/voice_parser.dart';

void main() {
  group('VoiceParser Tests', () {
    test('extracts basic dog info', () {
      final result = VoiceParser.parse('My dog is named Max');
      expect(result.name, 'Max');
      expect(result.species, 'Dog');
    });

    test('extracts breed and personality', () {
      final result = VoiceParser.parse("I have a golden retriever dog named Bella who is very energetic");
      expect(result.name, 'Bella');
      expect(result.species, 'Dog');
      expect(result.breed, 'Golden retriever');
      expect(result.personality, 'energetic');
    });

    test('extracts cat info', () {
      final result = VoiceParser.parse('My cat is called Oliver');
      expect(result.name, 'Oliver');
      expect(result.species, 'Cat');
    });

    test('handles messy input', () {
      final result = VoiceParser.parse('so i have this cat named simba and he is majestic');
      expect(result.name, 'Simba');
      expect(result.species, 'Cat');
      expect(result.personality, 'majestic');
    });
  });
}
