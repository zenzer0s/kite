import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final downloadsProvider = StreamProvider<List<DownloadedItem>>((ref) {
  return ref.watch(databaseProvider).watchAllDownloads();
});
