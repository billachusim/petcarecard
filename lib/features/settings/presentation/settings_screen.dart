import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('ACCOUNT'),
          ListTile(
            leading: const Icon(Icons.star_outline, color: AppTheme.primaryColor),
            title: const Text('Unlock Premium'),
            subtitle: const Text('Unlimited pets, PDF export, and more'),
            onTap: () => context.push('/premium'),
          ),
          const Divider(),
          _buildSectionHeader('DATA'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteDialog(context, ref),
          ),
          const Divider(),
          _buildSectionHeader('ABOUT'),
          const ListTile(
            title: Text('App Version'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all your pets and care cards. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Simple wipe logic for MVP
              final repository = ref.read(petRepositoryProvider);
              final pets = await repository.getAllPets();
              for (var pet in pets) {
                await repository.deletePet(pet.id);
              }
              ref.read(petsListProvider.notifier).loadPets();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/home');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
