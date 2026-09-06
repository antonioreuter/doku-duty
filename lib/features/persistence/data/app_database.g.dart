// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cellMeta = const VerificationMeta('cell');
  @override
  late final GeneratedColumn<int> cell = GeneratedColumn<int>(
    'cell',
    aliasedName,
    false,
    check: () => ComparableExpr(cell).isBetweenValues(0, 80),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _digitMeta = const VerificationMeta('digit');
  @override
  late final GeneratedColumn<int> digit = GeneratedColumn<int>(
    'digit',
    aliasedName,
    false,
    check: () => ComparableExpr(digit).isBetweenValues(1, 9),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NoteKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NoteKind>($NotesTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<NoteOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NoteOrigin>($NotesTable.$converterorigin);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    cell,
    digit,
    kind,
    origin,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('cell')) {
      context.handle(
        _cellMeta,
        cell.isAcceptableOrUnknown(data['cell']!, _cellMeta),
      );
    } else if (isInserting) {
      context.missing(_cellMeta);
    }
    if (data.containsKey('digit')) {
      context.handle(
        _digitMeta,
        digit.isAcceptableOrUnknown(data['digit']!, _digitMeta),
      );
    } else if (isInserting) {
      context.missing(_digitMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId, cell, digit};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      cell: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cell'],
      )!,
      digit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}digit'],
      )!,
      kind: $NotesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      origin: $NotesTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NoteKind, String, String> $converterkind =
      const EnumNameConverter<NoteKind>(NoteKind.values);
  static JsonTypeConverter2<NoteOrigin, String, String> $converterorigin =
      const EnumNameConverter<NoteOrigin>(NoteOrigin.values);
}

class Note extends DataClass implements Insertable<Note> {
  final String puzzleId;

  /// 0-80, reading the grid left to right and top to bottom.
  ///
  final int cell;

  /// The candidate itself, 1-9. This *is* the note's identity, not its
  /// position — the fixed 3x3 slot it occupies is derived from it (D-10).
  final int digit;
  final NoteKind kind;
  final NoteOrigin origin;

