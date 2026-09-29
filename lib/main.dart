import 'dart:io';

import 'package:flutter/material.dart';

import 'application/library/scenario_library_service.dart';
import 'infrastructure/database/sqlite/sqlite_scenario_repository.dart';
import 'presentation/app.dart';
import 'presentation/pages/library_page.dart';

export 'presentation/app.dart';
export 'presentation/widgets/shell.dart';
export 'presentation/pages/home_page.dart';
export 'presentation/pages/composer_page.dart';
export 'presentation/pages/transformer_page.dart';
export 'presentation/pages/library_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap SQLite scenario repository factory for LibraryPage
  LibraryPage.defaultServiceFactory = () async {
    final path = '${Directory.systemTemp.path}/zhuangma_library.db';
    final repo = await SqliteScenarioRepository.open(path);
    return ScenarioLibraryService(repo);
  };

  runApp(const ZhuangMaApp());
}
