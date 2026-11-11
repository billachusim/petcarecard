import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/providers.dart';
import '../../care_card/presentation/care_card_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../premium/presentation/premium_providers.dart';
import '../data/apply_parsed_details.dart';
import '../data/parsed_care_details.dart';
import '../data/voice_fill_service.dart';
import '../data/voice_usage_repository.dart';

final voiceUsageRepositoryProvider = Provider<VoiceUsageRepository>((ref) {
  return VoiceUsageRepository(ref.watch(databaseServiceProvider));
});

final voiceFillServiceProvider = Provider<VoiceFillService>((ref) => VoiceFillService());

enum _Stage { record, working, review }

const _promptHint =
    'Try: "This is Milo, a four-year-old beagle. He eats one cup of dry food at '
    '7am and 6pm, walks twice a day, takes half a tablet of Apoquel each morning, '
    'and our vet is Green Lane Clinic on 555 0134."';

const _labels = {
  'pet': {
    'name': 'Name',
    'species': 'Species',
    'breed': 'Breed',
    'sex': 'Sex',
    'approximateAge': 'Age',
    'weight': 'Weight',
    'personality': 'Personality',
    'thingsToKnow': 'Things to know',
  },
  'feeding': {
    'foodName': 'Food',
    'amount': 'Amount',
    'times': 'Times',
    'mealsPerDay': 'Meals per day',
    'treats': 'Treats',
    'foodsToAvoid': 'Foods to avoid',
    'notes': 'Feeding notes',
  },
  'routine': {
    'walkSchedule': 'Walks',
    'playtime': 'Playtime',
    'sleepRoutine': 'Sleep',
    'bathroomRoutine': 'Bathroom',
    'crateInstructions': 'Crate',
    'indoorOutdoorNotes': 'Indoor / outdoor',
    'other': 'Other routine notes',
  },
  'emergency': {
    'primaryName': 'Emergency contact',
    'primaryPhone': 'Emergency phone',
    'secondaryName': 'Backup contact',
    'secondaryPhone': 'Backup phone',
    'specialInstructions': 'Special instructions',
  },
  'veterinarian': {
    'vetName': 'Vet',
    'clinicName': 'Clinic',
    'phone': 'Vet phone',
    'address': 'Clinic address',
  },
};

const _sectionTitles = {
  'pet': 'ABOUT',
  'feeding': 'FEEDING',
  'routine': 'ROUTINE',
  'emergency': 'EMERGENCY',
  'veterinarian': 'VET',
};

/// Speak about your pet and the app fills in the care card.
///
/// Speech is turned into text on the phone. The text (never audio) goes to
/// the Pet Care Cards server, which runs the same AI parser as the website.
/// The user reviews and edits everything before it's saved.
class VoiceFillScreen extends ConsumerStatefulWidget {
  /// Set to add details to an existing pet; null creates a new pet.
  final String? petId;

  const VoiceFillScreen({super.key, this.petId});

  @override
  ConsumerState<VoiceFillScreen> createState() => _VoiceFillScreenState();
}

