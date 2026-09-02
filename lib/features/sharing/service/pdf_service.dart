import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/care_card/presentation/care_card_providers.dart';

class PdfService {
  static Future<void> generateAndPrint(PetDetails details) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('PET CARE CARD: ${details.pet.name.toUpperCase()}'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Species: ${details.pet.species}'),
              pw.Text('Breed: ${details.pet.breed ?? "N/A"}'),
              pw.SizedBox(height: 20),
              pw.Text('Personality: ${details.pet.personality ?? "Friendly"}'),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Feeding')),
              ...details.feeding.map((f) => pw.Bullet(text: '${f.name}: ${f.time} - ${f.amount}')),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Routine')),
              ...details.routines.map((r) => pw.Bullet(text: '${r.title}: ${r.instructions}')),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Emergency')),
              ...details.emergencyContacts.map((c) => pw.Bullet(text: '${c.name}: ${c.phone}')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
