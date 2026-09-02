import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              'One payment. No subscription. Ever.',
              style: TextStyle(fontSize: 18, color: AppTheme.secondaryColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 48),
            _buildFeatureRow(Icons.pets, 'Unlimited pets'),
            _buildFeatureRow(Icons.picture_as_pdf, 'Printable PDF Care Cards'),
            _buildFeatureRow(Icons.notifications_active, 'Smart care reminders'),
            _buildFeatureRow(Icons.qr_code_2, 'Advanced QR codes'),
            _buildFeatureRow(Icons.backup, 'Export & Backup data'),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () {
                // IAP Logic here
              },
              child: const Text('Unlock Lifetime — \$4.99'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {},
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
      padding: const EdgeInsets.only(bottom: 24),
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
