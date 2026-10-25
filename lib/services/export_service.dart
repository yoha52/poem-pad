import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../models/poem.dart';

class ExportService {
  static Future<void> copyToClipboard(Poem poem) async {
    final text = '${poem.title.isEmpty ? "ያለ ርዕስ" : poem.title}\n\n${poem.content}';
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<bool> exportTxt(Poem poem) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'ግጥም አስቀምጥ (TXT)',
      fileName: '${poem.title.isEmpty ? "poem" : poem.title}.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (path == null) return false;

    final file = File(path);
    final content = '${poem.title}\n\n${poem.content}';
    await file.writeAsString(content, encoding: utf8);
    return true;
  }

  static Future<bool> exportPdf(Poem poem) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'ግጥም አስቀምጥ (PDF)',
      fileName: '${poem.title.isEmpty ? "poem" : poem.title}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (path == null) return false;

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
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Text(poem.content, style: const pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return true;
  }

  static Future<bool> exportBackup(String backupJson) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'ባክአፕ ፋይል አስቀምጥ (JSON)',
      fileName: 'poem_pad_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (path == null) return false;

    final file = File(path);
    await file.writeAsString(backupJson, encoding: utf8);
    return true;
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
