import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DprPdfBuilder {
  static Future<File> buildPdf({
    required String projectName,
    required DateTime date,
    required String title,
    required String workDone,
    required String issues,

    /// ✅ NOW IT ACCEPTS FILES
    required List<File> photos,

    required List<Map<String, dynamic>> workers,
  }) async {
    final doc = pw.Document();
    final dateText = DateFormat("dd MMM yyyy").format(date);

    // ✅ convert site photos files -> pw.ImageProvider list
    final List<pw.MemoryImage> siteImages = [];
    for (final f in photos) {
      try {
        final bytes = await f.readAsBytes();
        siteImages.add(pw.MemoryImage(bytes));
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            "Daily Progress Report",
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          _kv("Project", projectName),
          _kv("Date", dateText),
          if (title.trim().isNotEmpty) _kv("Title", title),

          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Text("Work Done",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(workDone),
          pw.SizedBox(height: 14),

          if (issues.trim().isNotEmpty) ...[
            pw.Text("Issues / Blockers",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(issues),
            pw.SizedBox(height: 14),
          ],

          /// ✅ WORKERS TABLE
          pw.Text("Workers",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          workers.isEmpty
              ? pw.Text("No workers added")
              : pw.Table.fromTextArray(
                  headers: ["Name", "Role", "Daily Price"],
                  data: workers.map((w) {
                    return [
                      (w["name"] ?? "").toString(),
                      (w["role"] ?? "").toString(),
                      (w["dailyPrice"] ?? "").toString(),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                ),

          pw.SizedBox(height: 16),

          /// ✅ SITE IMAGES
          pw.Text("Site Photos",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          if (siteImages.isEmpty)
            pw.Text("No site photos")
          else
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: siteImages.map((img) {
                return pw.Container(
                  width: 160,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 10,
                    verticalRadius: 10,
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();

    // ✅ Clean filename
    final safeName =
        projectName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

    final file = File("${dir.path}/DPR_${safeName}_${dateText}.pdf");
    await file.writeAsBytes(await doc.save());

    return file;
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              "$k:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );
  }
}
