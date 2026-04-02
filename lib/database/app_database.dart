import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class DownloadedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get uploader => text()();
  TextColumn get url => text()();
  TextColumn get thumbnail => text()();
  TextColumn get filePath => text()();
  TextColumn get ext => text()();
  IntColumn get duration => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
}

@DriftDatabase(tables: [DownloadedItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<DownloadedItem>> watchAllDownloads() =>
      (select(downloadedItems)..orderBy([(t) => OrderingTerm.desc(t.downloadedAt)])).watch();

  Future<int> insertDownload(DownloadedItemsCompanion entry) =>
      into(downloadedItems).insert(entry);

  Future<int> deleteDownload(int id) =>
      (delete(downloadedItems)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'kite.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
