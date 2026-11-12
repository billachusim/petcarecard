import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'premium_providers.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumNotifierProvider);
    final notifier = ref.read(premiumNotifierProvider.notifier);

    ref.listen<PremiumState>(premiumNotifierProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
        notifier.clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        notifier.clearMessages();
      }
    });

    final String priceText =
        premiumState.productDetails?.price ?? '\$4.99';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.star_rounded, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Unlock Lifetime Access',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'One payment. No subscription. Forever.',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            if (premiumState.isPremium) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'You have Lifetime Access!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            // Only list what the unlock actually adds (App Review checks this).
            _buildFeatureRow(Icons.pets, 'Unlimited pets'),
            _buildFeatureRow(Icons.mic, 'Unlimited voice fills'),
            _buildFeatureRow(Icons.picture_as_pdf, 'Printable PDF care cards'),
            const SizedBox(height: 48),
            if (premiumState.isLoading)
              const CircularProgressIndicator()
            else if (premiumState.isPremium)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Unlocked — Enjoy Pet Care Card'),
              )
            else
              ElevatedButton(
                onPressed: () => notifier.buyLifetime(),
                child: Text('Unlock Lifetime — $priceText'),
              ),
            const SizedBox(height: 24),
            if (!premiumState.isPremium && !premiumState.isLoading)
              TextButton(
                onPressed: () => notifier.restorePurchases(),
                child: const Text('Restore Purchase', style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLink('Terms'),
                const SizedBox(width: 24),
                _buildLink('Privacy'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
