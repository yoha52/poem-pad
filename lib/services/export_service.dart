import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/poem.dart';

class ExportService {
  static pw.Font? _cachedEthiopicFont;

  static Future<pw.Font> _getEthiopicFont() async {
    if (_cachedEthiopicFont != null) return _cachedEthiopicFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansEthiopic-Regular.ttf');
      _cachedEthiopicFont = pw.Font.ttf(fontData);
      return _cachedEthiopicFont!;
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  static bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static Future<void> copyToClipboard(Poem poem) async {
    final text = '${poem.title.isEmpty ? "ያለ ርዕስ" : poem.title}\n\n${poem.content}';
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<bool> exportTxt(Poem poem) async {
    final fileName = '${poem.title.isEmpty ? "poem" : poem.title}.txt';
    final content = '${poem.title}\n\n${poem.content}';

    if (_isDesktop) {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'ግጥም አስቀምጥ (TXT)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (path == null) return false;
      final file = File(path);
      await file.writeAsString(content, encoding: utf8);
      return true;
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      await Share.shareXFiles([XFile(file.path)], text: poem.title);
      return true;
    }
  }

  static Future<bool> exportPdf(Poem poem) async {
    final fileName = '${poem.title.isEmpty ? "poem" : poem.title}.pdf';

    final font = await _getEthiopicFont();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                poem.title.isEmpty ? "ያለ ርዕስ" : poem.title,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                poem.content,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (_isDesktop) {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'ግጥም አስቀምጥ (PDF)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path == null) return false;
      final file = File(path);
      await file.writeAsBytes(pdfBytes);
      return true;
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: poem.title);
      return true;
    }
  }

  static Future<bool> exportBackup(String backupJson) async {
    const fileName = 'poem_pad_backup.json';

    if (_isDesktop) {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'ባክአፕ ፋይል አስቀምጥ (JSON)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return false;
      final file = File(path);
      await file.writeAsString(backupJson, encoding: utf8);
      return true;
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(backupJson, encoding: utf8);
      await Share.shareXFiles([XFile(file.path)], text: 'Poem Pad Backup');
      return true;
    }
  }

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    return await file.readAsString(encoding: utf8);
  }
}
