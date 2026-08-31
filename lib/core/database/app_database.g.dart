// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayerProfilesTable extends PlayerProfiles
    with TableInfo<$PlayerProfilesTable, PlayerProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudUidMeta = const VerificationMeta(
    'cloudUid',
  );
  @override
  late final GeneratedColumn<String> cloudUid = GeneratedColumn<String>(
    'cloud_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarSeedMeta = const VerificationMeta(
    'avatarSeed',
  );
  @override
  late final GeneratedColumn<int> avatarSeed = GeneratedColumn<int>(
    'avatar_seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCoinsMeta = const VerificationMeta(
    'totalCoins',
  );
  @override
  late final GeneratedColumn<int> totalCoins = GeneratedColumn<int>(
    'total_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gamesWonMeta = const VerificationMeta(
    'gamesWon',
  );
  @override
  late final GeneratedColumn<int> gamesWon = GeneratedColumn<int>(
    'games_won',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMovesMeta = const VerificationMeta(
    'totalMoves',
  );
  @override
  late final GeneratedColumn<int> totalMoves = GeneratedColumn<int>(
    'total_moves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedDateMeta = const VerificationMeta(
    'lastPlayedDate',
  );
  @override
  late final GeneratedColumn<String> lastPlayedDate = GeneratedColumn<String>(
    'last_played_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    cloudUid,
    displayName,
    avatarSeed,
    totalXp,
    totalCoins,
    gamesWon,
    totalMoves,
    currentStreak,
    longestStreak,
    lastPlayedDate,
    createdAt,
    updatedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('cloud_uid')) {
      context.handle(
        _cloudUidMeta,
        cloudUid.isAcceptableOrUnknown(data['cloud_uid']!, _cloudUidMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_seed')) {
      context.handle(
        _avatarSeedMeta,
        avatarSeed.isAcceptableOrUnknown(data['avatar_seed']!, _avatarSeedMeta),
      );
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('total_coins')) {
      context.handle(
        _totalCoinsMeta,
        totalCoins.isAcceptableOrUnknown(data['total_coins']!, _totalCoinsMeta),
      );
    }
    if (data.containsKey('games_won')) {
      context.handle(
        _gamesWonMeta,
        gamesWon.isAcceptableOrUnknown(data['games_won']!, _gamesWonMeta),
      );
    }
    if (data.containsKey('total_moves')) {
      context.handle(
        _totalMovesMeta,
        totalMoves.isAcceptableOrUnknown(data['total_moves']!, _totalMovesMeta),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_played_date')) {
      context.handle(
        _lastPlayedDateMeta,
        lastPlayedDate.isAcceptableOrUnknown(
          data['last_played_date']!,
          _lastPlayedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PlayerProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerProfileRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      cloudUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_uid'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_seed'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      totalCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_coins'],
      )!,
      gamesWon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}games_won'],
      )!,
      totalMoves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_moves'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      lastPlayedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_played_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $PlayerProfilesTable createAlias(String alias) {
    return $PlayerProfilesTable(attachedDatabase, alias);
  }
}

class PlayerProfileRow extends DataClass
    implements Insertable<PlayerProfileRow> {
  final String localId;

  /// UID de Firebase, o null mientras el jugador no tenga cuenta.
  final String? cloudUid;
  final String displayName;
  final int avatarSeed;

  /// XP acumulado de por vida. Monótono: nunca baja.
  final int totalXp;
  final int totalCoins;
  final int gamesWon;
  final int totalMoves;
  final int currentStreak;
  final int longestStreak;

  /// Último día jugado como `'YYYY-MM-DD'` en zona **local**.
  ///
  /// Texto y no timestamp: la racha tiene que resolverse sin servidor y
  /// sobrevivir a un cambio de huso horario sin saltar ni romperse.
  final String? lastPlayedDate;
  final int createdAt;
  final int updatedAt;

  /// Contador para resolver conflictos last-write-wins en los campos de
  /// perfil (nombre, avatar), que no son acumulables.
  final int version;
  const PlayerProfileRow({
    required this.localId,
    this.cloudUid,
    required this.displayName,
    required this.avatarSeed,
    required this.totalXp,
    required this.totalCoins,
    required this.gamesWon,
    required this.totalMoves,
    required this.currentStreak,
    required this.longestStreak,
    this.lastPlayedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || cloudUid != null) {
      map['cloud_uid'] = Variable<String>(cloudUid);
    }
    map['display_name'] = Variable<String>(displayName);
    map['avatar_seed'] = Variable<int>(avatarSeed);
    map['total_xp'] = Variable<int>(totalXp);
    map['total_coins'] = Variable<int>(totalCoins);
    map['games_won'] = Variable<int>(gamesWon);
    map['total_moves'] = Variable<int>(totalMoves);
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    if (!nullToAbsent || lastPlayedDate != null) {
      map['last_played_date'] = Variable<String>(lastPlayedDate);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  PlayerProfilesCompanion toCompanion(bool nullToAbsent) {
    return PlayerProfilesCompanion(
      localId: Value(localId),
      cloudUid: cloudUid == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudUid),
      displayName: Value(displayName),
      avatarSeed: Value(avatarSeed),
      totalXp: Value(totalXp),
      totalCoins: Value(totalCoins),
      gamesWon: Value(gamesWon),
      totalMoves: Value(totalMoves),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      lastPlayedDate: lastPlayedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
    );
  }

  factory PlayerProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerProfileRow(
      localId: serializer.fromJson<String>(json['localId']),
      cloudUid: serializer.fromJson<String?>(json['cloudUid']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarSeed: serializer.fromJson<int>(json['avatarSeed']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      totalCoins: serializer.fromJson<int>(json['totalCoins']),
      gamesWon: serializer.fromJson<int>(json['gamesWon']),
      totalMoves: serializer.fromJson<int>(json['totalMoves']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      lastPlayedDate: serializer.fromJson<String?>(json['lastPlayedDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'cloudUid': serializer.toJson<String?>(cloudUid),
      'displayName': serializer.toJson<String>(displayName),
      'avatarSeed': serializer.toJson<int>(avatarSeed),
      'totalXp': serializer.toJson<int>(totalXp),
      'totalCoins': serializer.toJson<int>(totalCoins),
      'gamesWon': serializer.toJson<int>(gamesWon),
      'totalMoves': serializer.toJson<int>(totalMoves),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'lastPlayedDate': serializer.toJson<String?>(lastPlayedDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  PlayerProfileRow copyWith({
    String? localId,
    Value<String?> cloudUid = const Value.absent(),
    String? displayName,
    int? avatarSeed,
    int? totalXp,
    int? totalCoins,
    int? gamesWon,
    int? totalMoves,
    int? currentStreak,
    int? longestStreak,
    Value<String?> lastPlayedDate = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    int? version,
  }) => PlayerProfileRow(
    localId: localId ?? this.localId,
    cloudUid: cloudUid.present ? cloudUid.value : this.cloudUid,
    displayName: displayName ?? this.displayName,
    avatarSeed: avatarSeed ?? this.avatarSeed,
    totalXp: totalXp ?? this.totalXp,
    totalCoins: totalCoins ?? this.totalCoins,
    gamesWon: gamesWon ?? this.gamesWon,
    totalMoves: totalMoves ?? this.totalMoves,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastPlayedDate: lastPlayedDate.present
        ? lastPlayedDate.value
        : this.lastPlayedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );
  PlayerProfileRow copyWithCompanion(PlayerProfilesCompanion data) {
    return PlayerProfileRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      cloudUid: data.cloudUid.present ? data.cloudUid.value : this.cloudUid,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarSeed: data.avatarSeed.present
          ? data.avatarSeed.value
          : this.avatarSeed,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      totalCoins: data.totalCoins.present
          ? data.totalCoins.value
          : this.totalCoins,
      gamesWon: data.gamesWon.present ? data.gamesWon.value : this.gamesWon,
      totalMoves: data.totalMoves.present
          ? data.totalMoves.value
          : this.totalMoves,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      lastPlayedDate: data.lastPlayedDate.present
          ? data.lastPlayedDate.value
          : this.lastPlayedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerProfileRow(')
          ..write('localId: $localId, ')
          ..write('cloudUid: $cloudUid, ')
          ..write('displayName: $displayName, ')
          ..write('avatarSeed: $avatarSeed, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalCoins: $totalCoins, ')
          ..write('gamesWon: $gamesWon, ')
          ..write('totalMoves: $totalMoves, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastPlayedDate: $lastPlayedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    cloudUid,
    displayName,
    avatarSeed,
    totalXp,
    totalCoins,
    gamesWon,
    totalMoves,
    currentStreak,
    longestStreak,
    lastPlayedDate,
    createdAt,
    updatedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerProfileRow &&
          other.localId == this.localId &&
          other.cloudUid == this.cloudUid &&
          other.displayName == this.displayName &&
          other.avatarSeed == this.avatarSeed &&
          other.totalXp == this.totalXp &&
          other.totalCoins == this.totalCoins &&
          other.gamesWon == this.gamesWon &&
          other.totalMoves == this.totalMoves &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.lastPlayedDate == this.lastPlayedDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version);
}

class PlayerProfilesCompanion extends UpdateCompanion<PlayerProfileRow> {
  final Value<String> localId;
  final Value<String?> cloudUid;
  final Value<String> displayName;
  final Value<int> avatarSeed;
  final Value<int> totalXp;
  final Value<int> totalCoins;
  final Value<int> gamesWon;
  final Value<int> totalMoves;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<String?> lastPlayedDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> rowid;
  const PlayerProfilesCompanion({
    this.localId = const Value.absent(),
    this.cloudUid = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarSeed = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalCoins = const Value.absent(),
    this.gamesWon = const Value.absent(),
    this.totalMoves = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerProfilesCompanion.insert({
    required String localId,
    this.cloudUid = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarSeed = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalCoins = const Value.absent(),
    this.gamesWon = const Value.absent(),
    this.totalMoves = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlayerProfileRow> custom({
    Expression<String>? localId,
    Expression<String>? cloudUid,
    Expression<String>? displayName,
    Expression<int>? avatarSeed,
    Expression<int>? totalXp,
    Expression<int>? totalCoins,
    Expression<int>? gamesWon,
    Expression<int>? totalMoves,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<String>? lastPlayedDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (cloudUid != null) 'cloud_uid': cloudUid,
      if (displayName != null) 'display_name': displayName,
      if (avatarSeed != null) 'avatar_seed': avatarSeed,
      if (totalXp != null) 'total_xp': totalXp,
      if (totalCoins != null) 'total_coins': totalCoins,
      if (gamesWon != null) 'games_won': gamesWon,
      if (totalMoves != null) 'total_moves': totalMoves,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (lastPlayedDate != null) 'last_played_date': lastPlayedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerProfilesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? cloudUid,
    Value<String>? displayName,
    Value<int>? avatarSeed,
    Value<int>? totalXp,
    Value<int>? totalCoins,
    Value<int>? gamesWon,
    Value<int>? totalMoves,
    Value<int>? currentStreak,
    Value<int>? longestStreak,
    Value<String?>? lastPlayedDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return PlayerProfilesCompanion(
      localId: localId ?? this.localId,
      cloudUid: cloudUid ?? this.cloudUid,
      displayName: displayName ?? this.displayName,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      totalXp: totalXp ?? this.totalXp,
      totalCoins: totalCoins ?? this.totalCoins,
      gamesWon: gamesWon ?? this.gamesWon,
      totalMoves: totalMoves ?? this.totalMoves,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (cloudUid.present) {
      map['cloud_uid'] = Variable<String>(cloudUid.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarSeed.present) {
      map['avatar_seed'] = Variable<int>(avatarSeed.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (totalCoins.present) {
      map['total_coins'] = Variable<int>(totalCoins.value);
    }
    if (gamesWon.present) {
      map['games_won'] = Variable<int>(gamesWon.value);
    }
    if (totalMoves.present) {
      map['total_moves'] = Variable<int>(totalMoves.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (lastPlayedDate.present) {
      map['last_played_date'] = Variable<String>(lastPlayedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerProfilesCompanion(')
          ..write('localId: $localId, ')
          ..write('cloudUid: $cloudUid, ')
          ..write('displayName: $displayName, ')
          ..write('avatarSeed: $avatarSeed, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalCoins: $totalCoins, ')
          ..write('gamesWon: $gamesWon, ')
          ..write('totalMoves: $totalMoves, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastPlayedDate: $lastPlayedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchesTable extends Matches with TableInfo<$MatchesTable, MatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerLocalIdMeta = const VerificationMeta(
    'playerLocalId',
  );
  @override
  late final GeneratedColumn<String> playerLocalId = GeneratedColumn<String>(
    'player_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES player_profiles (local_id)',
    ),
  );
  static const VerificationMeta _gameModeMeta = const VerificationMeta(
    'gameMode',
  );
  @override
  late final GeneratedColumn<String> gameMode = GeneratedColumn<String>(
    'game_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<int> moves = GeneratedColumn<int>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsElapsedMeta = const VerificationMeta(
    'secondsElapsed',
  );
  @override
  late final GeneratedColumn<int> secondsElapsed = GeneratedColumn<int>(
    'seconds_elapsed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeLimitMeta = const VerificationMeta(
    'timeLimit',
  );
  @override
  late final GeneratedColumn<int> timeLimit = GeneratedColumn<int>(
    'time_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coinsEarnedMeta = const VerificationMeta(
    'coinsEarned',
  );
  @override
  late final GeneratedColumn<int> coinsEarned = GeneratedColumn<int>(
    'coins_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wonMeta = const VerificationMeta('won');
  @override
  late final GeneratedColumn<bool> won = GeneratedColumn<bool>(
    'won',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("won" IN (0, 1))',
    ),
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<int> playedAt = GeneratedColumn<int>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelNumberMeta = const VerificationMeta(
    'levelNumber',
  );
  @override
  late final GeneratedColumn<int> levelNumber = GeneratedColumn<int>(
    'level_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($MatchesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playerLocalId,
    gameMode,
    score,
    moves,
    secondsElapsed,
    timeLimit,
    coinsEarned,
    xpEarned,
    won,
    playedAt,
    levelNumber,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('player_local_id')) {
      context.handle(
        _playerLocalIdMeta,
        playerLocalId.isAcceptableOrUnknown(
          data['player_local_id']!,
          _playerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerLocalIdMeta);
    }
    if (data.containsKey('game_mode')) {
      context.handle(
        _gameModeMeta,
        gameMode.isAcceptableOrUnknown(data['game_mode']!, _gameModeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameModeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    } else if (isInserting) {
      context.missing(_movesMeta);
    }
    if (data.containsKey('seconds_elapsed')) {
      context.handle(
        _secondsElapsedMeta,
        secondsElapsed.isAcceptableOrUnknown(
          data['seconds_elapsed']!,
          _secondsElapsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secondsElapsedMeta);
    }
    if (data.containsKey('time_limit')) {
      context.handle(
        _timeLimitMeta,
        timeLimit.isAcceptableOrUnknown(data['time_limit']!, _timeLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_timeLimitMeta);
    }
    if (data.containsKey('coins_earned')) {
      context.handle(
        _coinsEarnedMeta,
        coinsEarned.isAcceptableOrUnknown(
          data['coins_earned']!,
          _coinsEarnedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coinsEarnedMeta);
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    } else if (isInserting) {
      context.missing(_xpEarnedMeta);
    }
    if (data.containsKey('won')) {
      context.handle(
        _wonMeta,
        won.isAcceptableOrUnknown(data['won']!, _wonMeta),
      );
    } else if (isInserting) {
      context.missing(_wonMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('level_number')) {
      context.handle(
        _levelNumberMeta,
        levelNumber.isAcceptableOrUnknown(
          data['level_number']!,
          _levelNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      playerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_local_id'],
      )!,
      gameMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_mode'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moves'],
      )!,
      secondsElapsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds_elapsed'],
      )!,
      timeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_limit'],
      )!,
      coinsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins_earned'],
      )!,
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      won: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}won'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_at'],
      )!,
      levelNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_number'],
      ),
      syncStatus: $MatchesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class MatchRow extends DataClass implements Insertable<MatchRow> {
  final String id;
  final String playerLocalId;

  /// `solo`, `versus`, `daily_challenge`.
  final String gameMode;
  final int score;
  final int moves;
  final int secondsElapsed;
  final int timeLimit;
  final int coinsEarned;
  final int xpEarned;
  final bool won;

  /// Reloj local en milisegundos. La hora del servidor se registra aparte al
  /// sincronizar, para poder contrastarlas.
  final int playedAt;

  /// Nivel jugado, cuando la partida viene del mapa de niveles.
  final int? levelNumber;
  final SyncStatus syncStatus;
  const MatchRow({
    required this.id,
    required this.playerLocalId,
    required this.gameMode,
    required this.score,
    required this.moves,
    required this.secondsElapsed,
    required this.timeLimit,
    required this.coinsEarned,
    required this.xpEarned,
    required this.won,
    required this.playedAt,
    this.levelNumber,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['player_local_id'] = Variable<String>(playerLocalId);
    map['game_mode'] = Variable<String>(gameMode);
    map['score'] = Variable<int>(score);
    map['moves'] = Variable<int>(moves);
    map['seconds_elapsed'] = Variable<int>(secondsElapsed);
    map['time_limit'] = Variable<int>(timeLimit);
    map['coins_earned'] = Variable<int>(coinsEarned);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['won'] = Variable<bool>(won);
    map['played_at'] = Variable<int>(playedAt);
    if (!nullToAbsent || levelNumber != null) {
      map['level_number'] = Variable<int>(levelNumber);
    }
    {
      map['sync_status'] = Variable<String>(
        $MatchesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      playerLocalId: Value(playerLocalId),
      gameMode: Value(gameMode),
      score: Value(score),
      moves: Value(moves),
      secondsElapsed: Value(secondsElapsed),
      timeLimit: Value(timeLimit),
      coinsEarned: Value(coinsEarned),
      xpEarned: Value(xpEarned),
      won: Value(won),
      playedAt: Value(playedAt),
      levelNumber: levelNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(levelNumber),
      syncStatus: Value(syncStatus),
    );
  }

  factory MatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchRow(
      id: serializer.fromJson<String>(json['id']),
      playerLocalId: serializer.fromJson<String>(json['playerLocalId']),
      gameMode: serializer.fromJson<String>(json['gameMode']),
      score: serializer.fromJson<int>(json['score']),
      moves: serializer.fromJson<int>(json['moves']),
      secondsElapsed: serializer.fromJson<int>(json['secondsElapsed']),
      timeLimit: serializer.fromJson<int>(json['timeLimit']),
      coinsEarned: serializer.fromJson<int>(json['coinsEarned']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      won: serializer.fromJson<bool>(json['won']),
      playedAt: serializer.fromJson<int>(json['playedAt']),
      levelNumber: serializer.fromJson<int?>(json['levelNumber']),
      syncStatus: $MatchesTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playerLocalId': serializer.toJson<String>(playerLocalId),
      'gameMode': serializer.toJson<String>(gameMode),
      'score': serializer.toJson<int>(score),
      'moves': serializer.toJson<int>(moves),
      'secondsElapsed': serializer.toJson<int>(secondsElapsed),
      'timeLimit': serializer.toJson<int>(timeLimit),
      'coinsEarned': serializer.toJson<int>(coinsEarned),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'won': serializer.toJson<bool>(won),
      'playedAt': serializer.toJson<int>(playedAt),
      'levelNumber': serializer.toJson<int?>(levelNumber),
      'syncStatus': serializer.toJson<String>(
        $MatchesTable.$convertersyncStatus.toJson(syncStatus),
      ),
    };
  }

  MatchRow copyWith({
    String? id,
    String? playerLocalId,
    String? gameMode,
    int? score,
    int? moves,
    int? secondsElapsed,
    int? timeLimit,
    int? coinsEarned,
    int? xpEarned,
    bool? won,
    int? playedAt,
    Value<int?> levelNumber = const Value.absent(),
    SyncStatus? syncStatus,
  }) => MatchRow(
    id: id ?? this.id,
    playerLocalId: playerLocalId ?? this.playerLocalId,
    gameMode: gameMode ?? this.gameMode,
    score: score ?? this.score,
    moves: moves ?? this.moves,
    secondsElapsed: secondsElapsed ?? this.secondsElapsed,
    timeLimit: timeLimit ?? this.timeLimit,
    coinsEarned: coinsEarned ?? this.coinsEarned,
    xpEarned: xpEarned ?? this.xpEarned,
    won: won ?? this.won,
    playedAt: playedAt ?? this.playedAt,
    levelNumber: levelNumber.present ? levelNumber.value : this.levelNumber,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  MatchRow copyWithCompanion(MatchesCompanion data) {
    return MatchRow(
      id: data.id.present ? data.id.value : this.id,
      playerLocalId: data.playerLocalId.present
          ? data.playerLocalId.value
          : this.playerLocalId,
      gameMode: data.gameMode.present ? data.gameMode.value : this.gameMode,
      score: data.score.present ? data.score.value : this.score,
      moves: data.moves.present ? data.moves.value : this.moves,
      secondsElapsed: data.secondsElapsed.present
          ? data.secondsElapsed.value
          : this.secondsElapsed,
      timeLimit: data.timeLimit.present ? data.timeLimit.value : this.timeLimit,
      coinsEarned: data.coinsEarned.present
          ? data.coinsEarned.value
          : this.coinsEarned,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      won: data.won.present ? data.won.value : this.won,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      levelNumber: data.levelNumber.present
          ? data.levelNumber.value
          : this.levelNumber,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchRow(')
          ..write('id: $id, ')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('gameMode: $gameMode, ')
          ..write('score: $score, ')
          ..write('moves: $moves, ')
          ..write('secondsElapsed: $secondsElapsed, ')
          ..write('timeLimit: $timeLimit, ')
          ..write('coinsEarned: $coinsEarned, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('won: $won, ')
          ..write('playedAt: $playedAt, ')
          ..write('levelNumber: $levelNumber, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playerLocalId,
    gameMode,
    score,
    moves,
    secondsElapsed,
    timeLimit,
    coinsEarned,
    xpEarned,
    won,
    playedAt,
    levelNumber,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchRow &&
          other.id == this.id &&
          other.playerLocalId == this.playerLocalId &&
          other.gameMode == this.gameMode &&
          other.score == this.score &&
          other.moves == this.moves &&
          other.secondsElapsed == this.secondsElapsed &&
          other.timeLimit == this.timeLimit &&
          other.coinsEarned == this.coinsEarned &&
          other.xpEarned == this.xpEarned &&
          other.won == this.won &&
          other.playedAt == this.playedAt &&
          other.levelNumber == this.levelNumber &&
          other.syncStatus == this.syncStatus);
}

class MatchesCompanion extends UpdateCompanion<MatchRow> {
  final Value<String> id;
  final Value<String> playerLocalId;
  final Value<String> gameMode;
  final Value<int> score;
  final Value<int> moves;
  final Value<int> secondsElapsed;
  final Value<int> timeLimit;
  final Value<int> coinsEarned;
  final Value<int> xpEarned;
  final Value<bool> won;
  final Value<int> playedAt;
  final Value<int?> levelNumber;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.playerLocalId = const Value.absent(),
    this.gameMode = const Value.absent(),
    this.score = const Value.absent(),
    this.moves = const Value.absent(),
    this.secondsElapsed = const Value.absent(),
    this.timeLimit = const Value.absent(),
    this.coinsEarned = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.won = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.levelNumber = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCompanion.insert({
    required String id,
    required String playerLocalId,
    required String gameMode,
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required int coinsEarned,
    required int xpEarned,
    required bool won,
    required int playedAt,
    this.levelNumber = const Value.absent(),
    required SyncStatus syncStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       playerLocalId = Value(playerLocalId),
       gameMode = Value(gameMode),
       score = Value(score),
       moves = Value(moves),
       secondsElapsed = Value(secondsElapsed),
       timeLimit = Value(timeLimit),
       coinsEarned = Value(coinsEarned),
       xpEarned = Value(xpEarned),
       won = Value(won),
       playedAt = Value(playedAt),
       syncStatus = Value(syncStatus);
  static Insertable<MatchRow> custom({
    Expression<String>? id,
    Expression<String>? playerLocalId,
    Expression<String>? gameMode,
    Expression<int>? score,
    Expression<int>? moves,
    Expression<int>? secondsElapsed,
    Expression<int>? timeLimit,
    Expression<int>? coinsEarned,
    Expression<int>? xpEarned,
    Expression<bool>? won,
    Expression<int>? playedAt,
    Expression<int>? levelNumber,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerLocalId != null) 'player_local_id': playerLocalId,
      if (gameMode != null) 'game_mode': gameMode,
      if (score != null) 'score': score,
      if (moves != null) 'moves': moves,
      if (secondsElapsed != null) 'seconds_elapsed': secondsElapsed,
      if (timeLimit != null) 'time_limit': timeLimit,
      if (coinsEarned != null) 'coins_earned': coinsEarned,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (won != null) 'won': won,
      if (playedAt != null) 'played_at': playedAt,
      if (levelNumber != null) 'level_number': levelNumber,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? playerLocalId,
    Value<String>? gameMode,
    Value<int>? score,
    Value<int>? moves,
    Value<int>? secondsElapsed,
    Value<int>? timeLimit,
    Value<int>? coinsEarned,
    Value<int>? xpEarned,
    Value<bool>? won,
    Value<int>? playedAt,
    Value<int?>? levelNumber,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return MatchesCompanion(
      id: id ?? this.id,
      playerLocalId: playerLocalId ?? this.playerLocalId,
      gameMode: gameMode ?? this.gameMode,
      score: score ?? this.score,
      moves: moves ?? this.moves,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      timeLimit: timeLimit ?? this.timeLimit,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      xpEarned: xpEarned ?? this.xpEarned,
      won: won ?? this.won,
      playedAt: playedAt ?? this.playedAt,
      levelNumber: levelNumber ?? this.levelNumber,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playerLocalId.present) {
      map['player_local_id'] = Variable<String>(playerLocalId.value);
    }
    if (gameMode.present) {
      map['game_mode'] = Variable<String>(gameMode.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (moves.present) {
      map['moves'] = Variable<int>(moves.value);
    }
    if (secondsElapsed.present) {
      map['seconds_elapsed'] = Variable<int>(secondsElapsed.value);
    }
    if (timeLimit.present) {
      map['time_limit'] = Variable<int>(timeLimit.value);
    }
    if (coinsEarned.present) {
      map['coins_earned'] = Variable<int>(coinsEarned.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (won.present) {
      map['won'] = Variable<bool>(won.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<int>(playedAt.value);
    }
    if (levelNumber.present) {
      map['level_number'] = Variable<int>(levelNumber.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $MatchesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('gameMode: $gameMode, ')
          ..write('score: $score, ')
          ..write('moves: $moves, ')
          ..write('secondsElapsed: $secondsElapsed, ')
          ..write('timeLimit: $timeLimit, ')
          ..write('coinsEarned: $coinsEarned, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('won: $won, ')
          ..write('playedAt: $playedAt, ')
          ..write('levelNumber: $levelNumber, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelProgressTable extends LevelProgress
    with TableInfo<$LevelProgressTable, LevelProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerLocalIdMeta = const VerificationMeta(
    'playerLocalId',
  );
  @override
  late final GeneratedColumn<String> playerLocalId = GeneratedColumn<String>(
    'player_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES player_profiles (local_id)',
    ),
  );
  static const VerificationMeta _levelNumberMeta = const VerificationMeta(
    'levelNumber',
  );
  @override
  late final GeneratedColumn<int> levelNumber = GeneratedColumn<int>(
    'level_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  @override
  late final GeneratedColumn<int> bestScore = GeneratedColumn<int>(
    'best_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($LevelProgressTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    playerLocalId,
    levelNumber,
    isCompleted,
    bestScore,
    completedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_local_id')) {
      context.handle(
        _playerLocalIdMeta,
        playerLocalId.isAcceptableOrUnknown(
          data['player_local_id']!,
          _playerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerLocalIdMeta);
    }
    if (data.containsKey('level_number')) {
      context.handle(
        _levelNumberMeta,
        levelNumber.isAcceptableOrUnknown(
          data['level_number']!,
          _levelNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_levelNumberMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerLocalId, levelNumber};
  @override
  LevelProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelProgressRow(
      playerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_local_id'],
      )!,
      levelNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_number'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_score'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      syncStatus: $LevelProgressTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $LevelProgressTable createAlias(String alias) {
    return $LevelProgressTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class LevelProgressRow extends DataClass
    implements Insertable<LevelProgressRow> {
  final String playerLocalId;
  final int levelNumber;
  final bool isCompleted;
  final int bestScore;
  final int? completedAt;
  final SyncStatus syncStatus;
  const LevelProgressRow({
    required this.playerLocalId,
    required this.levelNumber,
    required this.isCompleted,
    required this.bestScore,
    this.completedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_local_id'] = Variable<String>(playerLocalId);
    map['level_number'] = Variable<int>(levelNumber);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['best_score'] = Variable<int>(bestScore);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $LevelProgressTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  LevelProgressCompanion toCompanion(bool nullToAbsent) {
    return LevelProgressCompanion(
      playerLocalId: Value(playerLocalId),
      levelNumber: Value(levelNumber),
      isCompleted: Value(isCompleted),
      bestScore: Value(bestScore),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LevelProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelProgressRow(
      playerLocalId: serializer.fromJson<String>(json['playerLocalId']),
      levelNumber: serializer.fromJson<int>(json['levelNumber']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      bestScore: serializer.fromJson<int>(json['bestScore']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      syncStatus: $LevelProgressTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerLocalId': serializer.toJson<String>(playerLocalId),
      'levelNumber': serializer.toJson<int>(levelNumber),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'bestScore': serializer.toJson<int>(bestScore),
      'completedAt': serializer.toJson<int?>(completedAt),
      'syncStatus': serializer.toJson<String>(
        $LevelProgressTable.$convertersyncStatus.toJson(syncStatus),
      ),
    };
  }

  LevelProgressRow copyWith({
    String? playerLocalId,
    int? levelNumber,
    bool? isCompleted,
    int? bestScore,
    Value<int?> completedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => LevelProgressRow(
    playerLocalId: playerLocalId ?? this.playerLocalId,
    levelNumber: levelNumber ?? this.levelNumber,
    isCompleted: isCompleted ?? this.isCompleted,
    bestScore: bestScore ?? this.bestScore,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LevelProgressRow copyWithCompanion(LevelProgressCompanion data) {
    return LevelProgressRow(
      playerLocalId: data.playerLocalId.present
          ? data.playerLocalId.value
          : this.playerLocalId,
      levelNumber: data.levelNumber.present
          ? data.levelNumber.value
          : this.levelNumber,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressRow(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('levelNumber: $levelNumber, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('bestScore: $bestScore, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playerLocalId,
    levelNumber,
    isCompleted,
    bestScore,
    completedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelProgressRow &&
          other.playerLocalId == this.playerLocalId &&
          other.levelNumber == this.levelNumber &&
          other.isCompleted == this.isCompleted &&
          other.bestScore == this.bestScore &&
          other.completedAt == this.completedAt &&
          other.syncStatus == this.syncStatus);
}

class LevelProgressCompanion extends UpdateCompanion<LevelProgressRow> {
  final Value<String> playerLocalId;
  final Value<int> levelNumber;
  final Value<bool> isCompleted;
  final Value<int> bestScore;
  final Value<int?> completedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const LevelProgressCompanion({
    this.playerLocalId = const Value.absent(),
    this.levelNumber = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelProgressCompanion.insert({
    required String playerLocalId,
    required int levelNumber,
    this.isCompleted = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.completedAt = const Value.absent(),
    required SyncStatus syncStatus,
    this.rowid = const Value.absent(),
  }) : playerLocalId = Value(playerLocalId),
       levelNumber = Value(levelNumber),
       syncStatus = Value(syncStatus);
  static Insertable<LevelProgressRow> custom({
    Expression<String>? playerLocalId,
    Expression<int>? levelNumber,
    Expression<bool>? isCompleted,
    Expression<int>? bestScore,
    Expression<int>? completedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerLocalId != null) 'player_local_id': playerLocalId,
      if (levelNumber != null) 'level_number': levelNumber,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (bestScore != null) 'best_score': bestScore,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelProgressCompanion copyWith({
    Value<String>? playerLocalId,
    Value<int>? levelNumber,
    Value<bool>? isCompleted,
    Value<int>? bestScore,
    Value<int?>? completedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return LevelProgressCompanion(
      playerLocalId: playerLocalId ?? this.playerLocalId,
      levelNumber: levelNumber ?? this.levelNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerLocalId.present) {
      map['player_local_id'] = Variable<String>(playerLocalId.value);
    }
    if (levelNumber.present) {
      map['level_number'] = Variable<int>(levelNumber.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<int>(bestScore.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $LevelProgressTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressCompanion(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('levelNumber: $levelNumber, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('bestScore: $bestScore, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyChallengeDefsTable extends DailyChallengeDefs
    with TableInfo<$DailyChallengeDefsTable, DailyChallengeDefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyChallengeDefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<String> challengeId = GeneratedColumn<String>(
    'challenge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _challengeDateMeta = const VerificationMeta(
    'challengeDate',
  );
  @override
  late final GeneratedColumn<String> challengeDate = GeneratedColumn<String>(
    'challenge_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    challengeId,
    challengeDate,
    payloadJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_challenge_defs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyChallengeDefRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeIdMeta);
    }
    if (data.containsKey('challenge_date')) {
      context.handle(
        _challengeDateMeta,
        challengeDate.isAcceptableOrUnknown(
          data['challenge_date']!,
          _challengeDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeDateMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {challengeId};
  @override
  DailyChallengeDefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyChallengeDefRow(
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_id'],
      )!,
      challengeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_date'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $DailyChallengeDefsTable createAlias(String alias) {
    return $DailyChallengeDefsTable(attachedDatabase, alias);
  }
}

class DailyChallengeDefRow extends DataClass
    implements Insertable<DailyChallengeDefRow> {
  final String challengeId;

  /// `'YYYY-MM-DD'` en zona local, para poder buscar el reto de hoy sin red.
  final String challengeDate;

  /// Contenido del reto tal cual llegó, sin interpretar. Guardarlo opaco
  /// permite añadir tipos de reto sin migrar el esquema local.
  final String payloadJson;
  final int cachedAt;
  const DailyChallengeDefRow({
    required this.challengeId,
    required this.challengeDate,
    required this.payloadJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['challenge_id'] = Variable<String>(challengeId);
    map['challenge_date'] = Variable<String>(challengeDate);
    map['payload_json'] = Variable<String>(payloadJson);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  DailyChallengeDefsCompanion toCompanion(bool nullToAbsent) {
    return DailyChallengeDefsCompanion(
      challengeId: Value(challengeId),
      challengeDate: Value(challengeDate),
      payloadJson: Value(payloadJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory DailyChallengeDefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyChallengeDefRow(
      challengeId: serializer.fromJson<String>(json['challengeId']),
      challengeDate: serializer.fromJson<String>(json['challengeDate']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'challengeId': serializer.toJson<String>(challengeId),
      'challengeDate': serializer.toJson<String>(challengeDate),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  DailyChallengeDefRow copyWith({
    String? challengeId,
    String? challengeDate,
    String? payloadJson,
    int? cachedAt,
  }) => DailyChallengeDefRow(
    challengeId: challengeId ?? this.challengeId,
    challengeDate: challengeDate ?? this.challengeDate,
    payloadJson: payloadJson ?? this.payloadJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  DailyChallengeDefRow copyWithCompanion(DailyChallengeDefsCompanion data) {
    return DailyChallengeDefRow(
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      challengeDate: data.challengeDate.present
          ? data.challengeDate.value
          : this.challengeDate,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengeDefRow(')
          ..write('challengeId: $challengeId, ')
          ..write('challengeDate: $challengeDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(challengeId, challengeDate, payloadJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyChallengeDefRow &&
          other.challengeId == this.challengeId &&
          other.challengeDate == this.challengeDate &&
          other.payloadJson == this.payloadJson &&
          other.cachedAt == this.cachedAt);
}

class DailyChallengeDefsCompanion
    extends UpdateCompanion<DailyChallengeDefRow> {
  final Value<String> challengeId;
  final Value<String> challengeDate;
  final Value<String> payloadJson;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const DailyChallengeDefsCompanion({
    this.challengeId = const Value.absent(),
    this.challengeDate = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyChallengeDefsCompanion.insert({
    required String challengeId,
    required String challengeDate,
    required String payloadJson,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : challengeId = Value(challengeId),
       challengeDate = Value(challengeDate),
       payloadJson = Value(payloadJson),
       cachedAt = Value(cachedAt);
  static Insertable<DailyChallengeDefRow> custom({
    Expression<String>? challengeId,
    Expression<String>? challengeDate,
    Expression<String>? payloadJson,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (challengeId != null) 'challenge_id': challengeId,
      if (challengeDate != null) 'challenge_date': challengeDate,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyChallengeDefsCompanion copyWith({
    Value<String>? challengeId,
    Value<String>? challengeDate,
    Value<String>? payloadJson,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return DailyChallengeDefsCompanion(
      challengeId: challengeId ?? this.challengeId,
      challengeDate: challengeDate ?? this.challengeDate,
      payloadJson: payloadJson ?? this.payloadJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (challengeId.present) {
      map['challenge_id'] = Variable<String>(challengeId.value);
    }
    if (challengeDate.present) {
      map['challenge_date'] = Variable<String>(challengeDate.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengeDefsCompanion(')
          ..write('challengeId: $challengeId, ')
          ..write('challengeDate: $challengeDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyChallengeProgressTable extends DailyChallengeProgress
    with TableInfo<$DailyChallengeProgressTable, DailyChallengeProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyChallengeProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerLocalIdMeta = const VerificationMeta(
    'playerLocalId',
  );
  @override
  late final GeneratedColumn<String> playerLocalId = GeneratedColumn<String>(
    'player_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES player_profiles (local_id)',
    ),
  );
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<String> challengeId = GeneratedColumn<String>(
    'challenge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>(
        $DailyChallengeProgressTable.$convertersyncStatus,
      );
  @override
  List<GeneratedColumn> get $columns => [
    playerLocalId,
    challengeId,
    completed,
    score,
    completedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_challenge_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyChallengeProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_local_id')) {
      context.handle(
        _playerLocalIdMeta,
        playerLocalId.isAcceptableOrUnknown(
          data['player_local_id']!,
          _playerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerLocalIdMeta);
    }
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeIdMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerLocalId, challengeId};
  @override
  DailyChallengeProgressRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyChallengeProgressRow(
      playerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_local_id'],
      )!,
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_id'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      syncStatus: $DailyChallengeProgressTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $DailyChallengeProgressTable createAlias(String alias) {
    return $DailyChallengeProgressTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class DailyChallengeProgressRow extends DataClass
    implements Insertable<DailyChallengeProgressRow> {
  final String playerLocalId;
  final String challengeId;
  final bool completed;
  final int score;
  final int? completedAt;
  final SyncStatus syncStatus;
  const DailyChallengeProgressRow({
    required this.playerLocalId,
    required this.challengeId,
    required this.completed,
    required this.score,
    this.completedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_local_id'] = Variable<String>(playerLocalId);
    map['challenge_id'] = Variable<String>(challengeId);
    map['completed'] = Variable<bool>(completed);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $DailyChallengeProgressTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  DailyChallengeProgressCompanion toCompanion(bool nullToAbsent) {
    return DailyChallengeProgressCompanion(
      playerLocalId: Value(playerLocalId),
      challengeId: Value(challengeId),
      completed: Value(completed),
      score: Value(score),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DailyChallengeProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyChallengeProgressRow(
      playerLocalId: serializer.fromJson<String>(json['playerLocalId']),
      challengeId: serializer.fromJson<String>(json['challengeId']),
      completed: serializer.fromJson<bool>(json['completed']),
      score: serializer.fromJson<int>(json['score']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      syncStatus: $DailyChallengeProgressTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerLocalId': serializer.toJson<String>(playerLocalId),
      'challengeId': serializer.toJson<String>(challengeId),
      'completed': serializer.toJson<bool>(completed),
      'score': serializer.toJson<int>(score),
      'completedAt': serializer.toJson<int?>(completedAt),
      'syncStatus': serializer.toJson<String>(
        $DailyChallengeProgressTable.$convertersyncStatus.toJson(syncStatus),
      ),
    };
  }

  DailyChallengeProgressRow copyWith({
    String? playerLocalId,
    String? challengeId,
    bool? completed,
    int? score,
    Value<int?> completedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => DailyChallengeProgressRow(
    playerLocalId: playerLocalId ?? this.playerLocalId,
    challengeId: challengeId ?? this.challengeId,
    completed: completed ?? this.completed,
    score: score ?? this.score,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DailyChallengeProgressRow copyWithCompanion(
    DailyChallengeProgressCompanion data,
  ) {
    return DailyChallengeProgressRow(
      playerLocalId: data.playerLocalId.present
          ? data.playerLocalId.value
          : this.playerLocalId,
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      completed: data.completed.present ? data.completed.value : this.completed,
      score: data.score.present ? data.score.value : this.score,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengeProgressRow(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('challengeId: $challengeId, ')
          ..write('completed: $completed, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playerLocalId,
    challengeId,
    completed,
    score,
    completedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyChallengeProgressRow &&
          other.playerLocalId == this.playerLocalId &&
          other.challengeId == this.challengeId &&
          other.completed == this.completed &&
          other.score == this.score &&
          other.completedAt == this.completedAt &&
          other.syncStatus == this.syncStatus);
}

class DailyChallengeProgressCompanion
    extends UpdateCompanion<DailyChallengeProgressRow> {
  final Value<String> playerLocalId;
  final Value<String> challengeId;
  final Value<bool> completed;
  final Value<int> score;
  final Value<int?> completedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const DailyChallengeProgressCompanion({
    this.playerLocalId = const Value.absent(),
    this.challengeId = const Value.absent(),
    this.completed = const Value.absent(),
    this.score = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyChallengeProgressCompanion.insert({
    required String playerLocalId,
    required String challengeId,
    this.completed = const Value.absent(),
    this.score = const Value.absent(),
    this.completedAt = const Value.absent(),
    required SyncStatus syncStatus,
    this.rowid = const Value.absent(),
  }) : playerLocalId = Value(playerLocalId),
       challengeId = Value(challengeId),
       syncStatus = Value(syncStatus);
  static Insertable<DailyChallengeProgressRow> custom({
    Expression<String>? playerLocalId,
    Expression<String>? challengeId,
    Expression<bool>? completed,
    Expression<int>? score,
    Expression<int>? completedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerLocalId != null) 'player_local_id': playerLocalId,
      if (challengeId != null) 'challenge_id': challengeId,
      if (completed != null) 'completed': completed,
      if (score != null) 'score': score,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyChallengeProgressCompanion copyWith({
    Value<String>? playerLocalId,
    Value<String>? challengeId,
    Value<bool>? completed,
    Value<int>? score,
    Value<int?>? completedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return DailyChallengeProgressCompanion(
      playerLocalId: playerLocalId ?? this.playerLocalId,
      challengeId: challengeId ?? this.challengeId,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerLocalId.present) {
      map['player_local_id'] = Variable<String>(playerLocalId.value);
    }
    if (challengeId.present) {
      map['challenge_id'] = Variable<String>(challengeId.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $DailyChallengeProgressTable.$convertersyncStatus.toSql(
          syncStatus.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengeProgressCompanion(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('challengeId: $challengeId, ')
          ..write('completed: $completed, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LivesStatesTable extends LivesStates
    with TableInfo<$LivesStatesTable, LivesStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LivesStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerLocalIdMeta = const VerificationMeta(
    'playerLocalId',
  );
  @override
  late final GeneratedColumn<String> playerLocalId = GeneratedColumn<String>(
    'player_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES player_profiles (local_id)',
    ),
  );
  static const VerificationMeta _currentLivesMeta = const VerificationMeta(
    'currentLives',
  );
  @override
  late final GeneratedColumn<int> currentLives = GeneratedColumn<int>(
    'current_lives',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRefillAtMeta = const VerificationMeta(
    'lastRefillAt',
  );
  @override
  late final GeneratedColumn<int> lastRefillAt = GeneratedColumn<int>(
    'last_refill_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playerLocalId,
    currentLives,
    lastRefillAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lives_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LivesStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_local_id')) {
      context.handle(
        _playerLocalIdMeta,
        playerLocalId.isAcceptableOrUnknown(
          data['player_local_id']!,
          _playerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerLocalIdMeta);
    }
    if (data.containsKey('current_lives')) {
      context.handle(
        _currentLivesMeta,
        currentLives.isAcceptableOrUnknown(
          data['current_lives']!,
          _currentLivesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentLivesMeta);
    }
    if (data.containsKey('last_refill_at')) {
      context.handle(
        _lastRefillAtMeta,
        lastRefillAt.isAcceptableOrUnknown(
          data['last_refill_at']!,
          _lastRefillAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastRefillAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerLocalId};
  @override
  LivesStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LivesStateRow(
      playerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_local_id'],
      )!,
      currentLives: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_lives'],
      )!,
      lastRefillAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_refill_at'],
      )!,
    );
  }

  @override
  $LivesStatesTable createAlias(String alias) {
    return $LivesStatesTable(attachedDatabase, alias);
  }
}

class LivesStateRow extends DataClass implements Insertable<LivesStateRow> {
  final String playerLocalId;
  final int currentLives;

  /// Instante de la última recarga, en milisegundos de reloj local.
  final int lastRefillAt;
  const LivesStateRow({
    required this.playerLocalId,
    required this.currentLives,
    required this.lastRefillAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_local_id'] = Variable<String>(playerLocalId);
    map['current_lives'] = Variable<int>(currentLives);
    map['last_refill_at'] = Variable<int>(lastRefillAt);
    return map;
  }

  LivesStatesCompanion toCompanion(bool nullToAbsent) {
    return LivesStatesCompanion(
      playerLocalId: Value(playerLocalId),
      currentLives: Value(currentLives),
      lastRefillAt: Value(lastRefillAt),
    );
  }

  factory LivesStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LivesStateRow(
      playerLocalId: serializer.fromJson<String>(json['playerLocalId']),
      currentLives: serializer.fromJson<int>(json['currentLives']),
      lastRefillAt: serializer.fromJson<int>(json['lastRefillAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerLocalId': serializer.toJson<String>(playerLocalId),
      'currentLives': serializer.toJson<int>(currentLives),
      'lastRefillAt': serializer.toJson<int>(lastRefillAt),
    };
  }

  LivesStateRow copyWith({
    String? playerLocalId,
    int? currentLives,
    int? lastRefillAt,
  }) => LivesStateRow(
    playerLocalId: playerLocalId ?? this.playerLocalId,
    currentLives: currentLives ?? this.currentLives,
    lastRefillAt: lastRefillAt ?? this.lastRefillAt,
  );
  LivesStateRow copyWithCompanion(LivesStatesCompanion data) {
    return LivesStateRow(
      playerLocalId: data.playerLocalId.present
          ? data.playerLocalId.value
          : this.playerLocalId,
      currentLives: data.currentLives.present
          ? data.currentLives.value
          : this.currentLives,
      lastRefillAt: data.lastRefillAt.present
          ? data.lastRefillAt.value
          : this.lastRefillAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LivesStateRow(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('currentLives: $currentLives, ')
          ..write('lastRefillAt: $lastRefillAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerLocalId, currentLives, lastRefillAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LivesStateRow &&
          other.playerLocalId == this.playerLocalId &&
          other.currentLives == this.currentLives &&
          other.lastRefillAt == this.lastRefillAt);
}

class LivesStatesCompanion extends UpdateCompanion<LivesStateRow> {
  final Value<String> playerLocalId;
  final Value<int> currentLives;
  final Value<int> lastRefillAt;
  final Value<int> rowid;
  const LivesStatesCompanion({
    this.playerLocalId = const Value.absent(),
    this.currentLives = const Value.absent(),
    this.lastRefillAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LivesStatesCompanion.insert({
    required String playerLocalId,
    required int currentLives,
    required int lastRefillAt,
    this.rowid = const Value.absent(),
  }) : playerLocalId = Value(playerLocalId),
       currentLives = Value(currentLives),
       lastRefillAt = Value(lastRefillAt);
  static Insertable<LivesStateRow> custom({
    Expression<String>? playerLocalId,
    Expression<int>? currentLives,
    Expression<int>? lastRefillAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerLocalId != null) 'player_local_id': playerLocalId,
      if (currentLives != null) 'current_lives': currentLives,
      if (lastRefillAt != null) 'last_refill_at': lastRefillAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LivesStatesCompanion copyWith({
    Value<String>? playerLocalId,
    Value<int>? currentLives,
    Value<int>? lastRefillAt,
    Value<int>? rowid,
  }) {
    return LivesStatesCompanion(
      playerLocalId: playerLocalId ?? this.playerLocalId,
      currentLives: currentLives ?? this.currentLives,
      lastRefillAt: lastRefillAt ?? this.lastRefillAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerLocalId.present) {
      map['player_local_id'] = Variable<String>(playerLocalId.value);
    }
    if (currentLives.present) {
      map['current_lives'] = Variable<int>(currentLives.value);
    }
    if (lastRefillAt.present) {
      map['last_refill_at'] = Variable<int>(lastRefillAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LivesStatesCompanion(')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('currentLives: $currentLives, ')
          ..write('lastRefillAt: $lastRefillAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTable extends SyncOperations
    with TableInfo<$SyncOperationsTable, SyncOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerLocalIdMeta = const VerificationMeta(
    'playerLocalId',
  );
  @override
  late final GeneratedColumn<String> playerLocalId = GeneratedColumn<String>(
    'player_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES player_profiles (local_id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOperationType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncOperationType>($SyncOperationsTable.$convertertype);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($SyncOperationsTable.$converterstatus);
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    playerLocalId,
    type,
    entityType,
    entityId,
    payloadJson,
    createdAt,
    status,
    retryCount,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('player_local_id')) {
      context.handle(
        _playerLocalIdMeta,
        playerLocalId.isAcceptableOrUnknown(
          data['player_local_id']!,
          _playerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerLocalIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  SyncOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperationRow(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      playerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_local_id'],
      )!,
      type: $SyncOperationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: $SyncOperationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOperationsTable createAlias(String alias) {
    return $SyncOperationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncOperationType, String, String> $convertertype =
      const EnumNameConverter<SyncOperationType>(SyncOperationType.values);
  static JsonTypeConverter2<SyncStatus, String, String> $converterstatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class SyncOperationRow extends DataClass
    implements Insertable<SyncOperationRow> {
  final String opId;
  final String playerLocalId;
  final SyncOperationType type;

  /// Qué se toca (`player`, `match`, `level`, `challenge`) y cuál.
  /// Permite descartar operaciones obsoletas sin interpretar el payload.
  final String entityType;
  final String entityId;

  /// Los deltas de la operación, serializados. Nunca totales.
  final String payloadJson;
  final int createdAt;
  final SyncStatus status;
  final int retryCount;

  /// Momento a partir del cual esta operación vuelve a ser elegible.
  /// Es el backoff exponencial, expresado como dato en vez de como espera.
  final int nextAttemptAt;
  final String? lastError;
  const SyncOperationRow({
    required this.opId,
    required this.playerLocalId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    required this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['player_local_id'] = Variable<String>(playerLocalId);
    {
      map['type'] = Variable<String>(
        $SyncOperationsTable.$convertertype.toSql(type),
      );
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<int>(createdAt);
    {
      map['status'] = Variable<String>(
        $SyncOperationsTable.$converterstatus.toSql(status),
      );
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsCompanion(
      opId: Value(opId),
      playerLocalId: Value(playerLocalId),
      type: Value(type),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      status: Value(status),
      retryCount: Value(retryCount),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperationRow(
      opId: serializer.fromJson<String>(json['opId']),
      playerLocalId: serializer.fromJson<String>(json['playerLocalId']),
      type: $SyncOperationsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      status: $SyncOperationsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'playerLocalId': serializer.toJson<String>(playerLocalId),
      'type': serializer.toJson<String>(
        $SyncOperationsTable.$convertertype.toJson(type),
      ),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<String>(
        $SyncOperationsTable.$converterstatus.toJson(status),
      ),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOperationRow copyWith({
    String? opId,
    String? playerLocalId,
    SyncOperationType? type,
    String? entityType,
    String? entityId,
    String? payloadJson,
    int? createdAt,
    SyncStatus? status,
    int? retryCount,
    int? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOperationRow(
    opId: opId ?? this.opId,
    playerLocalId: playerLocalId ?? this.playerLocalId,
    type: type ?? this.type,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOperationRow copyWithCompanion(SyncOperationsCompanion data) {
    return SyncOperationRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      playerLocalId: data.playerLocalId.present
          ? data.playerLocalId.value
          : this.playerLocalId,
      type: data.type.present ? data.type.value : this.type,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationRow(')
          ..write('opId: $opId, ')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('type: $type, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    playerLocalId,
    type,
    entityType,
    entityId,
    payloadJson,
    createdAt,
    status,
    retryCount,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperationRow &&
          other.opId == this.opId &&
          other.playerLocalId == this.playerLocalId &&
          other.type == this.type &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SyncOperationsCompanion extends UpdateCompanion<SyncOperationRow> {
  final Value<String> opId;
  final Value<String> playerLocalId;
  final Value<SyncOperationType> type;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payloadJson;
  final Value<int> createdAt;
  final Value<SyncStatus> status;
  final Value<int> retryCount;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOperationsCompanion({
    this.opId = const Value.absent(),
    this.playerLocalId = const Value.absent(),
    this.type = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationsCompanion.insert({
    required String opId,
    required String playerLocalId,
    required SyncOperationType type,
    required String entityType,
    required String entityId,
    required String payloadJson,
    required int createdAt,
    required SyncStatus status,
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       playerLocalId = Value(playerLocalId),
       type = Value(type),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<SyncOperationRow> custom({
    Expression<String>? opId,
    Expression<String>? playerLocalId,
    Expression<String>? type,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<int>? createdAt,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (playerLocalId != null) 'player_local_id': playerLocalId,
      if (type != null) 'type': type,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationsCompanion copyWith({
    Value<String>? opId,
    Value<String>? playerLocalId,
    Value<SyncOperationType>? type,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payloadJson,
    Value<int>? createdAt,
    Value<SyncStatus>? status,
    Value<int>? retryCount,
    Value<int>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOperationsCompanion(
      opId: opId ?? this.opId,
      playerLocalId: playerLocalId ?? this.playerLocalId,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (playerLocalId.present) {
      map['player_local_id'] = Variable<String>(playerLocalId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SyncOperationsTable.$convertertype.toSql(type.value),
      );
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncOperationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsCompanion(')
          ..write('opId: $opId, ')
          ..write('playerLocalId: $playerLocalId, ')
          ..write('type: $type, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayerProfilesTable playerProfiles = $PlayerProfilesTable(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $LevelProgressTable levelProgress = $LevelProgressTable(this);
  late final $DailyChallengeDefsTable dailyChallengeDefs =
      $DailyChallengeDefsTable(this);
  late final $DailyChallengeProgressTable dailyChallengeProgress =
      $DailyChallengeProgressTable(this);
  late final $LivesStatesTable livesStates = $LivesStatesTable(this);
  late final $SyncOperationsTable syncOperations = $SyncOperationsTable(this);
  late final Index idxMatchesPlayerPlayedAt = Index(
    'idx_matches_player_played_at',
    'CREATE INDEX idx_matches_player_played_at ON matches (player_local_id, played_at)',
  );
  late final Index idxMatchesSyncStatus = Index(
    'idx_matches_sync_status',
    'CREATE INDEX idx_matches_sync_status ON matches (sync_status)',
  );
  late final Index idxSyncOpsStatusNextAttempt = Index(
    'idx_sync_ops_status_next_attempt',
    'CREATE INDEX idx_sync_ops_status_next_attempt ON sync_operations (status, next_attempt_at)',
  );
  late final Index idxSyncOpsPlayerCreated = Index(
    'idx_sync_ops_player_created',
    'CREATE INDEX idx_sync_ops_player_created ON sync_operations (player_local_id, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    playerProfiles,
    matches,
    levelProgress,
    dailyChallengeDefs,
    dailyChallengeProgress,
    livesStates,
    syncOperations,
    idxMatchesPlayerPlayedAt,
    idxMatchesSyncStatus,
    idxSyncOpsStatusNextAttempt,
    idxSyncOpsPlayerCreated,
  ];
}

typedef $$PlayerProfilesTableCreateCompanionBuilder =
    PlayerProfilesCompanion Function({
      required String localId,
      Value<String?> cloudUid,
      Value<String> displayName,
      Value<int> avatarSeed,
      Value<int> totalXp,
      Value<int> totalCoins,
      Value<int> gamesWon,
      Value<int> totalMoves,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<String?> lastPlayedDate,
      required int createdAt,
      required int updatedAt,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$PlayerProfilesTableUpdateCompanionBuilder =
    PlayerProfilesCompanion Function({
      Value<String> localId,
      Value<String?> cloudUid,
      Value<String> displayName,
      Value<int> avatarSeed,
      Value<int> totalXp,
      Value<int> totalCoins,
      Value<int> gamesWon,
      Value<int> totalMoves,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<String?> lastPlayedDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> rowid,
    });

final class $$PlayerProfilesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlayerProfilesTable, PlayerProfileRow> {
  $$PlayerProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$MatchesTable, List<MatchRow>> _matchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.matches,
    aliasName: 'player_profiles__local_id__matches__player_local_id',
  );

  $$MatchesTableProcessedTableManager get matchesRefs {
    final manager = $$MatchesTableTableManager($_db, $_db.matches).filter(
      (f) =>
          f.playerLocalId.localId.sqlEquals($_itemColumn<String>('local_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_matchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LevelProgressTable, List<LevelProgressRow>>
  _levelProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.levelProgress,
    aliasName: 'player_profiles__local_id__level_progress__player_local_id',
  );

  $$LevelProgressTableProcessedTableManager get levelProgressRefs {
    final manager = $$LevelProgressTableTableManager($_db, $_db.levelProgress)
        .filter(
          (f) => f.playerLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_levelProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DailyChallengeProgressTable,
    List<DailyChallengeProgressRow>
  >
  _dailyChallengeProgressRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.dailyChallengeProgress,
    aliasName:
        'player_profiles__local_id__daily_challenge_progress__player_local_id',
  );

  $$DailyChallengeProgressTableProcessedTableManager
  get dailyChallengeProgressRefs {
    final manager =
        $$DailyChallengeProgressTableTableManager(
          $_db,
          $_db.dailyChallengeProgress,
        ).filter(
          (f) => f.playerLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _dailyChallengeProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LivesStatesTable, List<LivesStateRow>>
  _livesStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.livesStates,
    aliasName: 'player_profiles__local_id__lives_states__player_local_id',
  );

  $$LivesStatesTableProcessedTableManager get livesStatesRefs {
    final manager = $$LivesStatesTableTableManager($_db, $_db.livesStates)
        .filter(
          (f) => f.playerLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_livesStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncOperationsTable, List<SyncOperationRow>>
  _syncOperationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncOperations,
    aliasName: 'player_profiles__local_id__sync_operations__player_local_id',
  );

  $$SyncOperationsTableProcessedTableManager get syncOperationsRefs {
    final manager = $$SyncOperationsTableTableManager($_db, $_db.syncOperations)
        .filter(
          (f) => f.playerLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_syncOperationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudUid => $composableBuilder(
    column: $table.cloudUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarSeed => $composableBuilder(
    column: $table.avatarSeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCoins => $composableBuilder(
    column: $table.totalCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gamesWon => $composableBuilder(
    column: $table.gamesWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMoves => $composableBuilder(
    column: $table.totalMoves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> matchesRefs(
    Expression<bool> Function($$MatchesTableFilterComposer f) f,
  ) {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> levelProgressRefs(
    Expression<bool> Function($$LevelProgressTableFilterComposer f) f,
  ) {
    final $$LevelProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.levelProgress,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LevelProgressTableFilterComposer(
            $db: $db,
            $table: $db.levelProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dailyChallengeProgressRefs(
    Expression<bool> Function($$DailyChallengeProgressTableFilterComposer f) f,
  ) {
    final $$DailyChallengeProgressTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.dailyChallengeProgress,
          getReferencedColumn: (t) => t.playerLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyChallengeProgressTableFilterComposer(
                $db: $db,
                $table: $db.dailyChallengeProgress,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> livesStatesRefs(
    Expression<bool> Function($$LivesStatesTableFilterComposer f) f,
  ) {
    final $$LivesStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.livesStates,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivesStatesTableFilterComposer(
            $db: $db,
            $table: $db.livesStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncOperationsRefs(
    Expression<bool> Function($$SyncOperationsTableFilterComposer f) f,
  ) {
    final $$SyncOperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.syncOperations,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncOperationsTableFilterComposer(
            $db: $db,
            $table: $db.syncOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudUid => $composableBuilder(
    column: $table.cloudUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarSeed => $composableBuilder(
    column: $table.avatarSeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCoins => $composableBuilder(
    column: $table.totalCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gamesWon => $composableBuilder(
    column: $table.gamesWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMoves => $composableBuilder(
    column: $table.totalMoves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get cloudUid =>
      $composableBuilder(column: $table.cloudUid, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarSeed => $composableBuilder(
    column: $table.avatarSeed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get totalCoins => $composableBuilder(
    column: $table.totalCoins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gamesWon =>
      $composableBuilder(column: $table.gamesWon, builder: (column) => column);

  GeneratedColumn<int> get totalMoves => $composableBuilder(
    column: $table.totalMoves,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  Expression<T> matchesRefs<T extends Object>(
    Expression<T> Function($$MatchesTableAnnotationComposer a) f,
  ) {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> levelProgressRefs<T extends Object>(
    Expression<T> Function($$LevelProgressTableAnnotationComposer a) f,
  ) {
    final $$LevelProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.levelProgress,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LevelProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.levelProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dailyChallengeProgressRefs<T extends Object>(
    Expression<T> Function($$DailyChallengeProgressTableAnnotationComposer a) f,
  ) {
    final $$DailyChallengeProgressTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.dailyChallengeProgress,
          getReferencedColumn: (t) => t.playerLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyChallengeProgressTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyChallengeProgress,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> livesStatesRefs<T extends Object>(
    Expression<T> Function($$LivesStatesTableAnnotationComposer a) f,
  ) {
    final $$LivesStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.livesStates,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivesStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.livesStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncOperationsRefs<T extends Object>(
    Expression<T> Function($$SyncOperationsTableAnnotationComposer a) f,
  ) {
    final $$SyncOperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.syncOperations,
      getReferencedColumn: (t) => t.playerLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncOperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayerProfilesTable,
          PlayerProfileRow,
          $$PlayerProfilesTableFilterComposer,
          $$PlayerProfilesTableOrderingComposer,
          $$PlayerProfilesTableAnnotationComposer,
          $$PlayerProfilesTableCreateCompanionBuilder,
          $$PlayerProfilesTableUpdateCompanionBuilder,
          (PlayerProfileRow, $$PlayerProfilesTableReferences),
          PlayerProfileRow,
          PrefetchHooks Function({
            bool matchesRefs,
            bool levelProgressRefs,
            bool dailyChallengeProgressRefs,
            bool livesStatesRefs,
            bool syncOperationsRefs,
          })
        > {
  $$PlayerProfilesTableTableManager(
    _$AppDatabase db,
    $PlayerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> cloudUid = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> avatarSeed = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalCoins = const Value.absent(),
                Value<int> gamesWon = const Value.absent(),
                Value<int> totalMoves = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<String?> lastPlayedDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerProfilesCompanion(
                localId: localId,
                cloudUid: cloudUid,
                displayName: displayName,
                avatarSeed: avatarSeed,
                totalXp: totalXp,
                totalCoins: totalCoins,
                gamesWon: gamesWon,
                totalMoves: totalMoves,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> cloudUid = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> avatarSeed = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalCoins = const Value.absent(),
                Value<int> gamesWon = const Value.absent(),
                Value<int> totalMoves = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<String?> lastPlayedDate = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerProfilesCompanion.insert(
                localId: localId,
                cloudUid: cloudUid,
                displayName: displayName,
                avatarSeed: avatarSeed,
                totalXp: totalXp,
                totalCoins: totalCoins,
                gamesWon: gamesWon,
                totalMoves: totalMoves,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayerProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                matchesRefs = false,
                levelProgressRefs = false,
                dailyChallengeProgressRefs = false,
                livesStatesRefs = false,
                syncOperationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (matchesRefs) db.matches,
                    if (levelProgressRefs) db.levelProgress,
                    if (dailyChallengeProgressRefs) db.dailyChallengeProgress,
                    if (livesStatesRefs) db.livesStates,
                    if (syncOperationsRefs) db.syncOperations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (matchesRefs)
                        await $_getPrefetchedData<
                          PlayerProfileRow,
                          $PlayerProfilesTable,
                          MatchRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlayerProfilesTableReferences
                              ._matchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayerProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).matchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (levelProgressRefs)
                        await $_getPrefetchedData<
                          PlayerProfileRow,
                          $PlayerProfilesTable,
                          LevelProgressRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlayerProfilesTableReferences
                              ._levelProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayerProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).levelProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (dailyChallengeProgressRefs)
                        await $_getPrefetchedData<
                          PlayerProfileRow,
                          $PlayerProfilesTable,
                          DailyChallengeProgressRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlayerProfilesTableReferences
                              ._dailyChallengeProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayerProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyChallengeProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (livesStatesRefs)
                        await $_getPrefetchedData<
                          PlayerProfileRow,
                          $PlayerProfilesTable,
                          LivesStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlayerProfilesTableReferences
                              ._livesStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayerProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).livesStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (syncOperationsRefs)
                        await $_getPrefetchedData<
                          PlayerProfileRow,
                          $PlayerProfilesTable,
                          SyncOperationRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlayerProfilesTableReferences
                              ._syncOperationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayerProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).syncOperationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlayerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayerProfilesTable,
      PlayerProfileRow,
      $$PlayerProfilesTableFilterComposer,
      $$PlayerProfilesTableOrderingComposer,
      $$PlayerProfilesTableAnnotationComposer,
      $$PlayerProfilesTableCreateCompanionBuilder,
      $$PlayerProfilesTableUpdateCompanionBuilder,
      (PlayerProfileRow, $$PlayerProfilesTableReferences),
      PlayerProfileRow,
      PrefetchHooks Function({
        bool matchesRefs,
        bool levelProgressRefs,
        bool dailyChallengeProgressRefs,
        bool livesStatesRefs,
        bool syncOperationsRefs,
      })
    >;
typedef $$MatchesTableCreateCompanionBuilder =
    MatchesCompanion Function({
      required String id,
      required String playerLocalId,
      required String gameMode,
      required int score,
      required int moves,
      required int secondsElapsed,
      required int timeLimit,
      required int coinsEarned,
      required int xpEarned,
      required bool won,
      required int playedAt,
      Value<int?> levelNumber,
      required SyncStatus syncStatus,
      Value<int> rowid,
    });
typedef $$MatchesTableUpdateCompanionBuilder =
    MatchesCompanion Function({
      Value<String> id,
      Value<String> playerLocalId,
      Value<String> gameMode,
      Value<int> score,
      Value<int> moves,
      Value<int> secondsElapsed,
      Value<int> timeLimit,
      Value<int> coinsEarned,
      Value<int> xpEarned,
      Value<bool> won,
      Value<int> playedAt,
      Value<int?> levelNumber,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

final class $$MatchesTableReferences
    extends BaseReferences<_$AppDatabase, $MatchesTable, MatchRow> {
  $$MatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlayerProfilesTable _playerLocalIdTable(_$AppDatabase db) => db
      .playerProfiles
      .createAlias('matches__player_local_id__player_profiles__local_id');

  $$PlayerProfilesTableProcessedTableManager get playerLocalId {
    final $_column = $_itemColumn<String>('player_local_id')!;

    final manager = $$PlayerProfilesTableTableManager(
      $_db,
      $_db.playerProfiles,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
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

  ColumnFilters<String> get gameMode => $composableBuilder(
    column: $table.gameMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get secondsElapsed => $composableBuilder(
    column: $table.secondsElapsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeLimit => $composableBuilder(
    column: $table.timeLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinsEarned => $composableBuilder(
    column: $table.coinsEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get won => $composableBuilder(
    column: $table.won,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$PlayerProfilesTableFilterComposer get playerLocalId {
    final $$PlayerProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableFilterComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
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

  ColumnOrderings<String> get gameMode => $composableBuilder(
    column: $table.gameMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondsElapsed => $composableBuilder(
    column: $table.secondsElapsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeLimit => $composableBuilder(
    column: $table.timeLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinsEarned => $composableBuilder(
    column: $table.coinsEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get won => $composableBuilder(
    column: $table.won,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayerProfilesTableOrderingComposer get playerLocalId {
    final $$PlayerProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameMode =>
      $composableBuilder(column: $table.gameMode, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<int> get secondsElapsed => $composableBuilder(
    column: $table.secondsElapsed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeLimit =>
      $composableBuilder(column: $table.timeLimit, builder: (column) => column);

  GeneratedColumn<int> get coinsEarned => $composableBuilder(
    column: $table.coinsEarned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<bool> get won =>
      $composableBuilder(column: $table.won, builder: (column) => column);

  GeneratedColumn<int> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  $$PlayerProfilesTableAnnotationComposer get playerLocalId {
    final $$PlayerProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchesTable,
          MatchRow,
          $$MatchesTableFilterComposer,
          $$MatchesTableOrderingComposer,
          $$MatchesTableAnnotationComposer,
          $$MatchesTableCreateCompanionBuilder,
          $$MatchesTableUpdateCompanionBuilder,
          (MatchRow, $$MatchesTableReferences),
          MatchRow,
          PrefetchHooks Function({bool playerLocalId})
        > {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> playerLocalId = const Value.absent(),
                Value<String> gameMode = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> moves = const Value.absent(),
                Value<int> secondsElapsed = const Value.absent(),
                Value<int> timeLimit = const Value.absent(),
                Value<int> coinsEarned = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<bool> won = const Value.absent(),
                Value<int> playedAt = const Value.absent(),
                Value<int?> levelNumber = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion(
                id: id,
                playerLocalId: playerLocalId,
                gameMode: gameMode,
                score: score,
                moves: moves,
                secondsElapsed: secondsElapsed,
                timeLimit: timeLimit,
                coinsEarned: coinsEarned,
                xpEarned: xpEarned,
                won: won,
                playedAt: playedAt,
                levelNumber: levelNumber,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String playerLocalId,
                required String gameMode,
                required int score,
                required int moves,
                required int secondsElapsed,
                required int timeLimit,
                required int coinsEarned,
                required int xpEarned,
                required bool won,
                required int playedAt,
                Value<int?> levelNumber = const Value.absent(),
                required SyncStatus syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion.insert(
                id: id,
                playerLocalId: playerLocalId,
                gameMode: gameMode,
                score: score,
                moves: moves,
                secondsElapsed: secondsElapsed,
                timeLimit: timeLimit,
                coinsEarned: coinsEarned,
                xpEarned: xpEarned,
                won: won,
                playedAt: playedAt,
                levelNumber: levelNumber,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerLocalId = false}) {
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
                    if (playerLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerLocalId,
                                referencedTable: $$MatchesTableReferences
                                    ._playerLocalIdTable(db),
                                referencedColumn: $$MatchesTableReferences
                                    ._playerLocalIdTable(db)
                                    .localId,
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

typedef $$MatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchesTable,
      MatchRow,
      $$MatchesTableFilterComposer,
      $$MatchesTableOrderingComposer,
      $$MatchesTableAnnotationComposer,
      $$MatchesTableCreateCompanionBuilder,
      $$MatchesTableUpdateCompanionBuilder,
      (MatchRow, $$MatchesTableReferences),
      MatchRow,
      PrefetchHooks Function({bool playerLocalId})
    >;
typedef $$LevelProgressTableCreateCompanionBuilder =
    LevelProgressCompanion Function({
      required String playerLocalId,
      required int levelNumber,
      Value<bool> isCompleted,
      Value<int> bestScore,
      Value<int?> completedAt,
      required SyncStatus syncStatus,
      Value<int> rowid,
    });
typedef $$LevelProgressTableUpdateCompanionBuilder =
    LevelProgressCompanion Function({
      Value<String> playerLocalId,
      Value<int> levelNumber,
      Value<bool> isCompleted,
      Value<int> bestScore,
      Value<int?> completedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

final class $$LevelProgressTableReferences
    extends
        BaseReferences<_$AppDatabase, $LevelProgressTable, LevelProgressRow> {
  $$LevelProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayerProfilesTable _playerLocalIdTable(_$AppDatabase db) =>
      db.playerProfiles.createAlias(
        'level_progress__player_local_id__player_profiles__local_id',
      );

  $$PlayerProfilesTableProcessedTableManager get playerLocalId {
    final $_column = $_itemColumn<String>('player_local_id')!;

    final manager = $$PlayerProfilesTableTableManager(
      $_db,
      $_db.playerProfiles,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LevelProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$PlayerProfilesTableFilterComposer get playerLocalId {
    final $$PlayerProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableFilterComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LevelProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayerProfilesTableOrderingComposer get playerLocalId {
    final $$PlayerProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LevelProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get levelNumber => $composableBuilder(
    column: $table.levelNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  $$PlayerProfilesTableAnnotationComposer get playerLocalId {
    final $$PlayerProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LevelProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelProgressTable,
          LevelProgressRow,
          $$LevelProgressTableFilterComposer,
          $$LevelProgressTableOrderingComposer,
          $$LevelProgressTableAnnotationComposer,
          $$LevelProgressTableCreateCompanionBuilder,
          $$LevelProgressTableUpdateCompanionBuilder,
          (LevelProgressRow, $$LevelProgressTableReferences),
          LevelProgressRow,
          PrefetchHooks Function({bool playerLocalId})
        > {
  $$LevelProgressTableTableManager(_$AppDatabase db, $LevelProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playerLocalId = const Value.absent(),
                Value<int> levelNumber = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion(
                playerLocalId: playerLocalId,
                levelNumber: levelNumber,
                isCompleted: isCompleted,
                bestScore: bestScore,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playerLocalId,
                required int levelNumber,
                Value<bool> isCompleted = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                required SyncStatus syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion.insert(
                playerLocalId: playerLocalId,
                levelNumber: levelNumber,
                isCompleted: isCompleted,
                bestScore: bestScore,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LevelProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerLocalId = false}) {
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
                    if (playerLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerLocalId,
                                referencedTable: $$LevelProgressTableReferences
                                    ._playerLocalIdTable(db),
                                referencedColumn: $$LevelProgressTableReferences
                                    ._playerLocalIdTable(db)
                                    .localId,
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

typedef $$LevelProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelProgressTable,
      LevelProgressRow,
      $$LevelProgressTableFilterComposer,
      $$LevelProgressTableOrderingComposer,
      $$LevelProgressTableAnnotationComposer,
      $$LevelProgressTableCreateCompanionBuilder,
      $$LevelProgressTableUpdateCompanionBuilder,
      (LevelProgressRow, $$LevelProgressTableReferences),
      LevelProgressRow,
      PrefetchHooks Function({bool playerLocalId})
    >;
typedef $$DailyChallengeDefsTableCreateCompanionBuilder =
    DailyChallengeDefsCompanion Function({
      required String challengeId,
      required String challengeDate,
      required String payloadJson,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$DailyChallengeDefsTableUpdateCompanionBuilder =
    DailyChallengeDefsCompanion Function({
      Value<String> challengeId,
      Value<String> challengeDate,
      Value<String> payloadJson,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$DailyChallengeDefsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyChallengeDefsTable> {
  $$DailyChallengeDefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get challengeDate => $composableBuilder(
    column: $table.challengeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyChallengeDefsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyChallengeDefsTable> {
  $$DailyChallengeDefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get challengeDate => $composableBuilder(
    column: $table.challengeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyChallengeDefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyChallengeDefsTable> {
  $$DailyChallengeDefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get challengeDate => $composableBuilder(
    column: $table.challengeDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DailyChallengeDefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyChallengeDefsTable,
          DailyChallengeDefRow,
          $$DailyChallengeDefsTableFilterComposer,
          $$DailyChallengeDefsTableOrderingComposer,
          $$DailyChallengeDefsTableAnnotationComposer,
          $$DailyChallengeDefsTableCreateCompanionBuilder,
          $$DailyChallengeDefsTableUpdateCompanionBuilder,
          (
            DailyChallengeDefRow,
            BaseReferences<
              _$AppDatabase,
              $DailyChallengeDefsTable,
              DailyChallengeDefRow
            >,
          ),
          DailyChallengeDefRow,
          PrefetchHooks Function()
        > {
  $$DailyChallengeDefsTableTableManager(
    _$AppDatabase db,
    $DailyChallengeDefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyChallengeDefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyChallengeDefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyChallengeDefsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> challengeId = const Value.absent(),
                Value<String> challengeDate = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyChallengeDefsCompanion(
                challengeId: challengeId,
                challengeDate: challengeDate,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String challengeId,
                required String challengeDate,
                required String payloadJson,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyChallengeDefsCompanion.insert(
                challengeId: challengeId,
                challengeDate: challengeDate,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyChallengeDefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyChallengeDefsTable,
      DailyChallengeDefRow,
      $$DailyChallengeDefsTableFilterComposer,
      $$DailyChallengeDefsTableOrderingComposer,
      $$DailyChallengeDefsTableAnnotationComposer,
      $$DailyChallengeDefsTableCreateCompanionBuilder,
      $$DailyChallengeDefsTableUpdateCompanionBuilder,
      (
        DailyChallengeDefRow,
        BaseReferences<
          _$AppDatabase,
          $DailyChallengeDefsTable,
          DailyChallengeDefRow
        >,
      ),
      DailyChallengeDefRow,
      PrefetchHooks Function()
    >;
typedef $$DailyChallengeProgressTableCreateCompanionBuilder =
    DailyChallengeProgressCompanion Function({
      required String playerLocalId,
      required String challengeId,
      Value<bool> completed,
      Value<int> score,
      Value<int?> completedAt,
      required SyncStatus syncStatus,
      Value<int> rowid,
    });
typedef $$DailyChallengeProgressTableUpdateCompanionBuilder =
    DailyChallengeProgressCompanion Function({
      Value<String> playerLocalId,
      Value<String> challengeId,
      Value<bool> completed,
      Value<int> score,
      Value<int?> completedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

final class $$DailyChallengeProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DailyChallengeProgressTable,
          DailyChallengeProgressRow
        > {
  $$DailyChallengeProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayerProfilesTable _playerLocalIdTable(_$AppDatabase db) =>
      db.playerProfiles.createAlias(
        'daily_challenge_progress__player_local_id__player_profiles__local_id',
      );

  $$PlayerProfilesTableProcessedTableManager get playerLocalId {
    final $_column = $_itemColumn<String>('player_local_id')!;

    final manager = $$PlayerProfilesTableTableManager(
      $_db,
      $_db.playerProfiles,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyChallengeProgressTableFilterComposer
    extends Composer<_$AppDatabase, $DailyChallengeProgressTable> {
  $$DailyChallengeProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$PlayerProfilesTableFilterComposer get playerLocalId {
    final $$PlayerProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableFilterComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyChallengeProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyChallengeProgressTable> {
  $$DailyChallengeProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayerProfilesTableOrderingComposer get playerLocalId {
    final $$PlayerProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyChallengeProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyChallengeProgressTable> {
  $$DailyChallengeProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  $$PlayerProfilesTableAnnotationComposer get playerLocalId {
    final $$PlayerProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyChallengeProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyChallengeProgressTable,
          DailyChallengeProgressRow,
          $$DailyChallengeProgressTableFilterComposer,
          $$DailyChallengeProgressTableOrderingComposer,
          $$DailyChallengeProgressTableAnnotationComposer,
          $$DailyChallengeProgressTableCreateCompanionBuilder,
          $$DailyChallengeProgressTableUpdateCompanionBuilder,
          (DailyChallengeProgressRow, $$DailyChallengeProgressTableReferences),
          DailyChallengeProgressRow,
          PrefetchHooks Function({bool playerLocalId})
        > {
  $$DailyChallengeProgressTableTableManager(
    _$AppDatabase db,
    $DailyChallengeProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyChallengeProgressTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyChallengeProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyChallengeProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playerLocalId = const Value.absent(),
                Value<String> challengeId = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyChallengeProgressCompanion(
                playerLocalId: playerLocalId,
                challengeId: challengeId,
                completed: completed,
                score: score,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playerLocalId,
                required String challengeId,
                Value<bool> completed = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                required SyncStatus syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => DailyChallengeProgressCompanion.insert(
                playerLocalId: playerLocalId,
                challengeId: challengeId,
                completed: completed,
                score: score,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailyChallengeProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerLocalId = false}) {
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
                    if (playerLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerLocalId,
                                referencedTable:
                                    $$DailyChallengeProgressTableReferences
                                        ._playerLocalIdTable(db),
                                referencedColumn:
                                    $$DailyChallengeProgressTableReferences
                                        ._playerLocalIdTable(db)
                                        .localId,
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

typedef $$DailyChallengeProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyChallengeProgressTable,
      DailyChallengeProgressRow,
      $$DailyChallengeProgressTableFilterComposer,
      $$DailyChallengeProgressTableOrderingComposer,
      $$DailyChallengeProgressTableAnnotationComposer,
      $$DailyChallengeProgressTableCreateCompanionBuilder,
      $$DailyChallengeProgressTableUpdateCompanionBuilder,
      (DailyChallengeProgressRow, $$DailyChallengeProgressTableReferences),
      DailyChallengeProgressRow,
      PrefetchHooks Function({bool playerLocalId})
    >;
typedef $$LivesStatesTableCreateCompanionBuilder =
    LivesStatesCompanion Function({
      required String playerLocalId,
      required int currentLives,
      required int lastRefillAt,
      Value<int> rowid,
    });
typedef $$LivesStatesTableUpdateCompanionBuilder =
    LivesStatesCompanion Function({
      Value<String> playerLocalId,
      Value<int> currentLives,
      Value<int> lastRefillAt,
      Value<int> rowid,
    });

final class $$LivesStatesTableReferences
    extends BaseReferences<_$AppDatabase, $LivesStatesTable, LivesStateRow> {
  $$LivesStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlayerProfilesTable _playerLocalIdTable(_$AppDatabase db) => db
      .playerProfiles
      .createAlias('lives_states__player_local_id__player_profiles__local_id');

  $$PlayerProfilesTableProcessedTableManager get playerLocalId {
    final $_column = $_itemColumn<String>('player_local_id')!;

    final manager = $$PlayerProfilesTableTableManager(
      $_db,
      $_db.playerProfiles,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LivesStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LivesStatesTable> {
  $$LivesStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get currentLives => $composableBuilder(
    column: $table.currentLives,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRefillAt => $composableBuilder(
    column: $table.lastRefillAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayerProfilesTableFilterComposer get playerLocalId {
    final $$PlayerProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableFilterComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LivesStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LivesStatesTable> {
  $$LivesStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get currentLives => $composableBuilder(
    column: $table.currentLives,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRefillAt => $composableBuilder(
    column: $table.lastRefillAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayerProfilesTableOrderingComposer get playerLocalId {
    final $$PlayerProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LivesStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LivesStatesTable> {
  $$LivesStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get currentLives => $composableBuilder(
    column: $table.currentLives,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRefillAt => $composableBuilder(
    column: $table.lastRefillAt,
    builder: (column) => column,
  );

  $$PlayerProfilesTableAnnotationComposer get playerLocalId {
    final $$PlayerProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LivesStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LivesStatesTable,
          LivesStateRow,
          $$LivesStatesTableFilterComposer,
          $$LivesStatesTableOrderingComposer,
          $$LivesStatesTableAnnotationComposer,
          $$LivesStatesTableCreateCompanionBuilder,
          $$LivesStatesTableUpdateCompanionBuilder,
          (LivesStateRow, $$LivesStatesTableReferences),
          LivesStateRow,
          PrefetchHooks Function({bool playerLocalId})
        > {
  $$LivesStatesTableTableManager(_$AppDatabase db, $LivesStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LivesStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LivesStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LivesStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playerLocalId = const Value.absent(),
                Value<int> currentLives = const Value.absent(),
                Value<int> lastRefillAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LivesStatesCompanion(
                playerLocalId: playerLocalId,
                currentLives: currentLives,
                lastRefillAt: lastRefillAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playerLocalId,
                required int currentLives,
                required int lastRefillAt,
                Value<int> rowid = const Value.absent(),
              }) => LivesStatesCompanion.insert(
                playerLocalId: playerLocalId,
                currentLives: currentLives,
                lastRefillAt: lastRefillAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LivesStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerLocalId = false}) {
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
                    if (playerLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerLocalId,
                                referencedTable: $$LivesStatesTableReferences
                                    ._playerLocalIdTable(db),
                                referencedColumn: $$LivesStatesTableReferences
                                    ._playerLocalIdTable(db)
                                    .localId,
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

typedef $$LivesStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LivesStatesTable,
      LivesStateRow,
      $$LivesStatesTableFilterComposer,
      $$LivesStatesTableOrderingComposer,
      $$LivesStatesTableAnnotationComposer,
      $$LivesStatesTableCreateCompanionBuilder,
      $$LivesStatesTableUpdateCompanionBuilder,
      (LivesStateRow, $$LivesStatesTableReferences),
      LivesStateRow,
      PrefetchHooks Function({bool playerLocalId})
    >;
typedef $$SyncOperationsTableCreateCompanionBuilder =
    SyncOperationsCompanion Function({
      required String opId,
      required String playerLocalId,
      required SyncOperationType type,
      required String entityType,
      required String entityId,
      required String payloadJson,
      required int createdAt,
      required SyncStatus status,
      Value<int> retryCount,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncOperationsTableUpdateCompanionBuilder =
    SyncOperationsCompanion Function({
      Value<String> opId,
      Value<String> playerLocalId,
      Value<SyncOperationType> type,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payloadJson,
      Value<int> createdAt,
      Value<SyncStatus> status,
      Value<int> retryCount,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

final class $$SyncOperationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperationRow> {
  $$SyncOperationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayerProfilesTable _playerLocalIdTable(_$AppDatabase db) =>
      db.playerProfiles.createAlias(
        'sync_operations__player_local_id__player_profiles__local_id',
      );

  $$PlayerProfilesTableProcessedTableManager get playerLocalId {
    final $_column = $_itemColumn<String>('player_local_id')!;

    final manager = $$PlayerProfilesTableTableManager(
      $_db,
      $_db.playerProfiles,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOperationType, SyncOperationType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayerProfilesTableFilterComposer get playerLocalId {
    final $$PlayerProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableFilterComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayerProfilesTableOrderingComposer get playerLocalId {
    final $$PlayerProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncOperationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$PlayerProfilesTableAnnotationComposer get playerLocalId {
    final $$PlayerProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerLocalId,
      referencedTable: $db.playerProfiles,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.playerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOperationsTable,
          SyncOperationRow,
          $$SyncOperationsTableFilterComposer,
          $$SyncOperationsTableOrderingComposer,
          $$SyncOperationsTableAnnotationComposer,
          $$SyncOperationsTableCreateCompanionBuilder,
          $$SyncOperationsTableUpdateCompanionBuilder,
          (SyncOperationRow, $$SyncOperationsTableReferences),
          SyncOperationRow,
          PrefetchHooks Function({bool playerLocalId})
        > {
  $$SyncOperationsTableTableManager(
    _$AppDatabase db,
    $SyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> playerLocalId = const Value.absent(),
                Value<SyncOperationType> type = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<SyncStatus> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion(
                opId: opId,
                playerLocalId: playerLocalId,
                type: type,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String playerLocalId,
                required SyncOperationType type,
                required String entityType,
                required String entityId,
                required String payloadJson,
                required int createdAt,
                required SyncStatus status,
                Value<int> retryCount = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion.insert(
                opId: opId,
                playerLocalId: playerLocalId,
                type: type,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncOperationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerLocalId = false}) {
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
                    if (playerLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerLocalId,
                                referencedTable: $$SyncOperationsTableReferences
                                    ._playerLocalIdTable(db),
                                referencedColumn:
                                    $$SyncOperationsTableReferences
                                        ._playerLocalIdTable(db)
                                        .localId,
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

typedef $$SyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOperationsTable,
      SyncOperationRow,
      $$SyncOperationsTableFilterComposer,
      $$SyncOperationsTableOrderingComposer,
      $$SyncOperationsTableAnnotationComposer,
      $$SyncOperationsTableCreateCompanionBuilder,
      $$SyncOperationsTableUpdateCompanionBuilder,
      (SyncOperationRow, $$SyncOperationsTableReferences),
      SyncOperationRow,
      PrefetchHooks Function({bool playerLocalId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayerProfilesTableTableManager get playerProfiles =>
      $$PlayerProfilesTableTableManager(_db, _db.playerProfiles);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$LevelProgressTableTableManager get levelProgress =>
      $$LevelProgressTableTableManager(_db, _db.levelProgress);
  $$DailyChallengeDefsTableTableManager get dailyChallengeDefs =>
      $$DailyChallengeDefsTableTableManager(_db, _db.dailyChallengeDefs);
  $$DailyChallengeProgressTableTableManager get dailyChallengeProgress =>
      $$DailyChallengeProgressTableTableManager(
        _db,
        _db.dailyChallengeProgress,
      );
  $$LivesStatesTableTableManager get livesStates =>
      $$LivesStatesTableTableManager(_db, _db.livesStates);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(_db, _db.syncOperations);
}
