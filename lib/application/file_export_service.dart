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
  Future<File> _write(String path, String content) async =>
      File(path).writeAsString(content);
}
