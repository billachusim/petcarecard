import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'care_card_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../sharing/service/pdf_service.dart';
import '../../premium/presentation/premium_providers.dart';

class CareCardScreen extends ConsumerWidget {
  final String petId;
  const CareCardScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(petDetailsProvider(petId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('PET CARE CARD'),
        actions: [
          IconButton(
            tooltip: 'Add details by voice',
            onPressed: () => context.push('/voice-fill/$petId'),
            icon: const Icon(Icons.mic_outlined),
          ),
          IconButton(
            onPressed: () {
              detailsAsync.whenData((details) {
                context.push('/qr/${details.pet.id}/${details.pet.name}');
              });
            },
            icon: const Icon(Icons.qr_code_rounded),
          ),
          IconButton(
            onPressed: () {
              detailsAsync.whenData((details) {
                SharePlus.instance.share(
                  ShareParams(
                    text: "Check out ${details.pet.name}'s care card! Link coming soon.",
                  ),
                );
              });
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (details) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(details),
              const SizedBox(height: 16),
              _buildSection('ABOUT', [
                _buildInfoRow('Personality', details.pet.personality ?? 'Friendly'),
                if (details.pet.importantNotes != null)
                  _buildInfoRow('Important', details.pet.importantNotes!),
              ]),
              const SizedBox(height: 16),
              if (details.feeding.isNotEmpty)
                _buildSection('FEEDING', details.feeding.map((f) => _buildCareItem(f.name, '${f.time} - ${f.amount}', f.instructions)).toList()),
              const SizedBox(height: 16),
              if (details.routines.isNotEmpty)
                _buildSection('ROUTINE', details.routines.map((r) => _buildCareItem(r.title, r.schedule ?? 'Daily', r.instructions)).toList()),
              const SizedBox(height: 16),
              if (details.medications.isNotEmpty) ...[
                _buildSection('MEDICATIONS', details.medications.map((m) => _buildCareItem(m.name, [m.time, m.frequency].where((s) => s != null && s.isNotEmpty).join(' · '), [m.instructions, m.notes].where((s) => s != null && s.isNotEmpty).join('\n').ifEmptyNull)).toList()),
                const SizedBox(height: 16),
              ],
              if (details.veterinarians.isNotEmpty) ...[
                _buildSection('VET', details.veterinarians.map((v) => _buildCareItem(v.name, v.phone ?? '', [v.clinic, v.address].where((s) => s != null && s.isNotEmpty).join('\n').ifEmptyNull)).toList()),
                const SizedBox(height: 16),
              ],
              if (details.emergencyContacts.isNotEmpty)
                _buildSection('EMERGENCY', details.emergencyContacts.map((c) => _buildCareItem(c.name, c.phone, c.relationship)).toList(), color: Colors.red.shade50, titleColor: Colors.red.shade900),

              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, child) {
                  final isPremium = ref.watch(premiumNotifierProvider).isPremium;
                  return ElevatedButton.icon(
                    onPressed: () {
                      if (isPremium) {
                        PdfService.generateAndPrint(details);
                      } else {
                        context.push('/premium');
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      isPremium
                          ? 'Export Care Card PDF'
                          : 'Export to PDF (Premium)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(PetDetails details) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: const Icon(Icons.pets, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.pet.name.toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Text(
                  '${details.pet.species} • ${details.pet.breed ?? "Unknown Breed"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {Color? color, Color? titleColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: titleColor ?? AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String subtitle, String? notes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (notes != null) ...[
            const SizedBox(height: 8),
            Text(notes, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