  /// Sync metadata. Nothing reads these until `add-cloud-sync`; they exist so
  /// that change is not a migration of live saves.
  ///
  /// Defaulted rather than required so that no caller can insert a row without
  /// a stamp. Updates set it explicitly — see the note repository, where the
  /// stamp and the write are the same statement.
  final DateTime updatedAt;
  final bool pendingUpload;
  const Note({
    required this.puzzleId,
    required this.cell,
    required this.digit,
    required this.kind,
    required this.origin,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['cell'] = Variable<int>(cell);
    map['digit'] = Variable<int>(digit);
    {
      map['kind'] = Variable<String>($NotesTable.$converterkind.toSql(kind));
    }
    {
      map['origin'] = Variable<String>(
        $NotesTable.$converterorigin.toSql(origin),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      puzzleId: Value(puzzleId),
      cell: Value(cell),
      digit: Value(digit),
      kind: Value(kind),
      origin: Value(origin),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      cell: serializer.fromJson<int>(json['cell']),
      digit: serializer.fromJson<int>(json['digit']),
      kind: $NotesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      origin: $NotesTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'cell': serializer.toJson<int>(cell),
      'digit': serializer.toJson<int>(digit),
      'kind': serializer.toJson<String>(
        $NotesTable.$converterkind.toJson(kind),
      ),
      'origin': serializer.toJson<String>(
        $NotesTable.$converterorigin.toJson(origin),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  Note copyWith({
    String? puzzleId,
    int? cell,
    int? digit,
    NoteKind? kind,
    NoteOrigin? origin,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => Note(
    puzzleId: puzzleId ?? this.puzzleId,
    cell: cell ?? this.cell,
    digit: digit ?? this.digit,
    kind: kind ?? this.kind,
    origin: origin ?? this.origin,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      cell: data.cell.present ? data.cell.value : this.cell,
      digit: data.digit.present ? data.digit.value : this.digit,
      kind: data.kind.present ? data.kind.value : this.kind,
      origin: data.origin.present ? data.origin.value : this.origin,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('puzzleId: $puzzleId, ')
          ..write('cell: $cell, ')
          ..write('digit: $digit, ')
          ..write('kind: $kind, ')
          ..write('origin: $origin, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    cell,
    digit,
    kind,
    origin,
    updatedAt,
    pendingUpload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.puzzleId == this.puzzleId &&
          other.cell == this.cell &&
          other.digit == this.digit &&
          other.kind == this.kind &&
          other.origin == this.origin &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> puzzleId;
  final Value<int> cell;
  final Value<int> digit;
  final Value<NoteKind> kind;
  final Value<NoteOrigin> origin;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const NotesCompanion({
    this.puzzleId = const Value.absent(),
    this.cell = const Value.absent(),
    this.digit = const Value.absent(),
    this.kind = const Value.absent(),
    this.origin = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String puzzleId,
    required int cell,
    required int digit,
    required NoteKind kind,
    required NoteOrigin origin,
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       cell = Value(cell),
       digit = Value(digit),
       kind = Value(kind),
       origin = Value(origin);
  static Insertable<Note> custom({
    Expression<String>? puzzleId,
    Expression<int>? cell,
    Expression<int>? digit,
    Expression<String>? kind,
    Expression<String>? origin,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (cell != null) 'cell': cell,
      if (digit != null) 'digit': digit,
      if (kind != null) 'kind': kind,
      if (origin != null) 'origin': origin,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? puzzleId,
    Value<int>? cell,
    Value<int>? digit,
    Value<NoteKind>? kind,
    Value<NoteOrigin>? origin,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      cell: cell ?? this.cell,
      digit: digit ?? this.digit,
      kind: kind ?? this.kind,
      origin: origin ?? this.origin,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (cell.present) {
      map['cell'] = Variable<int>(cell.value);
    }
    if (digit.present) {
      map['digit'] = Variable<int>(digit.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $NotesTable.$converterkind.toSql(kind.value),
      );
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $NotesTable.$converterorigin.toSql(origin.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('cell: $cell, ')
          ..write('digit: $digit, ')
          ..write('kind: $kind, ')
          ..write('origin: $origin, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzleSavesTable extends PuzzleSaves
    with TableInfo<$PuzzleSavesTable, PuzzleSave> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleSavesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placedValuesMeta = const VerificationMeta(
    'placedValues',
  );
  @override
  late final GeneratedColumn<String> placedValues = GeneratedColumn<String>(
    'placed_values',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 81,
      maxTextLength: 81,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deviceOriginMeta = const VerificationMeta(
    'deviceOrigin',
  );
  @override
  late final GeneratedColumn<String> deviceOrigin = GeneratedColumn<String>(
    'device_origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    placedValues,
    elapsedMs,
    isComplete,
    updatedAt,
    pendingUpload,
    deviceOrigin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_saves';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleSave> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('placed_values')) {
      context.handle(
        _placedValuesMeta,
        placedValues.isAcceptableOrUnknown(
          data['placed_values']!,
          _placedValuesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_placedValuesMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    if (data.containsKey('device_origin')) {
      context.handle(
        _deviceOriginMeta,
        deviceOrigin.isAcceptableOrUnknown(
          data['device_origin']!,
          _deviceOriginMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  PuzzleSave map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleSave(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      placedValues: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}placed_values'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
      deviceOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_origin'],
      )!,
    );
  }

  @override
  $PuzzleSavesTable createAlias(String alias) {
    return $PuzzleSavesTable(attachedDatabase, alias);
  }
}

class PuzzleSave extends DataClass implements Insertable<PuzzleSave> {
  final String puzzleId;

  /// 81 characters, one per cell, `.` for empty. Fixed width, so a cell's
  /// index is its offset and the string can never shift.
  ///
  /// Required rather than defaulted. A save without a grid is not a state the
  /// game has, and a Dart constant used as a column default does not survive
  /// into the generated migration steps, which are a separate library.
  final String placedValues;

  /// Milliseconds of play. Stored rather than derived: wall-clock difference
  /// would count the hours the app was closed, and D-06 leaves the timer
  /// display-only precisely so it can be honest.
  final int elapsedMs;
  final bool isComplete;
  final DateTime updatedAt;
  final bool pendingUpload;

  /// Which device this save came from. Unused until `add-cloud-sync`, where
  /// §2a's "show both saves and let the player pick" needs to name them.
  final String deviceOrigin;
  const PuzzleSave({
    required this.puzzleId,
    required this.placedValues,
    required this.elapsedMs,
    required this.isComplete,
    required this.updatedAt,
    required this.pendingUpload,
    required this.deviceOrigin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['placed_values'] = Variable<String>(placedValues);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['is_complete'] = Variable<bool>(isComplete);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    map['device_origin'] = Variable<String>(deviceOrigin);
    return map;
  }

  PuzzleSavesCompanion toCompanion(bool nullToAbsent) {
    return PuzzleSavesCompanion(
      puzzleId: Value(puzzleId),
      placedValues: Value(placedValues),
      elapsedMs: Value(elapsedMs),
      isComplete: Value(isComplete),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
      deviceOrigin: Value(deviceOrigin),
    );
  }

  factory PuzzleSave.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleSave(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      placedValues: serializer.fromJson<String>(json['placedValues']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
      deviceOrigin: serializer.fromJson<String>(json['deviceOrigin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'placedValues': serializer.toJson<String>(placedValues),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'isComplete': serializer.toJson<bool>(isComplete),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
      'deviceOrigin': serializer.toJson<String>(deviceOrigin),
    };
  }

  PuzzleSave copyWith({
    String? puzzleId,
    String? placedValues,
    int? elapsedMs,
    bool? isComplete,
    DateTime? updatedAt,
    bool? pendingUpload,
    String? deviceOrigin,
  }) => PuzzleSave(
    puzzleId: puzzleId ?? this.puzzleId,
    placedValues: placedValues ?? this.placedValues,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    isComplete: isComplete ?? this.isComplete,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
    deviceOrigin: deviceOrigin ?? this.deviceOrigin,
  );
  PuzzleSave copyWithCompanion(PuzzleSavesCompanion data) {
    return PuzzleSave(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      placedValues: data.placedValues.present
          ? data.placedValues.value
          : this.placedValues,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
      deviceOrigin: data.deviceOrigin.present
          ? data.deviceOrigin.value
          : this.deviceOrigin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSave(')
          ..write('puzzleId: $puzzleId, ')
          ..write('placedValues: $placedValues, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('isComplete: $isComplete, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('deviceOrigin: $deviceOrigin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    placedValues,
    elapsedMs,
    isComplete,
    updatedAt,
    pendingUpload,
    deviceOrigin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleSave &&
          other.puzzleId == this.puzzleId &&
          other.placedValues == this.placedValues &&
          other.elapsedMs == this.elapsedMs &&
          other.isComplete == this.isComplete &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload &&
          other.deviceOrigin == this.deviceOrigin);
}

class PuzzleSavesCompanion extends UpdateCompanion<PuzzleSave> {
  final Value<String> puzzleId;
  final Value<String> placedValues;
  final Value<int> elapsedMs;
  final Value<bool> isComplete;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<String> deviceOrigin;
  final Value<int> rowid;
  const PuzzleSavesCompanion({
    this.puzzleId = const Value.absent(),
    this.placedValues = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.deviceOrigin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleSavesCompanion.insert({
    required String puzzleId,
    required String placedValues,
    this.elapsedMs = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.deviceOrigin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       placedValues = Value(placedValues);
  static Insertable<PuzzleSave> custom({
    Expression<String>? puzzleId,
    Expression<String>? placedValues,
    Expression<int>? elapsedMs,
    Expression<bool>? isComplete,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<String>? deviceOrigin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (placedValues != null) 'placed_values': placedValues,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (isComplete != null) 'is_complete': isComplete,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (deviceOrigin != null) 'device_origin': deviceOrigin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleSavesCompanion copyWith({
    Value<String>? puzzleId,
    Value<String>? placedValues,
    Value<int>? elapsedMs,
    Value<bool>? isComplete,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<String>? deviceOrigin,
    Value<int>? rowid,
  }) {
    return PuzzleSavesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      placedValues: placedValues ?? this.placedValues,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isComplete: isComplete ?? this.isComplete,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      deviceOrigin: deviceOrigin ?? this.deviceOrigin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (placedValues.present) {
      map['placed_values'] = Variable<String>(placedValues.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    if (deviceOrigin.present) {
      map['device_origin'] = Variable<String>(deviceOrigin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSavesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('placedValues: $placedValues, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('isComplete: $isComplete, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('deviceOrigin: $deviceOrigin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PacksTable extends Packs with TableInfo<$PacksTable, Pack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [packId, version, installedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId};
  @override
  Pack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pack(
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $PacksTable createAlias(String alias) {
    return $PacksTable(attachedDatabase, alias);
  }
}

class Pack extends DataClass implements Insertable<Pack> {
  final String packId;
  final int version;
  final DateTime installedAt;
  const Pack({
    required this.packId,
    required this.version,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<String>(packId);
    map['version'] = Variable<int>(version);
    map['installed_at'] = Variable<DateTime>(installedAt);
    return map;
  }

  PacksCompanion toCompanion(bool nullToAbsent) {
    return PacksCompanion(
      packId: Value(packId),
      version: Value(version),
      installedAt: Value(installedAt),
    );
  }

  factory Pack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pack(
      packId: serializer.fromJson<String>(json['packId']),
      version: serializer.fromJson<int>(json['version']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<String>(packId),
      'version': serializer.toJson<int>(version),
      'installedAt': serializer.toJson<DateTime>(installedAt),
    };
  }

  Pack copyWith({String? packId, int? version, DateTime? installedAt}) => Pack(
    packId: packId ?? this.packId,
    version: version ?? this.version,
    installedAt: installedAt ?? this.installedAt,
  );
  Pack copyWithCompanion(PacksCompanion data) {
    return Pack(
      packId: data.packId.present ? data.packId.value : this.packId,
      version: data.version.present ? data.version.value : this.version,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pack(')
          ..write('packId: $packId, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packId, version, installedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pack &&
          other.packId == this.packId &&
          other.version == this.version &&
          other.installedAt == this.installedAt);
}

class PacksCompanion extends UpdateCompanion<Pack> {
  final Value<String> packId;
  final Value<int> version;
  final Value<DateTime> installedAt;
  final Value<int> rowid;
  const PacksCompanion({
    this.packId = const Value.absent(),
    this.version = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PacksCompanion.insert({
    required String packId,
    required int version,
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : packId = Value(packId),
       version = Value(version);
  static Insertable<Pack> custom({
    Expression<String>? packId,
    Expression<int>? version,
    Expression<DateTime>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (version != null) 'version': version,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PacksCompanion copyWith({
    Value<String>? packId,
    Value<int>? version,
    Value<DateTime>? installedAt,
    Value<int>? rowid,
  }) {
    return PacksCompanion(
      packId: packId ?? this.packId,
      version: version ?? this.version,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PacksCompanion(')
          ..write('packId: $packId, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzlesTable extends Puzzles with TableInfo<$PuzzlesTable, Puzzle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cluesMeta = const VerificationMeta('clues');
  @override
  late final GeneratedColumn<String> clues = GeneratedColumn<String>(
    'clues',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 81,
      maxTextLength: 81,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solutionMeta = const VerificationMeta(
    'solution',
  );
  @override
  late final GeneratedColumn<String> solution = GeneratedColumn<String>(
    'solution',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 81,
      maxTextLength: 81,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Rank, String> rank =
      GeneratedColumn<String>(
        'rank',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Rank>($PuzzlesTable.$converterrank);
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packId,
    clues,
    solution,
    rank,
    seed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Puzzle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('clues')) {
      context.handle(
        _cluesMeta,
        clues.isAcceptableOrUnknown(data['clues']!, _cluesMeta),
      );
    } else if (isInserting) {
      context.missing(_cluesMeta);
    }
    if (data.containsKey('solution')) {
      context.handle(
        _solutionMeta,
        solution.isAcceptableOrUnknown(data['solution']!, _solutionMeta),
      );
    } else if (isInserting) {
      context.missing(_solutionMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Puzzle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Puzzle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_id'],
      )!,
      clues: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clues'],
      )!,
      solution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution'],
      )!,
      rank: $PuzzlesTable.$converterrank.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rank'],
        )!,
      ),
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
    );
  }

  @override
  $PuzzlesTable createAlias(String alias) {
    return $PuzzlesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Rank, String, String> $converterrank =
      const EnumNameConverter<Rank>(Rank.values);
}

class Puzzle extends DataClass implements Insertable<Puzzle> {
  final String id;
  final String packId;

  /// The givens, 81 characters, `.` for empty.
  final String clues;

  /// The full solution. Every puzzle has exactly one (D-08).
  final String solution;

  /// The hardest technique the puzzle requires, never its clue count (D-07).
  final Rank rank;
  final int seed;
  const Puzzle({
    required this.id,
    required this.packId,
    required this.clues,
    required this.solution,
    required this.rank,
    required this.seed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pack_id'] = Variable<String>(packId);
    map['clues'] = Variable<String>(clues);
    map['solution'] = Variable<String>(solution);
    {
      map['rank'] = Variable<String>($PuzzlesTable.$converterrank.toSql(rank));
    }
    map['seed'] = Variable<int>(seed);
    return map;
  }

  PuzzlesCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesCompanion(
      id: Value(id),
      packId: Value(packId),
      clues: Value(clues),
      solution: Value(solution),
      rank: Value(rank),
      seed: Value(seed),
    );
  }

  factory Puzzle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Puzzle(
      id: serializer.fromJson<String>(json['id']),
      packId: serializer.fromJson<String>(json['packId']),
      clues: serializer.fromJson<String>(json['clues']),
      solution: serializer.fromJson<String>(json['solution']),
      rank: $PuzzlesTable.$converterrank.fromJson(
        serializer.fromJson<String>(json['rank']),
      ),
      seed: serializer.fromJson<int>(json['seed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packId': serializer.toJson<String>(packId),
      'clues': serializer.toJson<String>(clues),
      'solution': serializer.toJson<String>(solution),
      'rank': serializer.toJson<String>(
        $PuzzlesTable.$converterrank.toJson(rank),
      ),
      'seed': serializer.toJson<int>(seed),
    };
  }

  Puzzle copyWith({
    String? id,
    String? packId,
    String? clues,
    String? solution,
    Rank? rank,
    int? seed,
  }) => Puzzle(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    clues: clues ?? this.clues,
    solution: solution ?? this.solution,
    rank: rank ?? this.rank,
    seed: seed ?? this.seed,
  );
  Puzzle copyWithCompanion(PuzzlesCompanion data) {
    return Puzzle(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      clues: data.clues.present ? data.clues.value : this.clues,
      solution: data.solution.present ? data.solution.value : this.solution,
      rank: data.rank.present ? data.rank.value : this.rank,
      seed: data.seed.present ? data.seed.value : this.seed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Puzzle(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('clues: $clues, ')
          ..write('solution: $solution, ')
          ..write('rank: $rank, ')
          ..write('seed: $seed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, packId, clues, solution, rank, seed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Puzzle &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.clues == this.clues &&
          other.solution == this.solution &&
          other.rank == this.rank &&
          other.seed == this.seed);
}

class PuzzlesCompanion extends UpdateCompanion<Puzzle> {
  final Value<String> id;
  final Value<String> packId;
  final Value<String> clues;
  final Value<String> solution;
  final Value<Rank> rank;
  final Value<int> seed;
  final Value<int> rowid;
  const PuzzlesCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.clues = const Value.absent(),
    this.solution = const Value.absent(),
    this.rank = const Value.absent(),
    this.seed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzlesCompanion.insert({
    required String id,
    required String packId,
    required String clues,
    required String solution,
    required Rank rank,
    required int seed,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packId = Value(packId),
       clues = Value(clues),
       solution = Value(solution),
       rank = Value(rank),
       seed = Value(seed);
  static Insertable<Puzzle> custom({
    Expression<String>? id,
    Expression<String>? packId,
    Expression<String>? clues,
    Expression<String>? solution,
    Expression<String>? rank,
    Expression<int>? seed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (clues != null) 'clues': clues,
      if (solution != null) 'solution': solution,
      if (rank != null) 'rank': rank,
      if (seed != null) 'seed': seed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzlesCompanion copyWith({
    Value<String>? id,
    Value<String>? packId,
    Value<String>? clues,
    Value<String>? solution,
    Value<Rank>? rank,
    Value<int>? seed,
    Value<int>? rowid,
  }) {
    return PuzzlesCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      clues: clues ?? this.clues,
      solution: solution ?? this.solution,
      rank: rank ?? this.rank,
      seed: seed ?? this.seed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (clues.present) {
      map['clues'] = Variable<String>(clues.value);
    }
    if (solution.present) {
      map['solution'] = Variable<String>(solution.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(
        $PuzzlesTable.$converterrank.toSql(rank.value),
      );
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzlesCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('clues: $clues, ')
          ..write('solution: $solution, ')
          ..write('rank: $rank, ')
          ..write('seed: $seed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SolvedPuzzlesTable extends SolvedPuzzles
    with TableInfo<$SolvedPuzzlesTable, SolvedPuzzle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolvedPuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solvedAtMeta = const VerificationMeta(
    'solvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> solvedAt = GeneratedColumn<DateTime>(
    'solved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    solvedAt,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solved_puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolvedPuzzle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('solved_at')) {
      context.handle(
        _solvedAtMeta,
        solvedAt.isAcceptableOrUnknown(data['solved_at']!, _solvedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  SolvedPuzzle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolvedPuzzle(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      solvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}solved_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
    );
  }

  @override
  $SolvedPuzzlesTable createAlias(String alias) {
    return $SolvedPuzzlesTable(attachedDatabase, alias);
  }
}

class SolvedPuzzle extends DataClass implements Insertable<SolvedPuzzle> {
  final String puzzleId;
  final DateTime solvedAt;
  final DateTime updatedAt;
  final bool pendingUpload;
  const SolvedPuzzle({
    required this.puzzleId,
    required this.solvedAt,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['solved_at'] = Variable<DateTime>(solvedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  SolvedPuzzlesCompanion toCompanion(bool nullToAbsent) {
    return SolvedPuzzlesCompanion(
      puzzleId: Value(puzzleId),
      solvedAt: Value(solvedAt),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory SolvedPuzzle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolvedPuzzle(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      solvedAt: serializer.fromJson<DateTime>(json['solvedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'solvedAt': serializer.toJson<DateTime>(solvedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  SolvedPuzzle copyWith({
    String? puzzleId,
    DateTime? solvedAt,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => SolvedPuzzle(
    puzzleId: puzzleId ?? this.puzzleId,
    solvedAt: solvedAt ?? this.solvedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  SolvedPuzzle copyWithCompanion(SolvedPuzzlesCompanion data) {
    return SolvedPuzzle(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      solvedAt: data.solvedAt.present ? data.solvedAt.value : this.solvedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolvedPuzzle(')
          ..write('puzzleId: $puzzleId, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(puzzleId, solvedAt, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolvedPuzzle &&
          other.puzzleId == this.puzzleId &&
          other.solvedAt == this.solvedAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class SolvedPuzzlesCompanion extends UpdateCompanion<SolvedPuzzle> {
  final Value<String> puzzleId;
  final Value<DateTime> solvedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const SolvedPuzzlesCompanion({
    this.puzzleId = const Value.absent(),
    this.solvedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SolvedPuzzlesCompanion.insert({
    required String puzzleId,
    this.solvedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId);
  static Insertable<SolvedPuzzle> custom({
    Expression<String>? puzzleId,
    Expression<DateTime>? solvedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (solvedAt != null) 'solved_at': solvedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SolvedPuzzlesCompanion copyWith({
    Value<String>? puzzleId,
    Value<DateTime>? solvedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return SolvedPuzzlesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      solvedAt: solvedAt ?? this.solvedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (solvedAt.present) {
      map['solved_at'] = Variable<DateTime>(solvedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolvedPuzzlesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifetimeStatsTable extends LifetimeStats
    with TableInfo<$LifetimeStatsTable, LifetimeStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifetimeStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _puzzlesSolvedMeta = const VerificationMeta(
    'puzzlesSolved',
  );
  @override
  late final GeneratedColumn<int> puzzlesSolved = GeneratedColumn<int>(
    'puzzles_solved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _perfectSolvesMeta = const VerificationMeta(
    'perfectSolves',
  );
  @override
  late final GeneratedColumn<int> perfectSolves = GeneratedColumn<int>(
    'perfect_solves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPlayMsMeta = const VerificationMeta(
    'totalPlayMs',
  );
  @override
  late final GeneratedColumn<int> totalPlayMs = GeneratedColumn<int>(
    'total_play_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzlesSolved,
    perfectSolves,
    totalPlayMs,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lifetime_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifetimeStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzles_solved')) {
      context.handle(
        _puzzlesSolvedMeta,
        puzzlesSolved.isAcceptableOrUnknown(
          data['puzzles_solved']!,
          _puzzlesSolvedMeta,
        ),
      );
    }
    if (data.containsKey('perfect_solves')) {
      context.handle(
        _perfectSolvesMeta,
        perfectSolves.isAcceptableOrUnknown(
          data['perfect_solves']!,
          _perfectSolvesMeta,
        ),
      );
    }
    if (data.containsKey('total_play_ms')) {
      context.handle(
        _totalPlayMsMeta,
        totalPlayMs.isAcceptableOrUnknown(
          data['total_play_ms']!,
          _totalPlayMsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifetimeStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifetimeStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzlesSolved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puzzles_solved'],
      )!,
      perfectSolves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}perfect_solves'],
      )!,
      totalPlayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_play_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
    );
  }

  @override
  $LifetimeStatsTable createAlias(String alias) {
    return $LifetimeStatsTable(attachedDatabase, alias);
  }
}

class LifetimeStat extends DataClass implements Insertable<LifetimeStat> {
  /// Always [singletonId]. The column exists only to give the single row a
  /// stable upsert target — leaving it to a default makes the conflict clause
  /// ambiguous, and the symptom is a second row rather than an error.
  final int id;
  final int puzzlesSolved;
  final int perfectSolves;
  final int totalPlayMs;
  final DateTime updatedAt;
  final bool pendingUpload;
  const LifetimeStat({
    required this.id,
    required this.puzzlesSolved,
    required this.perfectSolves,
    required this.totalPlayMs,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzles_solved'] = Variable<int>(puzzlesSolved);
    map['perfect_solves'] = Variable<int>(perfectSolves);
    map['total_play_ms'] = Variable<int>(totalPlayMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  LifetimeStatsCompanion toCompanion(bool nullToAbsent) {
    return LifetimeStatsCompanion(
      id: Value(id),
      puzzlesSolved: Value(puzzlesSolved),
      perfectSolves: Value(perfectSolves),
      totalPlayMs: Value(totalPlayMs),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory LifetimeStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifetimeStat(
      id: serializer.fromJson<int>(json['id']),
      puzzlesSolved: serializer.fromJson<int>(json['puzzlesSolved']),
      perfectSolves: serializer.fromJson<int>(json['perfectSolves']),
      totalPlayMs: serializer.fromJson<int>(json['totalPlayMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzlesSolved': serializer.toJson<int>(puzzlesSolved),
      'perfectSolves': serializer.toJson<int>(perfectSolves),
      'totalPlayMs': serializer.toJson<int>(totalPlayMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  LifetimeStat copyWith({
    int? id,
    int? puzzlesSolved,
    int? perfectSolves,
    int? totalPlayMs,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => LifetimeStat(
    id: id ?? this.id,
    puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
    perfectSolves: perfectSolves ?? this.perfectSolves,
    totalPlayMs: totalPlayMs ?? this.totalPlayMs,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  LifetimeStat copyWithCompanion(LifetimeStatsCompanion data) {
    return LifetimeStat(
      id: data.id.present ? data.id.value : this.id,
      puzzlesSolved: data.puzzlesSolved.present
          ? data.puzzlesSolved.value
          : this.puzzlesSolved,
      perfectSolves: data.perfectSolves.present
          ? data.perfectSolves.value
          : this.perfectSolves,
      totalPlayMs: data.totalPlayMs.present
          ? data.totalPlayMs.value
          : this.totalPlayMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifetimeStat(')
          ..write('id: $id, ')
          ..write('puzzlesSolved: $puzzlesSolved, ')
          ..write('perfectSolves: $perfectSolves, ')
          ..write('totalPlayMs: $totalPlayMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzlesSolved,
    perfectSolves,
    totalPlayMs,
    updatedAt,
    pendingUpload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifetimeStat &&
          other.id == this.id &&
          other.puzzlesSolved == this.puzzlesSolved &&
          other.perfectSolves == this.perfectSolves &&
          other.totalPlayMs == this.totalPlayMs &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class LifetimeStatsCompanion extends UpdateCompanion<LifetimeStat> {
  final Value<int> id;
  final Value<int> puzzlesSolved;
  final Value<int> perfectSolves;
  final Value<int> totalPlayMs;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  const LifetimeStatsCompanion({
    this.id = const Value.absent(),
    this.puzzlesSolved = const Value.absent(),
    this.perfectSolves = const Value.absent(),
    this.totalPlayMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
  });
  LifetimeStatsCompanion.insert({
    this.id = const Value.absent(),
    this.puzzlesSolved = const Value.absent(),
    this.perfectSolves = const Value.absent(),
    this.totalPlayMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
  });
  static Insertable<LifetimeStat> custom({
    Expression<int>? id,
    Expression<int>? puzzlesSolved,
    Expression<int>? perfectSolves,
    Expression<int>? totalPlayMs,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzlesSolved != null) 'puzzles_solved': puzzlesSolved,
      if (perfectSolves != null) 'perfect_solves': perfectSolves,
      if (totalPlayMs != null) 'total_play_ms': totalPlayMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
    });
  }

  LifetimeStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? puzzlesSolved,
    Value<int>? perfectSolves,
    Value<int>? totalPlayMs,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
  }) {
    return LifetimeStatsCompanion(
      id: id ?? this.id,
      puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
      perfectSolves: perfectSolves ?? this.perfectSolves,
      totalPlayMs: totalPlayMs ?? this.totalPlayMs,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzlesSolved.present) {
      map['puzzles_solved'] = Variable<int>(puzzlesSolved.value);
    }
    if (perfectSolves.present) {
      map['perfect_solves'] = Variable<int>(perfectSolves.value);
    }
    if (totalPlayMs.present) {
      map['total_play_ms'] = Variable<int>(totalPlayMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifetimeStatsCompanion(')
          ..write('id: $id, ')
          ..write('puzzlesSolved: $puzzlesSolved, ')
          ..write('perfectSolves: $perfectSolves, ')
          ..write('totalPlayMs: $totalPlayMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }
}

class $TechniqueStatsTable extends TechniqueStats
    with TableInfo<$TechniqueStatsTable, TechniqueStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TechniqueStatsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<Technique, String> technique =
      GeneratedColumn<String>(
        'technique',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Technique>($TechniqueStatsTable.$convertertechnique);
  static const VerificationMeta _puzzlesRequiringMeta = const VerificationMeta(
    'puzzlesRequiring',
  );
  @override
  late final GeneratedColumn<int> puzzlesRequiring = GeneratedColumn<int>(
    'puzzles_requiring',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    technique,
    puzzlesRequiring,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'technique_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<TechniqueStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzles_requiring')) {
      context.handle(
        _puzzlesRequiringMeta,
        puzzlesRequiring.isAcceptableOrUnknown(
          data['puzzles_requiring']!,
          _puzzlesRequiringMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {technique};
  @override
  TechniqueStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TechniqueStat(
      technique: $TechniqueStatsTable.$convertertechnique.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}technique'],
        )!,
      ),
      puzzlesRequiring: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puzzles_requiring'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
    );
  }

  @override
  $TechniqueStatsTable createAlias(String alias) {
    return $TechniqueStatsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Technique, String, String> $convertertechnique =
      const EnumNameConverter<Technique>(Technique.values);
}

class TechniqueStat extends DataClass implements Insertable<TechniqueStat> {
  final Technique technique;
  final int puzzlesRequiring;
  final DateTime updatedAt;
  final bool pendingUpload;
  const TechniqueStat({
    required this.technique,
    required this.puzzlesRequiring,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['technique'] = Variable<String>(
        $TechniqueStatsTable.$convertertechnique.toSql(technique),
      );
    }
    map['puzzles_requiring'] = Variable<int>(puzzlesRequiring);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  TechniqueStatsCompanion toCompanion(bool nullToAbsent) {
    return TechniqueStatsCompanion(
      technique: Value(technique),
      puzzlesRequiring: Value(puzzlesRequiring),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory TechniqueStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TechniqueStat(
      technique: $TechniqueStatsTable.$convertertechnique.fromJson(
        serializer.fromJson<String>(json['technique']),
      ),
      puzzlesRequiring: serializer.fromJson<int>(json['puzzlesRequiring']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'technique': serializer.toJson<String>(
        $TechniqueStatsTable.$convertertechnique.toJson(technique),
      ),
      'puzzlesRequiring': serializer.toJson<int>(puzzlesRequiring),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  TechniqueStat copyWith({
    Technique? technique,
    int? puzzlesRequiring,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => TechniqueStat(
    technique: technique ?? this.technique,
    puzzlesRequiring: puzzlesRequiring ?? this.puzzlesRequiring,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  TechniqueStat copyWithCompanion(TechniqueStatsCompanion data) {
    return TechniqueStat(
      technique: data.technique.present ? data.technique.value : this.technique,
      puzzlesRequiring: data.puzzlesRequiring.present
          ? data.puzzlesRequiring.value
          : this.puzzlesRequiring,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TechniqueStat(')
          ..write('technique: $technique, ')
          ..write('puzzlesRequiring: $puzzlesRequiring, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(technique, puzzlesRequiring, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TechniqueStat &&
          other.technique == this.technique &&
          other.puzzlesRequiring == this.puzzlesRequiring &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class TechniqueStatsCompanion extends UpdateCompanion<TechniqueStat> {
  final Value<Technique> technique;
  final Value<int> puzzlesRequiring;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const TechniqueStatsCompanion({
    this.technique = const Value.absent(),
    this.puzzlesRequiring = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TechniqueStatsCompanion.insert({
    required Technique technique,
    this.puzzlesRequiring = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : technique = Value(technique);
  static Insertable<TechniqueStat> custom({
    Expression<String>? technique,
    Expression<int>? puzzlesRequiring,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (technique != null) 'technique': technique,
      if (puzzlesRequiring != null) 'puzzles_requiring': puzzlesRequiring,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TechniqueStatsCompanion copyWith({
    Value<Technique>? technique,
    Value<int>? puzzlesRequiring,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return TechniqueStatsCompanion(
      technique: technique ?? this.technique,
      puzzlesRequiring: puzzlesRequiring ?? this.puzzlesRequiring,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (technique.present) {
      map['technique'] = Variable<String>(
        $TechniqueStatsTable.$convertertechnique.toSql(technique.value),
      );
    }
    if (puzzlesRequiring.present) {
      map['puzzles_requiring'] = Variable<int>(puzzlesRequiring.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TechniqueStatsCompanion(')
          ..write('technique: $technique, ')
          ..write('puzzlesRequiring: $puzzlesRequiring, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boolValueMeta = const VerificationMeta(
    'boolValue',
  );
  @override
  late final GeneratedColumn<bool> boolValue = GeneratedColumn<bool>(
    'bool_value',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bool_value" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _pendingUploadMeta = const VerificationMeta(
    'pendingUpload',
  );
  @override
  late final GeneratedColumn<bool> pendingUpload = GeneratedColumn<bool>(
    'pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    boolValue,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('bool_value')) {
      context.handle(
        _boolValueMeta,
        boolValue.isAcceptableOrUnknown(data['bool_value']!, _boolValueMeta),
      );
    } else if (isInserting) {
      context.missing(_boolValueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending_upload')) {
      context.handle(
        _pendingUploadMeta,
        pendingUpload.isAcceptableOrUnknown(
          data['pending_upload']!,
          _pendingUploadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      boolValue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bool_value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_upload'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final bool boolValue;
  final DateTime updatedAt;
  final bool pendingUpload;
  const Setting({
    required this.key,
    required this.boolValue,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['bool_value'] = Variable<bool>(boolValue);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      boolValue: Value(boolValue),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      boolValue: serializer.fromJson<bool>(json['boolValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'boolValue': serializer.toJson<bool>(boolValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  Setting copyWith({
    String? key,
    bool? boolValue,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => Setting(
    key: key ?? this.key,
    boolValue: boolValue ?? this.boolValue,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      boolValue: data.boolValue.present ? data.boolValue.value : this.boolValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('boolValue: $boolValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, boolValue, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.boolValue == this.boolValue &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<bool> boolValue;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.boolValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required bool boolValue,
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       boolValue = Value(boolValue);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<bool>? boolValue,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (boolValue != null) 'bool_value': boolValue,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<bool>? boolValue,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      boolValue: boolValue ?? this.boolValue,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (boolValue.present) {
      map['bool_value'] = Variable<bool>(boolValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingUpload.present) {
      map['pending_upload'] = Variable<bool>(pendingUpload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('boolValue: $boolValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigCacheTable extends ConfigCache
    with TableInfo<$ConfigCacheTable, ConfigCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validatorMeta = const VerificationMeta(
    'validator',
  );
  @override
  late final GeneratedColumn<String> validator = GeneratedColumn<String>(
    'validator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [id, document, validator, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('validator')) {
      context.handle(
        _validatorMeta,
        validator.isAcceptableOrUnknown(data['validator']!, _validatorMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      validator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validator'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $ConfigCacheTable createAlias(String alias) {
    return $ConfigCacheTable(attachedDatabase, alias);
  }
}

class ConfigCacheData extends DataClass implements Insertable<ConfigCacheData> {
  /// Always [singletonId]. One config, one row.
  final int id;

  /// The document exactly as fetched, re-parsed on read rather than stored
  /// pre-parsed: the parser is where per-key fallback and clamping happen, and
  /// a cached config must go through both again after an app upgrade that
  /// changed either.
  final String document;

  /// The server's entity tag, sent on the next fetch so an unchanged document
  /// costs a round trip and no payload.
  final String? validator;
  final DateTime fetchedAt;
  const ConfigCacheData({
    required this.id,
    required this.document,
    this.validator,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document'] = Variable<String>(document);
    if (!nullToAbsent || validator != null) {
      map['validator'] = Variable<String>(validator);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ConfigCacheCompanion toCompanion(bool nullToAbsent) {
    return ConfigCacheCompanion(
      id: Value(id),
      document: Value(document),
      validator: validator == null && nullToAbsent
          ? const Value.absent()
          : Value(validator),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ConfigCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigCacheData(
      id: serializer.fromJson<int>(json['id']),
      document: serializer.fromJson<String>(json['document']),
      validator: serializer.fromJson<String?>(json['validator']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'document': serializer.toJson<String>(document),
      'validator': serializer.toJson<String?>(validator),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ConfigCacheData copyWith({
    int? id,
    String? document,
    Value<String?> validator = const Value.absent(),
    DateTime? fetchedAt,
  }) => ConfigCacheData(
    id: id ?? this.id,
    document: document ?? this.document,
    validator: validator.present ? validator.value : this.validator,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  ConfigCacheData copyWithCompanion(ConfigCacheCompanion data) {
    return ConfigCacheData(
      id: data.id.present ? data.id.value : this.id,
      document: data.document.present ? data.document.value : this.document,
      validator: data.validator.present ? data.validator.value : this.validator,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigCacheData(')
          ..write('id: $id, ')
          ..write('document: $document, ')
          ..write('validator: $validator, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, document, validator, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigCacheData &&
          other.id == this.id &&
          other.document == this.document &&
          other.validator == this.validator &&
          other.fetchedAt == this.fetchedAt);
}

class ConfigCacheCompanion extends UpdateCompanion<ConfigCacheData> {
  final Value<int> id;
  final Value<String> document;
  final Value<String?> validator;
  final Value<DateTime> fetchedAt;
  const ConfigCacheCompanion({
    this.id = const Value.absent(),
    this.document = const Value.absent(),
    this.validator = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  ConfigCacheCompanion.insert({
    this.id = const Value.absent(),
    required String document,
    this.validator = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  }) : document = Value(document);
  static Insertable<ConfigCacheData> custom({
    Expression<int>? id,
    Expression<String>? document,
    Expression<String>? validator,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (document != null) 'document': document,
      if (validator != null) 'validator': validator,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  ConfigCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? document,
    Value<String?>? validator,
    Value<DateTime>? fetchedAt,
  }) {
    return ConfigCacheCompanion(
      id: id ?? this.id,
      document: document ?? this.document,
      validator: validator ?? this.validator,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (validator.present) {
      map['validator'] = Variable<String>(validator.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigCacheCompanion(')
          ..write('id: $id, ')
          ..write('document: $document, ')
          ..write('validator: $validator, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $PuzzleSavesTable puzzleSaves = $PuzzleSavesTable(this);
  late final $PacksTable packs = $PacksTable(this);
  late final $PuzzlesTable puzzles = $PuzzlesTable(this);
  late final $SolvedPuzzlesTable solvedPuzzles = $SolvedPuzzlesTable(this);
  late final $LifetimeStatsTable lifetimeStats = $LifetimeStatsTable(this);
  late final $TechniqueStatsTable techniqueStats = $TechniqueStatsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ConfigCacheTable configCache = $ConfigCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    puzzleSaves,
    packs,
    puzzles,
    solvedPuzzles,
    lifetimeStats,
    techniqueStats,
    settings,
    configCache,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String puzzleId,
      required int cell,
      required int digit,
      required NoteKind kind,
      required NoteOrigin origin,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> puzzleId,
      Value<int> cell,
      Value<int> digit,
      Value<NoteKind> kind,
      Value<NoteOrigin> origin,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cell => $composableBuilder(
    column: $table.cell,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get digit => $composableBuilder(
    column: $table.digit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NoteKind, NoteKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<NoteOrigin, NoteOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cell => $composableBuilder(
    column: $table.cell,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get digit => $composableBuilder(
    column: $table.digit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<int> get cell =>
      $composableBuilder(column: $table.cell, builder: (column) => column);

  GeneratedColumn<int> get digit =>
      $composableBuilder(column: $table.digit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<int> cell = const Value.absent(),
                Value<int> digit = const Value.absent(),
                Value<NoteKind> kind = const Value.absent(),
                Value<NoteOrigin> origin = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                puzzleId: puzzleId,
                cell: cell,
                digit: digit,
                kind: kind,
                origin: origin,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required int cell,
                required int digit,
                required NoteKind kind,
                required NoteOrigin origin,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                puzzleId: puzzleId,
                cell: cell,
                digit: digit,
                kind: kind,
                origin: origin,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$PuzzleSavesTableCreateCompanionBuilder =
    PuzzleSavesCompanion Function({
      required String puzzleId,
      required String placedValues,
      Value<int> elapsedMs,
      Value<bool> isComplete,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<String> deviceOrigin,
      Value<int> rowid,
    });
typedef $$PuzzleSavesTableUpdateCompanionBuilder =
    PuzzleSavesCompanion Function({
      Value<String> puzzleId,
      Value<String> placedValues,
      Value<int> elapsedMs,
      Value<bool> isComplete,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<String> deviceOrigin,
      Value<int> rowid,
    });

class $$PuzzleSavesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleSavesTable> {
  $$PuzzleSavesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placedValues => $composableBuilder(
    column: $table.placedValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceOrigin => $composableBuilder(
    column: $table.deviceOrigin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuzzleSavesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleSavesTable> {
  $$PuzzleSavesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placedValues => $composableBuilder(
    column: $table.placedValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceOrigin => $composableBuilder(
    column: $table.deviceOrigin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzleSavesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleSavesTable> {
  $$PuzzleSavesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get placedValues => $composableBuilder(
    column: $table.placedValues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceOrigin => $composableBuilder(
    column: $table.deviceOrigin,
    builder: (column) => column,
  );
}

class $$PuzzleSavesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleSavesTable,
          PuzzleSave,
          $$PuzzleSavesTableFilterComposer,
          $$PuzzleSavesTableOrderingComposer,
          $$PuzzleSavesTableAnnotationComposer,
          $$PuzzleSavesTableCreateCompanionBuilder,
          $$PuzzleSavesTableUpdateCompanionBuilder,
          (
            PuzzleSave,
            BaseReferences<_$AppDatabase, $PuzzleSavesTable, PuzzleSave>,
          ),
          PuzzleSave,
          PrefetchHooks Function()
        > {
  $$PuzzleSavesTableTableManager(_$AppDatabase db, $PuzzleSavesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleSavesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleSavesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleSavesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<String> placedValues = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<String> deviceOrigin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSavesCompanion(
                puzzleId: puzzleId,
                placedValues: placedValues,
                elapsedMs: elapsedMs,
                isComplete: isComplete,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                deviceOrigin: deviceOrigin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required String placedValues,
                Value<int> elapsedMs = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<String> deviceOrigin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSavesCompanion.insert(
                puzzleId: puzzleId,
                placedValues: placedValues,
                elapsedMs: elapsedMs,
                isComplete: isComplete,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                deviceOrigin: deviceOrigin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuzzleSavesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleSavesTable,
      PuzzleSave,
      $$PuzzleSavesTableFilterComposer,
      $$PuzzleSavesTableOrderingComposer,
      $$PuzzleSavesTableAnnotationComposer,
      $$PuzzleSavesTableCreateCompanionBuilder,
      $$PuzzleSavesTableUpdateCompanionBuilder,
      (
        PuzzleSave,
        BaseReferences<_$AppDatabase, $PuzzleSavesTable, PuzzleSave>,
      ),
      PuzzleSave,
      PrefetchHooks Function()
    >;
typedef $$PacksTableCreateCompanionBuilder =
    PacksCompanion Function({
      required String packId,
      required int version,
      Value<DateTime> installedAt,
      Value<int> rowid,
    });
typedef $$PacksTableUpdateCompanionBuilder =
    PacksCompanion Function({
      Value<String> packId,
      Value<int> version,
      Value<DateTime> installedAt,
      Value<int> rowid,
    });

class $$PacksTableFilterComposer extends Composer<_$AppDatabase, $PacksTable> {
  $$PacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PacksTableOrderingComposer
    extends Composer<_$AppDatabase, $PacksTable> {
  $$PacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PacksTable> {
  $$PacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );
}

class $$PacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PacksTable,
          Pack,
          $$PacksTableFilterComposer,
          $$PacksTableOrderingComposer,
          $$PacksTableAnnotationComposer,
          $$PacksTableCreateCompanionBuilder,
          $$PacksTableUpdateCompanionBuilder,
          (Pack, BaseReferences<_$AppDatabase, $PacksTable, Pack>),
          Pack,
          PrefetchHooks Function()
        > {
  $$PacksTableTableManager(_$AppDatabase db, $PacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PacksCompanion(
                packId: packId,
                version: version,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packId,
                required int version,
                Value<DateTime> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PacksCompanion.insert(
                packId: packId,
                version: version,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PacksTable,
      Pack,
      $$PacksTableFilterComposer,
      $$PacksTableOrderingComposer,
      $$PacksTableAnnotationComposer,
      $$PacksTableCreateCompanionBuilder,
      $$PacksTableUpdateCompanionBuilder,
      (Pack, BaseReferences<_$AppDatabase, $PacksTable, Pack>),
      Pack,
      PrefetchHooks Function()
    >;
typedef $$PuzzlesTableCreateCompanionBuilder =
    PuzzlesCompanion Function({
      required String id,
      required String packId,
      required String clues,
      required String solution,
      required Rank rank,
      required int seed,
      Value<int> rowid,
    });
typedef $$PuzzlesTableUpdateCompanionBuilder =
    PuzzlesCompanion Function({
      Value<String> id,
      Value<String> packId,
      Value<String> clues,
      Value<String> solution,
      Value<Rank> rank,
      Value<int> seed,
      Value<int> rowid,
    });

class $$PuzzlesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clues => $composableBuilder(
    column: $table.clues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Rank, Rank, String> get rank =>
      $composableBuilder(
        column: $table.rank,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuzzlesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clues => $composableBuilder(
    column: $table.clues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<String> get clues =>
      $composableBuilder(column: $table.clues, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Rank, String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);
}

class $$PuzzlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzlesTable,
          Puzzle,
          $$PuzzlesTableFilterComposer,
          $$PuzzlesTableOrderingComposer,
          $$PuzzlesTableAnnotationComposer,
          $$PuzzlesTableCreateCompanionBuilder,
          $$PuzzlesTableUpdateCompanionBuilder,
          (Puzzle, BaseReferences<_$AppDatabase, $PuzzlesTable, Puzzle>),
          Puzzle,
          PrefetchHooks Function()
        > {
  $$PuzzlesTableTableManager(_$AppDatabase db, $PuzzlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packId = const Value.absent(),
                Value<String> clues = const Value.absent(),
                Value<String> solution = const Value.absent(),
                Value<Rank> rank = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion(
                id: id,
                packId: packId,
                clues: clues,
                solution: solution,
                rank: rank,
                seed: seed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packId,
                required String clues,
                required String solution,
                required Rank rank,
                required int seed,
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion.insert(
                id: id,
                packId: packId,
                clues: clues,
                solution: solution,
                rank: rank,
                seed: seed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuzzlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzlesTable,
      Puzzle,
      $$PuzzlesTableFilterComposer,
      $$PuzzlesTableOrderingComposer,
      $$PuzzlesTableAnnotationComposer,
      $$PuzzlesTableCreateCompanionBuilder,
      $$PuzzlesTableUpdateCompanionBuilder,
      (Puzzle, BaseReferences<_$AppDatabase, $PuzzlesTable, Puzzle>),
      Puzzle,
      PrefetchHooks Function()
    >;
typedef $$SolvedPuzzlesTableCreateCompanionBuilder =
    SolvedPuzzlesCompanion Function({
      required String puzzleId,
      Value<DateTime> solvedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$SolvedPuzzlesTableUpdateCompanionBuilder =
    SolvedPuzzlesCompanion Function({
      Value<String> puzzleId,
      Value<DateTime> solvedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$SolvedPuzzlesTableFilterComposer
    extends Composer<_$AppDatabase, $SolvedPuzzlesTable> {
  $$SolvedPuzzlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolvedPuzzlesTableOrderingComposer
    extends Composer<_$AppDatabase, $SolvedPuzzlesTable> {
  $$SolvedPuzzlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolvedPuzzlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolvedPuzzlesTable> {
  $$SolvedPuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<DateTime> get solvedAt =>
      $composableBuilder(column: $table.solvedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$SolvedPuzzlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SolvedPuzzlesTable,
          SolvedPuzzle,
          $$SolvedPuzzlesTableFilterComposer,
          $$SolvedPuzzlesTableOrderingComposer,
          $$SolvedPuzzlesTableAnnotationComposer,
          $$SolvedPuzzlesTableCreateCompanionBuilder,
          $$SolvedPuzzlesTableUpdateCompanionBuilder,
          (
            SolvedPuzzle,
            BaseReferences<_$AppDatabase, $SolvedPuzzlesTable, SolvedPuzzle>,
          ),
          SolvedPuzzle,
          PrefetchHooks Function()
        > {
  $$SolvedPuzzlesTableTableManager(_$AppDatabase db, $SolvedPuzzlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolvedPuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolvedPuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolvedPuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<DateTime> solvedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolvedPuzzlesCompanion(
                puzzleId: puzzleId,
                solvedAt: solvedAt,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                Value<DateTime> solvedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolvedPuzzlesCompanion.insert(
                puzzleId: puzzleId,
                solvedAt: solvedAt,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolvedPuzzlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SolvedPuzzlesTable,
      SolvedPuzzle,
      $$SolvedPuzzlesTableFilterComposer,
      $$SolvedPuzzlesTableOrderingComposer,
      $$SolvedPuzzlesTableAnnotationComposer,
      $$SolvedPuzzlesTableCreateCompanionBuilder,
      $$SolvedPuzzlesTableUpdateCompanionBuilder,
      (
        SolvedPuzzle,
        BaseReferences<_$AppDatabase, $SolvedPuzzlesTable, SolvedPuzzle>,
      ),
      SolvedPuzzle,
      PrefetchHooks Function()
    >;
typedef $$LifetimeStatsTableCreateCompanionBuilder =
    LifetimeStatsCompanion Function({
      Value<int> id,
      Value<int> puzzlesSolved,
      Value<int> perfectSolves,
      Value<int> totalPlayMs,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
    });
typedef $$LifetimeStatsTableUpdateCompanionBuilder =
    LifetimeStatsCompanion Function({
      Value<int> id,
      Value<int> puzzlesSolved,
      Value<int> perfectSolves,
      Value<int> totalPlayMs,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
    });

class $$LifetimeStatsTableFilterComposer
    extends Composer<_$AppDatabase, $LifetimeStatsTable> {
  $$LifetimeStatsTableFilterComposer({
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

  ColumnFilters<int> get puzzlesSolved => $composableBuilder(
    column: $table.puzzlesSolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perfectSolves => $composableBuilder(
    column: $table.perfectSolves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPlayMs => $composableBuilder(
    column: $table.totalPlayMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LifetimeStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $LifetimeStatsTable> {
  $$LifetimeStatsTableOrderingComposer({
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

  ColumnOrderings<int> get puzzlesSolved => $composableBuilder(
    column: $table.puzzlesSolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perfectSolves => $composableBuilder(
    column: $table.perfectSolves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPlayMs => $composableBuilder(
    column: $table.totalPlayMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LifetimeStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifetimeStatsTable> {
  $$LifetimeStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get puzzlesSolved => $composableBuilder(
    column: $table.puzzlesSolved,
    builder: (column) => column,
  );

  GeneratedColumn<int> get perfectSolves => $composableBuilder(
    column: $table.perfectSolves,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPlayMs => $composableBuilder(
    column: $table.totalPlayMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$LifetimeStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifetimeStatsTable,
          LifetimeStat,
          $$LifetimeStatsTableFilterComposer,
          $$LifetimeStatsTableOrderingComposer,
          $$LifetimeStatsTableAnnotationComposer,
          $$LifetimeStatsTableCreateCompanionBuilder,
          $$LifetimeStatsTableUpdateCompanionBuilder,
          (
            LifetimeStat,
            BaseReferences<_$AppDatabase, $LifetimeStatsTable, LifetimeStat>,
          ),
          LifetimeStat,
          PrefetchHooks Function()
        > {
  $$LifetimeStatsTableTableManager(_$AppDatabase db, $LifetimeStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifetimeStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifetimeStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifetimeStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> puzzlesSolved = const Value.absent(),
                Value<int> perfectSolves = const Value.absent(),
                Value<int> totalPlayMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
              }) => LifetimeStatsCompanion(
                id: id,
                puzzlesSolved: puzzlesSolved,
                perfectSolves: perfectSolves,
                totalPlayMs: totalPlayMs,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> puzzlesSolved = const Value.absent(),
                Value<int> perfectSolves = const Value.absent(),
                Value<int> totalPlayMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
              }) => LifetimeStatsCompanion.insert(
                id: id,
                puzzlesSolved: puzzlesSolved,
                perfectSolves: perfectSolves,
                totalPlayMs: totalPlayMs,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LifetimeStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifetimeStatsTable,
      LifetimeStat,
      $$LifetimeStatsTableFilterComposer,
      $$LifetimeStatsTableOrderingComposer,
      $$LifetimeStatsTableAnnotationComposer,
      $$LifetimeStatsTableCreateCompanionBuilder,
      $$LifetimeStatsTableUpdateCompanionBuilder,
      (
        LifetimeStat,
        BaseReferences<_$AppDatabase, $LifetimeStatsTable, LifetimeStat>,
      ),
      LifetimeStat,
      PrefetchHooks Function()
    >;
typedef $$TechniqueStatsTableCreateCompanionBuilder =
    TechniqueStatsCompanion Function({
      required Technique technique,
      Value<int> puzzlesRequiring,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$TechniqueStatsTableUpdateCompanionBuilder =
    TechniqueStatsCompanion Function({
      Value<Technique> technique,
      Value<int> puzzlesRequiring,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$TechniqueStatsTableFilterComposer
    extends Composer<_$AppDatabase, $TechniqueStatsTable> {
  $$TechniqueStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Technique, Technique, String> get technique =>
      $composableBuilder(
        column: $table.technique,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get puzzlesRequiring => $composableBuilder(
    column: $table.puzzlesRequiring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TechniqueStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $TechniqueStatsTable> {
  $$TechniqueStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get technique => $composableBuilder(
    column: $table.technique,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puzzlesRequiring => $composableBuilder(
    column: $table.puzzlesRequiring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TechniqueStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TechniqueStatsTable> {
  $$TechniqueStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Technique, String> get technique =>
      $composableBuilder(column: $table.technique, builder: (column) => column);

  GeneratedColumn<int> get puzzlesRequiring => $composableBuilder(
    column: $table.puzzlesRequiring,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$TechniqueStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TechniqueStatsTable,
          TechniqueStat,
          $$TechniqueStatsTableFilterComposer,
          $$TechniqueStatsTableOrderingComposer,
          $$TechniqueStatsTableAnnotationComposer,
          $$TechniqueStatsTableCreateCompanionBuilder,
          $$TechniqueStatsTableUpdateCompanionBuilder,
          (
            TechniqueStat,
            BaseReferences<_$AppDatabase, $TechniqueStatsTable, TechniqueStat>,
          ),
          TechniqueStat,
          PrefetchHooks Function()
        > {
  $$TechniqueStatsTableTableManager(
    _$AppDatabase db,
    $TechniqueStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TechniqueStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TechniqueStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TechniqueStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Technique> technique = const Value.absent(),
                Value<int> puzzlesRequiring = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TechniqueStatsCompanion(
                technique: technique,
                puzzlesRequiring: puzzlesRequiring,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Technique technique,
                Value<int> puzzlesRequiring = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TechniqueStatsCompanion.insert(
                technique: technique,
                puzzlesRequiring: puzzlesRequiring,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TechniqueStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TechniqueStatsTable,
      TechniqueStat,
      $$TechniqueStatsTableFilterComposer,
      $$TechniqueStatsTableOrderingComposer,
      $$TechniqueStatsTableAnnotationComposer,
      $$TechniqueStatsTableCreateCompanionBuilder,
      $$TechniqueStatsTableUpdateCompanionBuilder,
      (
        TechniqueStat,
        BaseReferences<_$AppDatabase, $TechniqueStatsTable, TechniqueStat>,
      ),
      TechniqueStat,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required bool boolValue,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<bool> boolValue,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get boolValue => $composableBuilder(
    column: $table.boolValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get boolValue => $composableBuilder(
    column: $table.boolValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get boolValue =>
      $composableBuilder(column: $table.boolValue, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<bool> boolValue = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                boolValue: boolValue,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required bool boolValue,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                boolValue: boolValue,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ConfigCacheTableCreateCompanionBuilder =
    ConfigCacheCompanion Function({
      Value<int> id,
      required String document,
      Value<String?> validator,
      Value<DateTime> fetchedAt,
    });
typedef $$ConfigCacheTableUpdateCompanionBuilder =
    ConfigCacheCompanion Function({
      Value<int> id,
      Value<String> document,
      Value<String?> validator,
      Value<DateTime> fetchedAt,
    });

class $$ConfigCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigCacheTable> {
  $$ConfigCacheTableFilterComposer({
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

  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validator => $composableBuilder(
    column: $table.validator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigCacheTable> {
  $$ConfigCacheTableOrderingComposer({
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

  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validator => $composableBuilder(
    column: $table.validator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigCacheTable> {
  $$ConfigCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<String> get validator =>
      $composableBuilder(column: $table.validator, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ConfigCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigCacheTable,
          ConfigCacheData,
          $$ConfigCacheTableFilterComposer,
          $$ConfigCacheTableOrderingComposer,
          $$ConfigCacheTableAnnotationComposer,
          $$ConfigCacheTableCreateCompanionBuilder,
          $$ConfigCacheTableUpdateCompanionBuilder,
          (
            ConfigCacheData,
            BaseReferences<_$AppDatabase, $ConfigCacheTable, ConfigCacheData>,
          ),
          ConfigCacheData,
          PrefetchHooks Function()
        > {
  $$ConfigCacheTableTableManager(_$AppDatabase db, $ConfigCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<String?> validator = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => ConfigCacheCompanion(
                id: id,
                document: document,
                validator: validator,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String document,
                Value<String?> validator = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => ConfigCacheCompanion.insert(
                id: id,
                document: document,
                validator: validator,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigCacheTable,
      ConfigCacheData,
      $$ConfigCacheTableFilterComposer,
      $$ConfigCacheTableOrderingComposer,
      $$ConfigCacheTableAnnotationComposer,
      $$ConfigCacheTableCreateCompanionBuilder,
      $$ConfigCacheTableUpdateCompanionBuilder,
      (
        ConfigCacheData,
        BaseReferences<_$AppDatabase, $ConfigCacheTable, ConfigCacheData>,
      ),
      ConfigCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$PuzzleSavesTableTableManager get puzzleSaves =>
      $$PuzzleSavesTableTableManager(_db, _db.puzzleSaves);
  $$PacksTableTableManager get packs =>
      $$PacksTableTableManager(_db, _db.packs);
  $$PuzzlesTableTableManager get puzzles =>
      $$PuzzlesTableTableManager(_db, _db.puzzles);
  $$SolvedPuzzlesTableTableManager get solvedPuzzles =>
      $$SolvedPuzzlesTableTableManager(_db, _db.solvedPuzzles);
  $$LifetimeStatsTableTableManager get lifetimeStats =>
      $$LifetimeStatsTableTableManager(_db, _db.lifetimeStats);
  $$TechniqueStatsTableTableManager get techniqueStats =>
      $$TechniqueStatsTableTableManager(_db, _db.techniqueStats);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ConfigCacheTableTableManager get configCache =>
      $$ConfigCacheTableTableManager(_db, _db.configCache);
}
