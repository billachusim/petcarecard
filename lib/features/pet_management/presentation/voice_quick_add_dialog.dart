import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../../core/utils/voice_parser.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/providers.dart';
import '../../home/presentation/home_providers.dart';

class VoiceQuickAddDialog extends ConsumerStatefulWidget {
  const VoiceQuickAddDialog({super.key});

  @override
  ConsumerState<VoiceQuickAddDialog> createState() => _VoiceQuickAddDialogState();
}

class _VoiceQuickAddDialogState extends ConsumerState<VoiceQuickAddDialog> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking...';
  ParsedPetInfo? _parsedInfo;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _parsedInfo = VoiceParser.parse(_text);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _savePet() async {
    if (_parsedInfo == null || _parsedInfo!.name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect pet name. Please try again.')),
      );
      return;
    }

    final repository = ref.read(petRepositoryProvider);
    final pet = Pet(
      id: const Uuid().v4(),
      name: _parsedInfo!.name!,
      species: _parsedInfo!.species ?? 'Dog',
      breed: _parsedInfo!.breed,
      personality: _parsedInfo!.personality,
    );

    await repository.insertPet(pet);
    await ref.read(petsListProvider.notifier).loadPets();
    
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice Quick Add'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _text,
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.black : Colors.grey.shade600,
                fontStyle: _isListening ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_parsedInfo != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow('Name', _parsedInfo!.name),
            _buildInfoRow('Species', _parsedInfo!.species),
            _buildInfoRow('Breed', _parsedInfo!.breed),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            onPressed: _listen,
            backgroundColor: _isListening ? Colors.red : AppTheme.primaryColor,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _parsedInfo?.name != null ? _savePet : null,
          child: const Text('Save Pet'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'Detecting...', style: TextStyle(color: value == null ? Colors.grey : Colors.black)),
        ],
      ),
    );
  }
}
