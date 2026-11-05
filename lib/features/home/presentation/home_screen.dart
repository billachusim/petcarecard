import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_providers.dart';
import '../../../core/theme/app_theme.dart';

import '../../premium/presentation/premium_providers.dart';
import '../../pet_management/presentation/voice_quick_add_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _onVoiceAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VoiceQuickAddDialog(),
    );
  }

  void _onAddPetPressed(BuildContext context, WidgetRef ref, int currentPetCount) {
    final isPremium = ref.read(premiumNotifierProvider).isPremium;
    if (!isPremium && currentPetCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free version includes 1 pet. Unlock Premium for unlimited pets!'),
        ),
      );
      context.push('/premium');
    } else {
      context.push('/add-pet');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsListProvider);
    final petCount = petsAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Card'),
        actions: [
          IconButton(
            onPressed: () => _onVoiceAddPressed(context),
            icon: const Icon(Icons.mic_outlined),
            tooltip: 'Voice Quick Add',
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: petsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return EmptyPetsState(
              onAddPet: () => _onAddPetPressed(context, ref, 0),
            );
          }
          return PetsList(pets: pets);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddPetPressed(context, ref, petCount),
        label: const Text('Add Pet'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class EmptyPetsState extends StatelessWidget {
  final VoidCallback onAddPet;
  const EmptyPetsState({super.key, required this.onAddPet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 32),
          Text(
            'Your pet\'s care card starts here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create one for your pet before their next stay with a sitter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: onAddPet,
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
          ),
        ],
      ),
    );
  }
}

class PetsList extends StatelessWidget {
  final List pets; // List<Pet>

  const PetsList({super.key, required this.pets});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => context.push('/care-card/${pet.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: pet.photoPath != null
                        ? ClipOval(child: Image.network(pet.photoPath!, fit: BoxFit.cover, width: 64, height: 64))
                        : const Icon(Icons.pets, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pet.species}${pet.breed != null ? " • ${pet.breed}" : ""}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
