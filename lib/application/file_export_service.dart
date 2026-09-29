import 'dart:io';

import 'export_service.dart';
import '../main.dart';

class FileExportService {
  final ExportService exporter;
  const FileExportService({this.exporter = const ExportService()});

  Future<File> writeText(AttackScenario scenario, String path) =>
      _write(path, exporter.text(scenario));

  Future<File> writeJson(AttackScenario scenario, String path) =>
      _write(path, exporter.json(scenario));

  Future<File> writeMarkdown(AttackScenario scenario, String path) =>
      _write(path, exporter.markdown(scenario));

  Future<File> writeTestCaseJson(AdversarialTestCase testCase, String path) =>
      _write(path, exporter.testCaseJson(testCase));

  static String sanitizeFilename(String name, {String fallback = 'export'}) {
    final trimmed = name.trim();
    final safe = trimmed
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\.{2,}'), '_');
    return safe.isEmpty ? fallback : safe;
  }

  Future<File> _write(String path, String content) async {
    if (path.trim().isEmpty) {
      throw const FileSystemException('Export path is empty');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    return file.writeAsString(content);
  }
}