class _VoiceFillScreenState extends ConsumerState<VoiceFillScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _transcript = TextEditingController();

  _Stage _stage = _Stage.record;
  bool _speechReady = false;
  bool _speechChecked = false;
  bool _listening = false;
  bool _wantListening = false;
  bool _saving = false;
  String _committed = '';
  int? _freeLeft;
  Pet? _existingPet;
  bool _usedOfflineParser = false;

  ParsedCareDetails _details = ParsedCareDetails.empty();
  final Map<String, TextEditingController> _controllers = {};

  bool get _isNewPet => widget.petId == null;

  @override
  void initState() {
    super.initState();
    _transcript.addListener(_onTranscriptChanged);
    _loadAllowance();
    if (!_isNewPet) _loadPet();
  }

  @override
  void dispose() {
    _wantListening = false;
    _speech.cancel();
    _transcript.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTranscriptChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAllowance() async {
    final left = await ref.read(voiceUsageRepositoryProvider).left();
    if (mounted) setState(() => _freeLeft = left);
  }

  Future<void> _loadPet() async {
    final pet = await ref.read(petRepositoryProvider).getPetById(widget.petId!);
    if (mounted) setState(() => _existingPet = pet);
  }

  // ---------------------------------------------------------------- speech

  Future<bool> _ensureSpeech() async {
    if (_speechChecked) return _speechReady;
    try {
      _speechReady = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
    } catch (_) {
      _speechReady = false;
    }
    _speechChecked = true;
    return _speechReady;
  }

  Future<void> _startListening() async {
    if (!await _ensureSpeech()) {
      _toast("Voice input isn't available on this phone, or microphone access is off. "
          'You can type the details in the box instead.');
      return;
    }
    _committed = _transcript.text.trim();
    _wantListening = true;
    await _listen();
  }

  Future<void> _listen() async {
    if (!_wantListening || !mounted) return;
    setState(() => _listening = true);
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(minutes: 3),
          pauseFor: const Duration(seconds: 8),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (_) {
      _wantListening = false;
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _stopListening() async {
    _wantListening = false;
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    final text = [_committed, words].where((s) => s.isNotEmpty).join(' ');
    if (result.finalResult) _committed = text;
    if (!mounted) return;
    setState(() {
      _transcript.text = text;
      _transcript.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _onSpeechStatus(String status) {
    // Phones stop listening after a pause. Keep going until the user taps
    // stop, so they can describe their pet at their own pace.
    if ((status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) &&
        _wantListening &&
        !_speech.isListening) {
      Future.delayed(const Duration(milliseconds: 250), _listen);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    const benign = {'error_no_match', 'error_speech_timeout'};
    if (benign.contains(error.errorMsg)) return; // silence: restart via status
    if (error.permanent) {
      _wantListening = false;
      if (mounted) setState(() => _listening = false);
      if (error.errorMsg.contains('permission')) {
        _toast('Microphone access is off. Turn it on in Settings, or type the details instead.');
      }
    }
  }

  // ---------------------------------------------------------------- parse

  Future<void> _fillIn() async {
    if (_listening) await _stopListening();
    final text = _transcript.text.trim();
    if (text.length < 8) {
      _toast("We didn't hear enough. Try again, or type the details instead.");
      return;
    }
    setState(() => _stage = _Stage.working);
    try {
      final result = await ref.read(voiceFillServiceProvider).parse(text);
      if (!mounted) return;
      if (result.details.isEmpty) {
        _toast("We couldn't pick out any details. Try mentioning your pet's name, food or routine.");
        setState(() => _stage = _Stage.record);
        return;
      }
      _setDetails(result.details);
      setState(() {
        _usedOfflineParser = result.usedOfflineParser;
        _stage = _Stage.review;
      });
    } on VoiceFillException catch (e) {
      _toast(e.message);
      if (mounted) setState(() => _stage = _Stage.record);
    } catch (_) {
      _toast('Something went wrong. Please try again, or type the details instead.');
      if (mounted) setState(() => _stage = _Stage.record);
    }
  }

  void _setDetails(ParsedCareDetails details) {
    // Old controllers may still be attached this frame; dispose them after.
    final old = _controllers.values.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in old) {
        c.dispose();
      }
    });
    _controllers.clear();
    _details = details;
    final groups = _groups(details);
    for (final entry in groups.entries) {
      for (final key in entry.value.values.keys) {
        _controllers['${entry.key}.$key'] =
            TextEditingController(text: entry.value[key] ?? '');
      }
    }
    for (var i = 0; i < details.medications.length; i++) {
      final med = details.medications[i];
      _controllers['med$i.name'] = TextEditingController(text: med.name);
      _controllers['med$i.dosage'] = TextEditingController(text: med.dosage ?? '');
      _controllers['med$i.time'] = TextEditingController(text: med.time ?? '');
      _controllers['med$i.frequency'] = TextEditingController(text: med.frequency ?? '');
    }
  }

  Map<String, FieldGroup> _groups(ParsedCareDetails d) => {
        'pet': d.pet,
        'feeding': d.feeding,
        'routine': d.routine,
        'emergency': d.emergency,
        'veterinarian': d.veterinarian,
      };

  /// Copies the user's edits back into [_details].
  void _collectEdits() {
    for (final entry in _groups(_details).entries) {
      for (final key in entry.value.values.keys.toList()) {
        if (key == 'species' || key == 'sex') continue; // dropdowns
        final controller = _controllers['${entry.key}.$key'];
        if (controller != null) entry.value[key] = controller.text;
      }
    }
    for (var i = 0; i < _details.medications.length; i++) {
      final med = _details.medications[i];
      med.name = _controllers['med$i.name']?.text.trim() ?? med.name;
      med.dosage = cleanString(_controllers['med$i.dosage']?.text);
      med.time = cleanString(_controllers['med$i.time']?.text);
      med.frequency = cleanString(_controllers['med$i.frequency']?.text);
    }
  }

  // ---------------------------------------------------------------- save

  Future<void> _save() async {
    _collectEdits();
    if (_isNewPet && _details.pet['name'] == null) {
      _toast("Add your pet's name first.");
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = ref.read(petRepositoryProvider);
      final petId = await applyParsedDetails(repository, _details, existing: _existingPet);
      final isPremium = ref.read(premiumNotifierProvider).isPremium;
      if (!isPremium) await ref.read(voiceUsageRepositoryProvider).recordFill();

      ref.invalidate(petDetailsProvider(petId));
      await ref.read(petsListProvider.notifier).loadPets();
      if (!mounted) return;
      if (_isNewPet) {
        context.pushReplacement('/care-card/$petId');
      } else {
        context.pop();
      }
      _toast(_isNewPet ? 'Care card created.' : 'Care card updated.');
    } catch (_) {
      _toast("We couldn't save those details. Please try again.");
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumNotifierProvider).isPremium;
    final outOfFree = !isPremium && _freeLeft == 0;
    final title = _isNewPet
        ? 'Add a pet by voice'
        : 'Add details for ${_existingPet?.name ?? 'your pet'}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.record =>
            outOfFree ? _buildPaywall() : _buildRecord(isPremium),
          _Stage.working => _buildWorking(),
          _Stage.review => _buildReview(),
        },
      ),
    );
  }

  Widget _buildPaywall() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic_rounded, size: 72, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          const Text(
            "You've used your free voice fills",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock Premium for unlimited voice fills, unlimited pets and PDF export. '
            'You can still type the details any time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            child: const Text('Unlock Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecord(bool isPremium) {
    final freeLeft = _freeLeft;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          _isNewPet
              ? 'Tell us about your pet in your own words. We\'ll fill in the care card for you to check.'
              : 'Describe anything new: food, routine, medicines, contacts or vet. We\'ll add it for you to check.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(_promptHint, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        const SizedBox(height: 32),
        Center(
          child: Semantics(
            button: true,
            label: _listening ? 'Stop recording' : 'Start speaking',
            child: GestureDetector(
              onTap: _listening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _listening ? 112 : 96,
                height: _listening ? 112 : 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? Colors.red : AppTheme.primaryColor,
                  boxShadow: [
                    if (_listening)
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                  ],
                ),
                child: Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _listening ? 'Listening… tap to stop' : 'Tap to speak',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _transcript,
          minLines: 4,
          maxLines: 10,
          readOnly: _listening,
          decoration: const InputDecoration(
            labelText: 'What we heard (you can edit or type here)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _transcript.text.trim().isEmpty && !_listening ? null : _fillIn,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Fill in the care card'),
        ),
        const SizedBox(height: 16),
        if (!isPremium && freeLeft != null)
          Text(
            '$freeLeft of ${VoiceUsageRepository.freeVoiceFills} free voice fills left.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        const SizedBox(height: 8),
        Text(
          'Your words are turned into text on your phone. Only the text is sent to '
          'fill in the card, and it isn\'t stored. You check everything before it\'s saved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWorking() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Reading your notes…', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final sections = <Widget>[];
    for (final entry in _groups(_details).entries) {
      final fields = <Widget>[];
      for (final key in entry.value.values.keys) {
        final showAlways = _isNewPet && entry.key == 'pet' && (key == 'name' || key == 'species');
        if (entry.value[key] == null && !showAlways) continue;
        if (!_isNewPet && entry.key == 'pet' && key == 'name') continue;
        fields.add(_buildField(entry.key, key));
      }
      if (entry.key == 'feeding') {
        // Medications sit after feeding, like on the care card.
        sections.add(_section('FEEDING', fields));
        sections.add(_buildMedications());
        continue;
      }
      sections.add(_section(_sectionTitles[entry.key]!, fields));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Check what we picked up. Edit anything that\'s wrong, then save.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              if (_usedOfflineParser) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "We couldn't reach the voice service, so we only picked out the basics. "
                    'Go back and try again when you\'re online for the full card.',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ...sections,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _stage = _Stage.record),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save to care card'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String group, String key) {
    final label = _labels[group]![key]!;
    if (group == 'pet' && (key == 'species' || key == 'sex')) {
      final options = key == 'species' ? voiceSpecies : voiceSexes;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: _details.pet[key],
          decoration: InputDecoration(labelText: label),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (value) => setState(() => _details.pet[key] = value),
        ),
      );
    }
    final isPhone = key.toLowerCase().contains('phone');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers['$group.$key'],
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        minLines: 1,
        maxLines: isPhone ? 1 : 4,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildMedications() {
    final meds = _details.medications;
    if (meds.isEmpty) return const SizedBox.shrink();
    return _section('MEDICATIONS', [
      for (var i = 0; i < meds.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers['med$i.name'],
                      decoration: const InputDecoration(labelText: 'Medicine'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _collectEdits();
                      final details = _details;
                      details.medications.removeAt(i);
                      setState(() => _setDetails(details));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controllers['med$i.dosage'],
                decoration: const InputDecoration(labelText: 'Dose'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers['med$i.time'],
                      decoration: const InputDecoration(labelText: 'Time'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controllers['med$i.frequency'],
                      decoration: const InputDecoration(labelText: 'How often'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ]);
  }
}
