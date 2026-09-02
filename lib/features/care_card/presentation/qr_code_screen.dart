import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';

class QrCodeScreen extends StatelessWidget {
  final String petId;
  final String petName;

  const QrCodeScreen({super.key, required this.petId, required this.petName});

  @override
  Widget build(BuildContext context) {
    // For MVP, we encode a conceptual URL or ID.
    // Future: petcarecard://care/petId
    final String qrData = 'petcarecard://care/$petId';

    return Scaffold(
      appBar: AppBar(title: Text('$petName\'s QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.textColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Scan to view $petName\'s Care Card',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A caregiver can scan this to quickly\naccess care instructions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.share_outlined, 'Share QR', () {}),
                const SizedBox(width: 48),
                _buildActionButton(Icons.save_alt_outlined, 'Save Image', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
