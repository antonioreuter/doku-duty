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
  static const VerificationMeta _mistakesMeta = const VerificationMeta(
    'mistakes',
  );
  @override
  late final GeneratedColumn<int> mistakes = GeneratedColumn<int>(
    'mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    mistakes,
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
    if (data.containsKey('mistakes')) {
      context.handle(
        _mistakesMeta,
        mistakes.isAcceptableOrUnknown(data['mistakes']!, _mistakesMeta),
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
      mistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mistakes'],
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

  /// **Mistake**s recorded against this **attempt** (D-96).
  ///
  /// Defaults to zero, which is also what a save written before
  /// `add-mistake-model` reads as — the only honest answer, since the
  /// placements that made it were never inspected.
  ///
  /// On the save row rather than a table of its own: it is one number per
  /// puzzle in progress, it is written by the same action that writes the
  /// board, and a second table would be a second thing to keep in step with
  /// the first (constraint 9).
  final int mistakes;
  const PuzzleSave({
    required this.puzzleId,
    required this.placedValues,
    required this.elapsedMs,
    required this.isComplete,
    required this.updatedAt,
    required this.pendingUpload,
    required this.deviceOrigin,
    required this.mistakes,
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
    map['mistakes'] = Variable<int>(mistakes);
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
      mistakes: Value(mistakes),
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
      mistakes: serializer.fromJson<int>(json['mistakes']),
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
      'mistakes': serializer.toJson<int>(mistakes),
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
    int? mistakes,
  }) => PuzzleSave(
    puzzleId: puzzleId ?? this.puzzleId,
    placedValues: placedValues ?? this.placedValues,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    isComplete: isComplete ?? this.isComplete,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
    deviceOrigin: deviceOrigin ?? this.deviceOrigin,
    mistakes: mistakes ?? this.mistakes,
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
      mistakes: data.mistakes.present ? data.mistakes.value : this.mistakes,
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
          ..write('deviceOrigin: $deviceOrigin, ')
          ..write('mistakes: $mistakes')
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
    mistakes,
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
          other.deviceOrigin == this.deviceOrigin &&
          other.mistakes == this.mistakes);
}

class PuzzleSavesCompanion extends UpdateCompanion<PuzzleSave> {
  final Value<String> puzzleId;
  final Value<String> placedValues;
  final Value<int> elapsedMs;
  final Value<bool> isComplete;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<String> deviceOrigin;
  final Value<int> mistakes;
  final Value<int> rowid;
  const PuzzleSavesCompanion({
    this.puzzleId = const Value.absent(),
    this.placedValues = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.deviceOrigin = const Value.absent(),
    this.mistakes = const Value.absent(),
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
    this.mistakes = const Value.absent(),
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
    Expression<int>? mistakes,
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
      if (mistakes != null) 'mistakes': mistakes,
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
    Value<int>? mistakes,
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
      mistakes: mistakes ?? this.mistakes,
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
    if (mistakes.present) {
      map['mistakes'] = Variable<int>(mistakes.value);
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
          ..write('mistakes: $mistakes, ')
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
    $customConstraints: 'NOT NULL REFERENCES packs (pack_id)',
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

  /// The **pack** this puzzle came from.
  ///
  /// Spelled as a custom constraint rather than `.references(Packs, #packId)`,
  /// and not by preference. `.references()` stopped emitting the SQL-level
  /// foreign key at some drift upgrade, so the app quietly began creating this
  /// column as a bare `TEXT NOT NULL` while every schema snapshot from v1 on
  /// still recorded `REFERENCES packs (pack_id)`. Nothing caught it because the
  /// migration tests compare snapshots with each other, and no schema change
  /// was made between the upgrade and `add-technique-tutorials` — whose bump to
  /// version 4 was the first comparison against what the app actually builds.
  ///
  /// Installs from before that upgrade have the key; installs made in between
  /// do not. Neither enforces it — there is no `foreign_keys` pragma — so the
  /// divergence costs nothing at runtime, and stating the constraint here is
  /// what makes new databases agree with the old ones and with the snapshots
  /// again.
  ///
  /// **Do not swap this back to `.references()` without dumping
  /// `sqlite_master` and reading the emitted SQL.** The declaration looks
  /// correct either way; only the SQL says which one it is.
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

class $SeenLessonsTable extends SeenLessons
    with TableInfo<$SeenLessonsTable, SeenLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeenLessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
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
    lessonId,
    seenAt,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen_lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeenLesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
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
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  SeenLesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenLesson(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_at'],
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
  $SeenLessonsTable createAlias(String alias) {
    return $SeenLessonsTable(attachedDatabase, alias);
  }
}

class SeenLesson extends DataClass implements Insertable<SeenLesson> {
  final String lessonId;
  final DateTime seenAt;
  final DateTime updatedAt;
  final bool pendingUpload;
  const SeenLesson({
    required this.lessonId,
    required this.seenAt,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['seen_at'] = Variable<DateTime>(seenAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  SeenLessonsCompanion toCompanion(bool nullToAbsent) {
    return SeenLessonsCompanion(
      lessonId: Value(lessonId),
      seenAt: Value(seenAt),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory SeenLesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenLesson(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      seenAt: serializer.fromJson<DateTime>(json['seenAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'seenAt': serializer.toJson<DateTime>(seenAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  SeenLesson copyWith({
    String? lessonId,
    DateTime? seenAt,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => SeenLesson(
    lessonId: lessonId ?? this.lessonId,
    seenAt: seenAt ?? this.seenAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  SeenLesson copyWithCompanion(SeenLessonsCompanion data) {
    return SeenLesson(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenLesson(')
          ..write('lessonId: $lessonId, ')
          ..write('seenAt: $seenAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, seenAt, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenLesson &&
          other.lessonId == this.lessonId &&
          other.seenAt == this.seenAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class SeenLessonsCompanion extends UpdateCompanion<SeenLesson> {
  final Value<String> lessonId;
  final Value<DateTime> seenAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const SeenLessonsCompanion({
    this.lessonId = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeenLessonsCompanion.insert({
    required String lessonId,
    this.seenAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId);
  static Insertable<SeenLesson> custom({
    Expression<String>? lessonId,
    Expression<DateTime>? seenAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (seenAt != null) 'seen_at': seenAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeenLessonsCompanion copyWith({
    Value<String>? lessonId,
    Value<DateTime>? seenAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return SeenLessonsCompanion(
      lessonId: lessonId ?? this.lessonId,
      seenAt: seenAt ?? this.seenAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
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
    return (StringBuffer('SeenLessonsCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('seenAt: $seenAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeasonStatesTable extends SeasonStates
    with TableInfo<$SeasonStatesTable, SeasonState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
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
    id,
    seasonId,
    startedAt,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'season_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeasonState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
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
  SeasonState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
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
  $SeasonStatesTable createAlias(String alias) {
    return $SeasonStatesTable(attachedDatabase, alias);
  }
}

class SeasonState extends DataClass implements Insertable<SeasonState> {
  /// Always [singletonId]. One **season** in force, one row.
  final int id;

  /// The **season**'s id, matching the definition's own.
  final String seasonId;

  /// When this **season** became the one in force. Not the **season**'s start
  /// date, which the definition carries — this is when *this player* began it.
  final DateTime startedAt;
  final DateTime updatedAt;
  final bool pendingUpload;
  const SeasonState({
    required this.id,
    required this.seasonId,
    required this.startedAt,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['season_id'] = Variable<String>(seasonId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  SeasonStatesCompanion toCompanion(bool nullToAbsent) {
    return SeasonStatesCompanion(
      id: Value(id),
      seasonId: Value(seasonId),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory SeasonState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonState(
      id: serializer.fromJson<int>(json['id']),
      seasonId: serializer.fromJson<String>(json['seasonId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seasonId': serializer.toJson<String>(seasonId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  SeasonState copyWith({
    int? id,
    String? seasonId,
    DateTime? startedAt,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => SeasonState(
    id: id ?? this.id,
    seasonId: seasonId ?? this.seasonId,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  SeasonState copyWithCompanion(SeasonStatesCompanion data) {
    return SeasonState(
      id: data.id.present ? data.id.value : this.id,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonState(')
          ..write('id: $id, ')
          ..write('seasonId: $seasonId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seasonId, startedAt, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonState &&
          other.id == this.id &&
          other.seasonId == this.seasonId &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class SeasonStatesCompanion extends UpdateCompanion<SeasonState> {
  final Value<int> id;
  final Value<String> seasonId;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  const SeasonStatesCompanion({
    this.id = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
  });
  SeasonStatesCompanion.insert({
    this.id = const Value.absent(),
    required String seasonId,
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
  }) : seasonId = Value(seasonId);
  static Insertable<SeasonState> custom({
    Expression<int>? id,
    Expression<String>? seasonId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seasonId != null) 'season_id': seasonId,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
    });
  }

  SeasonStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? seasonId,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
  }) {
    return SeasonStatesCompanion(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      startedAt: startedAt ?? this.startedAt,
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
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
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
    return (StringBuffer('SeasonStatesCompanion(')
          ..write('id: $id, ')
          ..write('seasonId: $seasonId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }
}

class $CompletedNodesTable extends CompletedNodes
    with TableInfo<$CompletedNodesTable, CompletedNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    check: () => ComparableExpr(position).isBetweenValues(1, 42),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
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
    seasonId,
    position,
    completedAt,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedNode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
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
  Set<GeneratedColumn> get $primaryKey => {seasonId, position};
  @override
  CompletedNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedNode(
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
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
  $CompletedNodesTable createAlias(String alias) {
    return $CompletedNodesTable(attachedDatabase, alias);
  }
}

class CompletedNode extends DataClass implements Insertable<CompletedNode> {
  final String seasonId;

  /// 1-based, matching what the player is shown ("Node 14").
  final int position;
  final DateTime completedAt;
  final DateTime updatedAt;
  final bool pendingUpload;
  const CompletedNode({
    required this.seasonId,
    required this.position,
    required this.completedAt,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season_id'] = Variable<String>(seasonId);
    map['position'] = Variable<int>(position);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  CompletedNodesCompanion toCompanion(bool nullToAbsent) {
    return CompletedNodesCompanion(
      seasonId: Value(seasonId),
      position: Value(position),
      completedAt: Value(completedAt),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory CompletedNode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedNode(
      seasonId: serializer.fromJson<String>(json['seasonId']),
      position: serializer.fromJson<int>(json['position']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seasonId': serializer.toJson<String>(seasonId),
      'position': serializer.toJson<int>(position),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  CompletedNode copyWith({
    String? seasonId,
    int? position,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => CompletedNode(
    seasonId: seasonId ?? this.seasonId,
    position: position ?? this.position,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  CompletedNode copyWithCompanion(CompletedNodesCompanion data) {
    return CompletedNode(
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      position: data.position.present ? data.position.value : this.position,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedNode(')
          ..write('seasonId: $seasonId, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seasonId, position, completedAt, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedNode &&
          other.seasonId == this.seasonId &&
          other.position == this.position &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class CompletedNodesCompanion extends UpdateCompanion<CompletedNode> {
  final Value<String> seasonId;
  final Value<int> position;
  final Value<DateTime> completedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const CompletedNodesCompanion({
    this.seasonId = const Value.absent(),
    this.position = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletedNodesCompanion.insert({
    required String seasonId,
    required int position,
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : seasonId = Value(seasonId),
       position = Value(position);
  static Insertable<CompletedNode> custom({
    Expression<String>? seasonId,
    Expression<int>? position,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seasonId != null) 'season_id': seasonId,
      if (position != null) 'position': position,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletedNodesCompanion copyWith({
    Value<String>? seasonId,
    Value<int>? position,
    Value<DateTime>? completedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return CompletedNodesCompanion(
      seasonId: seasonId ?? this.seasonId,
      position: position ?? this.position,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
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
    return (StringBuffer('CompletedNodesCompanion(')
          ..write('seasonId: $seasonId, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BossAttemptsTable extends BossAttempts
    with TableInfo<$BossAttemptsTable, BossAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BossAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    check: () => ComparableExpr(position).isBetweenValues(1, 42),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
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
    seasonId,
    position,
    attempts,
    updatedAt,
    pendingUpload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boss_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BossAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
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
  Set<GeneratedColumn> get $primaryKey => {seasonId, position};
  @override
  BossAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BossAttempt(
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
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
  $BossAttemptsTable createAlias(String alias) {
    return $BossAttemptsTable(attachedDatabase, alias);
  }
}

class BossAttempt extends DataClass implements Insertable<BossAttempt> {
  final String seasonId;
  final int position;
  final int attempts;
  final DateTime updatedAt;
  final bool pendingUpload;
  const BossAttempt({
    required this.seasonId,
    required this.position,
    required this.attempts,
    required this.updatedAt,
    required this.pendingUpload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season_id'] = Variable<String>(seasonId);
    map['position'] = Variable<int>(position);
    map['attempts'] = Variable<int>(attempts);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_upload'] = Variable<bool>(pendingUpload);
    return map;
  }

  BossAttemptsCompanion toCompanion(bool nullToAbsent) {
    return BossAttemptsCompanion(
      seasonId: Value(seasonId),
      position: Value(position),
      attempts: Value(attempts),
      updatedAt: Value(updatedAt),
      pendingUpload: Value(pendingUpload),
    );
  }

  factory BossAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BossAttempt(
      seasonId: serializer.fromJson<String>(json['seasonId']),
      position: serializer.fromJson<int>(json['position']),
      attempts: serializer.fromJson<int>(json['attempts']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingUpload: serializer.fromJson<bool>(json['pendingUpload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seasonId': serializer.toJson<String>(seasonId),
      'position': serializer.toJson<int>(position),
      'attempts': serializer.toJson<int>(attempts),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingUpload': serializer.toJson<bool>(pendingUpload),
    };
  }

  BossAttempt copyWith({
    String? seasonId,
    int? position,
    int? attempts,
    DateTime? updatedAt,
    bool? pendingUpload,
  }) => BossAttempt(
    seasonId: seasonId ?? this.seasonId,
    position: position ?? this.position,
    attempts: attempts ?? this.attempts,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingUpload: pendingUpload ?? this.pendingUpload,
  );
  BossAttempt copyWithCompanion(BossAttemptsCompanion data) {
    return BossAttempt(
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      position: data.position.present ? data.position.value : this.position,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingUpload: data.pendingUpload.present
          ? data.pendingUpload.value
          : this.pendingUpload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BossAttempt(')
          ..write('seasonId: $seasonId, ')
          ..write('position: $position, ')
          ..write('attempts: $attempts, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seasonId, position, attempts, updatedAt, pendingUpload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BossAttempt &&
          other.seasonId == this.seasonId &&
          other.position == this.position &&
          other.attempts == this.attempts &&
          other.updatedAt == this.updatedAt &&
          other.pendingUpload == this.pendingUpload);
}

class BossAttemptsCompanion extends UpdateCompanion<BossAttempt> {
  final Value<String> seasonId;
  final Value<int> position;
  final Value<int> attempts;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingUpload;
  final Value<int> rowid;
  const BossAttemptsCompanion({
    this.seasonId = const Value.absent(),
    this.position = const Value.absent(),
    this.attempts = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BossAttemptsCompanion.insert({
    required String seasonId,
    required int position,
    this.attempts = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingUpload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : seasonId = Value(seasonId),
       position = Value(position);
  static Insertable<BossAttempt> custom({
    Expression<String>? seasonId,
    Expression<int>? position,
    Expression<int>? attempts,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingUpload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seasonId != null) 'season_id': seasonId,
      if (position != null) 'position': position,
      if (attempts != null) 'attempts': attempts,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingUpload != null) 'pending_upload': pendingUpload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BossAttemptsCompanion copyWith({
    Value<String>? seasonId,
    Value<int>? position,
    Value<int>? attempts,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingUpload,
    Value<int>? rowid,
  }) {
    return BossAttemptsCompanion(
      seasonId: seasonId ?? this.seasonId,
      position: position ?? this.position,
      attempts: attempts ?? this.attempts,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
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
    return (StringBuffer('BossAttemptsCompanion(')
          ..write('seasonId: $seasonId, ')
          ..write('position: $position, ')
          ..write('attempts: $attempts, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingUpload: $pendingUpload, ')
          ..write('rowid: $rowid')
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
  late final $SeenLessonsTable seenLessons = $SeenLessonsTable(this);
  late final $SeasonStatesTable seasonStates = $SeasonStatesTable(this);
  late final $CompletedNodesTable completedNodes = $CompletedNodesTable(this);
  late final $BossAttemptsTable bossAttempts = $BossAttemptsTable(this);
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
    seenLessons,
    seasonStates,
    completedNodes,
    bossAttempts,
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
      Value<int> mistakes,
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
      Value<int> mistakes,
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

  ColumnFilters<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
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

  ColumnOrderings<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
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

  GeneratedColumn<int> get mistakes =>
      $composableBuilder(column: $table.mistakes, builder: (column) => column);
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
                Value<int> mistakes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSavesCompanion(
                puzzleId: puzzleId,
                placedValues: placedValues,
                elapsedMs: elapsedMs,
                isComplete: isComplete,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                deviceOrigin: deviceOrigin,
                mistakes: mistakes,
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
                Value<int> mistakes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSavesCompanion.insert(
                puzzleId: puzzleId,
                placedValues: placedValues,
                elapsedMs: elapsedMs,
                isComplete: isComplete,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                deviceOrigin: deviceOrigin,
                mistakes: mistakes,
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

final class $$PacksTableReferences
    extends BaseReferences<_$AppDatabase, $PacksTable, Pack> {
  $$PacksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzlesTable, List<Puzzle>> _puzzlesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.puzzles,
    aliasName: $_aliasNameGenerator(db.packs.packId, db.puzzles.packId),
  );

  $$PuzzlesTableProcessedTableManager get puzzlesRefs {
    final manager = $$PuzzlesTableTableManager($_db, $_db.puzzles).filter(
      (f) => f.packId.packId.sqlEquals($_itemColumn<String>('pack_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_puzzlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  Expression<bool> puzzlesRefs(
    Expression<bool> Function($$PuzzlesTableFilterComposer f) f,
  ) {
    final $$PuzzlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableFilterComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  Expression<T> puzzlesRefs<T extends Object>(
    Expression<T> Function($$PuzzlesTableAnnotationComposer a) f,
  ) {
    final $$PuzzlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Pack, $$PacksTableReferences),
          Pack,
          PrefetchHooks Function({bool puzzlesRefs})
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
              .map(
                (e) =>
                    (e.readTable(table), $$PacksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({puzzlesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (puzzlesRefs) db.puzzles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (puzzlesRefs)
                    await $_getPrefetchedData<Pack, $PacksTable, Puzzle>(
                      currentTable: table,
                      referencedTable: $$PacksTableReferences._puzzlesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$PacksTableReferences(db, table, p0).puzzlesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.packId == item.packId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (Pack, $$PacksTableReferences),
      Pack,
      PrefetchHooks Function({bool puzzlesRefs})
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

final class $$PuzzlesTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzlesTable, Puzzle> {
  $$PuzzlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PacksTable _packIdTable(_$AppDatabase db) => db.packs.createAlias(
    $_aliasNameGenerator(db.puzzles.packId, db.packs.packId),
  );

  $$PacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<String>('pack_id')!;

    final manager = $$PacksTableTableManager(
      $_db,
      $_db.packs,
    ).filter((f) => f.packId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$PacksTableFilterComposer get packId {
    final $$PacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.packs,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PacksTableFilterComposer(
            $db: $db,
            $table: $db.packs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$PacksTableOrderingComposer get packId {
    final $$PacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.packs,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PacksTableOrderingComposer(
            $db: $db,
            $table: $db.packs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get clues =>
      $composableBuilder(column: $table.clues, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Rank, String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  $$PacksTableAnnotationComposer get packId {
    final $$PacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.packs,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PacksTableAnnotationComposer(
            $db: $db,
            $table: $db.packs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Puzzle, $$PuzzlesTableReferences),
          Puzzle,
          PrefetchHooks Function({bool packId})
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
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (packId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.packId,
                                referencedTable: $$PuzzlesTableReferences
                                    ._packIdTable(db),
                                referencedColumn: $$PuzzlesTableReferences
                                    ._packIdTable(db)
                                    .packId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
      (Puzzle, $$PuzzlesTableReferences),
      Puzzle,
      PrefetchHooks Function({bool packId})
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
typedef $$SeenLessonsTableCreateCompanionBuilder =
    SeenLessonsCompanion Function({
      required String lessonId,
      Value<DateTime> seenAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$SeenLessonsTableUpdateCompanionBuilder =
    SeenLessonsCompanion Function({
      Value<String> lessonId,
      Value<DateTime> seenAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$SeenLessonsTableFilterComposer
    extends Composer<_$AppDatabase, $SeenLessonsTable> {
  $$SeenLessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
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

class $$SeenLessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeenLessonsTable> {
  $$SeenLessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
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

class $$SeenLessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeenLessonsTable> {
  $$SeenLessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$SeenLessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeenLessonsTable,
          SeenLesson,
          $$SeenLessonsTableFilterComposer,
          $$SeenLessonsTableOrderingComposer,
          $$SeenLessonsTableAnnotationComposer,
          $$SeenLessonsTableCreateCompanionBuilder,
          $$SeenLessonsTableUpdateCompanionBuilder,
          (
            SeenLesson,
            BaseReferences<_$AppDatabase, $SeenLessonsTable, SeenLesson>,
          ),
          SeenLesson,
          PrefetchHooks Function()
        > {
  $$SeenLessonsTableTableManager(_$AppDatabase db, $SeenLessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeenLessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeenLessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeenLessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<DateTime> seenAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeenLessonsCompanion(
                lessonId: lessonId,
                seenAt: seenAt,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                Value<DateTime> seenAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeenLessonsCompanion.insert(
                lessonId: lessonId,
                seenAt: seenAt,
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

typedef $$SeenLessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeenLessonsTable,
      SeenLesson,
      $$SeenLessonsTableFilterComposer,
      $$SeenLessonsTableOrderingComposer,
      $$SeenLessonsTableAnnotationComposer,
      $$SeenLessonsTableCreateCompanionBuilder,
      $$SeenLessonsTableUpdateCompanionBuilder,
      (
        SeenLesson,
        BaseReferences<_$AppDatabase, $SeenLessonsTable, SeenLesson>,
      ),
      SeenLesson,
      PrefetchHooks Function()
    >;
typedef $$SeasonStatesTableCreateCompanionBuilder =
    SeasonStatesCompanion Function({
      Value<int> id,
      required String seasonId,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
    });
typedef $$SeasonStatesTableUpdateCompanionBuilder =
    SeasonStatesCompanion Function({
      Value<int> id,
      Value<String> seasonId,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
    });

class $$SeasonStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SeasonStatesTable> {
  $$SeasonStatesTableFilterComposer({
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

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
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

class $$SeasonStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SeasonStatesTable> {
  $$SeasonStatesTableOrderingComposer({
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

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
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

class $$SeasonStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeasonStatesTable> {
  $$SeasonStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$SeasonStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonStatesTable,
          SeasonState,
          $$SeasonStatesTableFilterComposer,
          $$SeasonStatesTableOrderingComposer,
          $$SeasonStatesTableAnnotationComposer,
          $$SeasonStatesTableCreateCompanionBuilder,
          $$SeasonStatesTableUpdateCompanionBuilder,
          (
            SeasonState,
            BaseReferences<_$AppDatabase, $SeasonStatesTable, SeasonState>,
          ),
          SeasonState,
          PrefetchHooks Function()
        > {
  $$SeasonStatesTableTableManager(_$AppDatabase db, $SeasonStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> seasonId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
              }) => SeasonStatesCompanion(
                id: id,
                seasonId: seasonId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String seasonId,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
              }) => SeasonStatesCompanion.insert(
                id: id,
                seasonId: seasonId,
                startedAt: startedAt,
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

typedef $$SeasonStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonStatesTable,
      SeasonState,
      $$SeasonStatesTableFilterComposer,
      $$SeasonStatesTableOrderingComposer,
      $$SeasonStatesTableAnnotationComposer,
      $$SeasonStatesTableCreateCompanionBuilder,
      $$SeasonStatesTableUpdateCompanionBuilder,
      (
        SeasonState,
        BaseReferences<_$AppDatabase, $SeasonStatesTable, SeasonState>,
      ),
      SeasonState,
      PrefetchHooks Function()
    >;
typedef $$CompletedNodesTableCreateCompanionBuilder =
    CompletedNodesCompanion Function({
      required String seasonId,
      required int position,
      Value<DateTime> completedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$CompletedNodesTableUpdateCompanionBuilder =
    CompletedNodesCompanion Function({
      Value<String> seasonId,
      Value<int> position,
      Value<DateTime> completedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$CompletedNodesTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedNodesTable> {
  $$CompletedNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

class $$CompletedNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedNodesTable> {
  $$CompletedNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

class $$CompletedNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedNodesTable> {
  $$CompletedNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$CompletedNodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedNodesTable,
          CompletedNode,
          $$CompletedNodesTableFilterComposer,
          $$CompletedNodesTableOrderingComposer,
          $$CompletedNodesTableAnnotationComposer,
          $$CompletedNodesTableCreateCompanionBuilder,
          $$CompletedNodesTableUpdateCompanionBuilder,
          (
            CompletedNode,
            BaseReferences<_$AppDatabase, $CompletedNodesTable, CompletedNode>,
          ),
          CompletedNode,
          PrefetchHooks Function()
        > {
  $$CompletedNodesTableTableManager(
    _$AppDatabase db,
    $CompletedNodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> seasonId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletedNodesCompanion(
                seasonId: seasonId,
                position: position,
                completedAt: completedAt,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String seasonId,
                required int position,
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletedNodesCompanion.insert(
                seasonId: seasonId,
                position: position,
                completedAt: completedAt,
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

typedef $$CompletedNodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedNodesTable,
      CompletedNode,
      $$CompletedNodesTableFilterComposer,
      $$CompletedNodesTableOrderingComposer,
      $$CompletedNodesTableAnnotationComposer,
      $$CompletedNodesTableCreateCompanionBuilder,
      $$CompletedNodesTableUpdateCompanionBuilder,
      (
        CompletedNode,
        BaseReferences<_$AppDatabase, $CompletedNodesTable, CompletedNode>,
      ),
      CompletedNode,
      PrefetchHooks Function()
    >;
typedef $$BossAttemptsTableCreateCompanionBuilder =
    BossAttemptsCompanion Function({
      required String seasonId,
      required int position,
      Value<int> attempts,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });
typedef $$BossAttemptsTableUpdateCompanionBuilder =
    BossAttemptsCompanion Function({
      Value<String> seasonId,
      Value<int> position,
      Value<int> attempts,
      Value<DateTime> updatedAt,
      Value<bool> pendingUpload,
      Value<int> rowid,
    });

class $$BossAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $BossAttemptsTable> {
  $$BossAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
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

class $$BossAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $BossAttemptsTable> {
  $$BossAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
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

class $$BossAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BossAttemptsTable> {
  $$BossAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingUpload => $composableBuilder(
    column: $table.pendingUpload,
    builder: (column) => column,
  );
}

class $$BossAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BossAttemptsTable,
          BossAttempt,
          $$BossAttemptsTableFilterComposer,
          $$BossAttemptsTableOrderingComposer,
          $$BossAttemptsTableAnnotationComposer,
          $$BossAttemptsTableCreateCompanionBuilder,
          $$BossAttemptsTableUpdateCompanionBuilder,
          (
            BossAttempt,
            BaseReferences<_$AppDatabase, $BossAttemptsTable, BossAttempt>,
          ),
          BossAttempt,
          PrefetchHooks Function()
        > {
  $$BossAttemptsTableTableManager(_$AppDatabase db, $BossAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BossAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BossAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BossAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> seasonId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BossAttemptsCompanion(
                seasonId: seasonId,
                position: position,
                attempts: attempts,
                updatedAt: updatedAt,
                pendingUpload: pendingUpload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String seasonId,
                required int position,
                Value<int> attempts = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingUpload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BossAttemptsCompanion.insert(
                seasonId: seasonId,
                position: position,
                attempts: attempts,
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

typedef $$BossAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BossAttemptsTable,
      BossAttempt,
      $$BossAttemptsTableFilterComposer,
      $$BossAttemptsTableOrderingComposer,
      $$BossAttemptsTableAnnotationComposer,
      $$BossAttemptsTableCreateCompanionBuilder,
      $$BossAttemptsTableUpdateCompanionBuilder,
      (
        BossAttempt,
        BaseReferences<_$AppDatabase, $BossAttemptsTable, BossAttempt>,
      ),
      BossAttempt,
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
  $$SeenLessonsTableTableManager get seenLessons =>
      $$SeenLessonsTableTableManager(_db, _db.seenLessons);
  $$SeasonStatesTableTableManager get seasonStates =>
      $$SeasonStatesTableTableManager(_db, _db.seasonStates);
  $$CompletedNodesTableTableManager get completedNodes =>
      $$CompletedNodesTableTableManager(_db, _db.completedNodes);
  $$BossAttemptsTableTableManager get bossAttempts =>
      $$BossAttemptsTableTableManager(_db, _db.bossAttempts);
}
