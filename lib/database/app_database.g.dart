// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DownloadedItemsTable extends DownloadedItems
    with TableInfo<$DownloadedItemsTable, DownloadedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta(
    'uploader',
  );
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extMeta = const VerificationMeta('ext');
  @override
  late final GeneratedColumn<String> ext = GeneratedColumn<String>(
    'ext',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    uploader,
    url,
    thumbnail,
    filePath,
    ext,
    duration,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('uploader')) {
      context.handle(
        _uploaderMeta,
        uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta),
      );
    } else if (isInserting) {
      context.missing(_uploaderMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbnailMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('ext')) {
      context.handle(
        _extMeta,
        ext.isAcceptableOrUnknown(data['ext']!, _extMeta),
      );
    } else if (isInserting) {
      context.missing(_extMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      uploader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploader'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      ext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $DownloadedItemsTable createAlias(String alias) {
    return $DownloadedItemsTable(attachedDatabase, alias);
  }
}

class DownloadedItem extends DataClass implements Insertable<DownloadedItem> {
  final int id;
  final String title;
  final String uploader;
  final String url;
  final String thumbnail;
  final String filePath;
  final String ext;
  final int duration;
  final DateTime downloadedAt;
  const DownloadedItem({
    required this.id,
    required this.title,
    required this.uploader,
    required this.url,
    required this.thumbnail,
    required this.filePath,
    required this.ext,
    required this.duration,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['uploader'] = Variable<String>(uploader);
    map['url'] = Variable<String>(url);
    map['thumbnail'] = Variable<String>(thumbnail);
    map['file_path'] = Variable<String>(filePath);
    map['ext'] = Variable<String>(ext);
    map['duration'] = Variable<int>(duration);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  DownloadedItemsCompanion toCompanion(bool nullToAbsent) {
    return DownloadedItemsCompanion(
      id: Value(id),
      title: Value(title),
      uploader: Value(uploader),
      url: Value(url),
      thumbnail: Value(thumbnail),
      filePath: Value(filePath),
      ext: Value(ext),
      duration: Value(duration),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory DownloadedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      uploader: serializer.fromJson<String>(json['uploader']),
      url: serializer.fromJson<String>(json['url']),
      thumbnail: serializer.fromJson<String>(json['thumbnail']),
      filePath: serializer.fromJson<String>(json['filePath']),
      ext: serializer.fromJson<String>(json['ext']),
      duration: serializer.fromJson<int>(json['duration']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'uploader': serializer.toJson<String>(uploader),
      'url': serializer.toJson<String>(url),
      'thumbnail': serializer.toJson<String>(thumbnail),
      'filePath': serializer.toJson<String>(filePath),
      'ext': serializer.toJson<String>(ext),
      'duration': serializer.toJson<int>(duration),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  DownloadedItem copyWith({
    int? id,
    String? title,
    String? uploader,
    String? url,
    String? thumbnail,
    String? filePath,
    String? ext,
    int? duration,
    DateTime? downloadedAt,
  }) => DownloadedItem(
    id: id ?? this.id,
    title: title ?? this.title,
    uploader: uploader ?? this.uploader,
    url: url ?? this.url,
    thumbnail: thumbnail ?? this.thumbnail,
    filePath: filePath ?? this.filePath,
    ext: ext ?? this.ext,
    duration: duration ?? this.duration,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  DownloadedItem copyWithCompanion(DownloadedItemsCompanion data) {
    return DownloadedItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      url: data.url.present ? data.url.value : this.url,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      ext: data.ext.present ? data.ext.value : this.ext,
      duration: data.duration.present ? data.duration.value : this.duration,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('filePath: $filePath, ')
          ..write('ext: $ext, ')
          ..write('duration: $duration, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    uploader,
    url,
    thumbnail,
    filePath,
    ext,
    duration,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.uploader == this.uploader &&
          other.url == this.url &&
          other.thumbnail == this.thumbnail &&
          other.filePath == this.filePath &&
          other.ext == this.ext &&
          other.duration == this.duration &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadedItemsCompanion extends UpdateCompanion<DownloadedItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> uploader;
  final Value<String> url;
  final Value<String> thumbnail;
  final Value<String> filePath;
  final Value<String> ext;
  final Value<int> duration;
  final Value<DateTime> downloadedAt;
  const DownloadedItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.filePath = const Value.absent(),
    this.ext = const Value.absent(),
    this.duration = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  DownloadedItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String uploader,
    required String url,
    required String thumbnail,
    required String filePath,
    required String ext,
    required int duration,
    required DateTime downloadedAt,
  }) : title = Value(title),
       uploader = Value(uploader),
       url = Value(url),
       thumbnail = Value(thumbnail),
       filePath = Value(filePath),
       ext = Value(ext),
       duration = Value(duration),
       downloadedAt = Value(downloadedAt);
  static Insertable<DownloadedItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? uploader,
    Expression<String>? url,
    Expression<String>? thumbnail,
    Expression<String>? filePath,
    Expression<String>? ext,
    Expression<int>? duration,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (uploader != null) 'uploader': uploader,
      if (url != null) 'url': url,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (filePath != null) 'file_path': filePath,
      if (ext != null) 'ext': ext,
      if (duration != null) 'duration': duration,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  DownloadedItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? uploader,
    Value<String>? url,
    Value<String>? thumbnail,
    Value<String>? filePath,
    Value<String>? ext,
    Value<int>? duration,
    Value<DateTime>? downloadedAt,
  }) {
    return DownloadedItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      uploader: uploader ?? this.uploader,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      filePath: filePath ?? this.filePath,
      ext: ext ?? this.ext,
      duration: duration ?? this.duration,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (ext.present) {
      map['ext'] = Variable<String>(ext.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('filePath: $filePath, ')
          ..write('ext: $ext, ')
          ..write('duration: $duration, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadedItemsTable downloadedItems = $DownloadedItemsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloadedItems];
}

typedef $$DownloadedItemsTableCreateCompanionBuilder =
    DownloadedItemsCompanion Function({
      Value<int> id,
      required String title,
      required String uploader,
      required String url,
      required String thumbnail,
      required String filePath,
      required String ext,
      required int duration,
      required DateTime downloadedAt,
    });
typedef $$DownloadedItemsTableUpdateCompanionBuilder =
    DownloadedItemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> uploader,
      Value<String> url,
      Value<String> thumbnail,
      Value<String> filePath,
      Value<String> ext,
      Value<int> duration,
      Value<DateTime> downloadedAt,
    });

class $$DownloadedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ext => $composableBuilder(
    column: $table.ext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ext => $composableBuilder(
    column: $table.ext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get ext =>
      $composableBuilder(column: $table.ext, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedItemsTable,
          DownloadedItem,
          $$DownloadedItemsTableFilterComposer,
          $$DownloadedItemsTableOrderingComposer,
          $$DownloadedItemsTableAnnotationComposer,
          $$DownloadedItemsTableCreateCompanionBuilder,
          $$DownloadedItemsTableUpdateCompanionBuilder,
          (
            DownloadedItem,
            BaseReferences<
              _$AppDatabase,
              $DownloadedItemsTable,
              DownloadedItem
            >,
          ),
          DownloadedItem,
          PrefetchHooks Function()
        > {
  $$DownloadedItemsTableTableManager(
    _$AppDatabase db,
    $DownloadedItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> thumbnail = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> ext = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
              }) => DownloadedItemsCompanion(
                id: id,
                title: title,
                uploader: uploader,
                url: url,
                thumbnail: thumbnail,
                filePath: filePath,
                ext: ext,
                duration: duration,
                downloadedAt: downloadedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String uploader,
                required String url,
                required String thumbnail,
                required String filePath,
                required String ext,
                required int duration,
                required DateTime downloadedAt,
              }) => DownloadedItemsCompanion.insert(
                id: id,
                title: title,
                uploader: uploader,
                url: url,
                thumbnail: thumbnail,
                filePath: filePath,
                ext: ext,
                duration: duration,
                downloadedAt: downloadedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedItemsTable,
      DownloadedItem,
      $$DownloadedItemsTableFilterComposer,
      $$DownloadedItemsTableOrderingComposer,
      $$DownloadedItemsTableAnnotationComposer,
      $$DownloadedItemsTableCreateCompanionBuilder,
      $$DownloadedItemsTableUpdateCompanionBuilder,
      (
        DownloadedItem,
        BaseReferences<_$AppDatabase, $DownloadedItemsTable, DownloadedItem>,
      ),
      DownloadedItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadedItemsTableTableManager get downloadedItems =>
      $$DownloadedItemsTableTableManager(_db, _db.downloadedItems);
}
