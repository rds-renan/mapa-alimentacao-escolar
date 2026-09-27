// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, unit, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }
}

class FoodItem extends DataClass implements Insertable<FoodItem> {
  final String id;
  final String name;
  final String unit;
  final bool active;
  const FoodItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['active'] = Variable<bool>(active);
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      active: Value(active),
    );
  }

  factory FoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'active': serializer.toJson<bool>(active),
    };
  }

  FoodItem copyWith({String? id, String? name, String? unit, bool? active}) =>
      FoodItem(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        active: active ?? this.active,
      );
  FoodItem copyWithCompanion(FoodItemsCompanion data) {
    return FoodItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unit, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.active == this.active);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> active;
  final Value<int> rowid;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    required String id,
    required String name,
    required String unit,
    required bool active,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       unit = Value(unit),
       active = Value(active);
  static Insertable<FoodItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? unit,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealMapsTable extends MealMaps with TableInfo<$MealMapsTable, MealMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealMapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mapDateMeta = const VerificationMeta(
    'mapDate',
  );
  @override
  late final GeneratedColumn<DateTime> mapDate = GeneratedColumn<DateTime>(
    'map_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonSchoolDayMeta = const VerificationMeta(
    'nonSchoolDay',
  );
  @override
  late final GeneratedColumn<bool> nonSchoolDay = GeneratedColumn<bool>(
    'non_school_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("non_school_day" IN (0, 1))',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealsServedMeta = const VerificationMeta(
    'mealsServed',
  );
  @override
  late final GeneratedColumn<int> mealsServed = GeneratedColumn<int>(
    'meals_served',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked" IN (0, 1))',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mapDate,
    nonSchoolDay,
    note,
    mealsServed,
    locked,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_maps';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealMap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('map_date')) {
      context.handle(
        _mapDateMeta,
        mapDate.isAcceptableOrUnknown(data['map_date']!, _mapDateMeta),
      );
    } else if (isInserting) {
      context.missing(_mapDateMeta);
    }
    if (data.containsKey('non_school_day')) {
      context.handle(
        _nonSchoolDayMeta,
        nonSchoolDay.isAcceptableOrUnknown(
          data['non_school_day']!,
          _nonSchoolDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nonSchoolDayMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('meals_served')) {
      context.handle(
        _mealsServedMeta,
        mealsServed.isAcceptableOrUnknown(
          data['meals_served']!,
          _mealsServedMeta,
        ),
      );
    }
    if (data.containsKey('locked')) {
      context.handle(
        _lockedMeta,
        locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta),
      );
    } else if (isInserting) {
      context.missing(_lockedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mapDate},
  ];
  @override
  MealMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealMap(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mapDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}map_date'],
      )!,
      nonSchoolDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}non_school_day'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      mealsServed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meals_served'],
      ),
      locked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealMapsTable createAlias(String alias) {
    return $MealMapsTable(attachedDatabase, alias);
  }
}

class MealMap extends DataClass implements Insertable<MealMap> {
  final String id;
  final DateTime mapDate;
  final bool nonSchoolDay;
  final String? note;
  final int? mealsServed;
  final bool locked;
  final DateTime updatedAt;
  const MealMap({
    required this.id,
    required this.mapDate,
    required this.nonSchoolDay,
    this.note,
    this.mealsServed,
    required this.locked,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['map_date'] = Variable<DateTime>(mapDate);
    map['non_school_day'] = Variable<bool>(nonSchoolDay);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || mealsServed != null) {
      map['meals_served'] = Variable<int>(mealsServed);
    }
    map['locked'] = Variable<bool>(locked);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealMapsCompanion toCompanion(bool nullToAbsent) {
    return MealMapsCompanion(
      id: Value(id),
      mapDate: Value(mapDate),
      nonSchoolDay: Value(nonSchoolDay),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      mealsServed: mealsServed == null && nullToAbsent
          ? const Value.absent()
          : Value(mealsServed),
      locked: Value(locked),
      updatedAt: Value(updatedAt),
    );
  }

  factory MealMap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealMap(
      id: serializer.fromJson<String>(json['id']),
      mapDate: serializer.fromJson<DateTime>(json['mapDate']),
      nonSchoolDay: serializer.fromJson<bool>(json['nonSchoolDay']),
      note: serializer.fromJson<String?>(json['note']),
      mealsServed: serializer.fromJson<int?>(json['mealsServed']),
      locked: serializer.fromJson<bool>(json['locked']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mapDate': serializer.toJson<DateTime>(mapDate),
      'nonSchoolDay': serializer.toJson<bool>(nonSchoolDay),
      'note': serializer.toJson<String?>(note),
      'mealsServed': serializer.toJson<int?>(mealsServed),
      'locked': serializer.toJson<bool>(locked),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MealMap copyWith({
    String? id,
    DateTime? mapDate,
    bool? nonSchoolDay,
    Value<String?> note = const Value.absent(),
    Value<int?> mealsServed = const Value.absent(),
    bool? locked,
    DateTime? updatedAt,
  }) => MealMap(
    id: id ?? this.id,
    mapDate: mapDate ?? this.mapDate,
    nonSchoolDay: nonSchoolDay ?? this.nonSchoolDay,
    note: note.present ? note.value : this.note,
    mealsServed: mealsServed.present ? mealsServed.value : this.mealsServed,
    locked: locked ?? this.locked,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MealMap copyWithCompanion(MealMapsCompanion data) {
    return MealMap(
      id: data.id.present ? data.id.value : this.id,
      mapDate: data.mapDate.present ? data.mapDate.value : this.mapDate,
      nonSchoolDay: data.nonSchoolDay.present
          ? data.nonSchoolDay.value
          : this.nonSchoolDay,
      note: data.note.present ? data.note.value : this.note,
      mealsServed: data.mealsServed.present
          ? data.mealsServed.value
          : this.mealsServed,
      locked: data.locked.present ? data.locked.value : this.locked,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealMap(')
          ..write('id: $id, ')
          ..write('mapDate: $mapDate, ')
          ..write('nonSchoolDay: $nonSchoolDay, ')
          ..write('note: $note, ')
          ..write('mealsServed: $mealsServed, ')
          ..write('locked: $locked, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mapDate,
    nonSchoolDay,
    note,
    mealsServed,
    locked,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealMap &&
          other.id == this.id &&
          other.mapDate == this.mapDate &&
          other.nonSchoolDay == this.nonSchoolDay &&
          other.note == this.note &&
          other.mealsServed == this.mealsServed &&
          other.locked == this.locked &&
          other.updatedAt == this.updatedAt);
}

class MealMapsCompanion extends UpdateCompanion<MealMap> {
  final Value<String> id;
  final Value<DateTime> mapDate;
  final Value<bool> nonSchoolDay;
  final Value<String?> note;
  final Value<int?> mealsServed;
  final Value<bool> locked;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MealMapsCompanion({
    this.id = const Value.absent(),
    this.mapDate = const Value.absent(),
    this.nonSchoolDay = const Value.absent(),
    this.note = const Value.absent(),
    this.mealsServed = const Value.absent(),
    this.locked = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealMapsCompanion.insert({
    required String id,
    required DateTime mapDate,
    required bool nonSchoolDay,
    this.note = const Value.absent(),
    this.mealsServed = const Value.absent(),
    required bool locked,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mapDate = Value(mapDate),
       nonSchoolDay = Value(nonSchoolDay),
       locked = Value(locked),
       updatedAt = Value(updatedAt);
  static Insertable<MealMap> custom({
    Expression<String>? id,
    Expression<DateTime>? mapDate,
    Expression<bool>? nonSchoolDay,
    Expression<String>? note,
    Expression<int>? mealsServed,
    Expression<bool>? locked,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mapDate != null) 'map_date': mapDate,
      if (nonSchoolDay != null) 'non_school_day': nonSchoolDay,
      if (note != null) 'note': note,
      if (mealsServed != null) 'meals_served': mealsServed,
      if (locked != null) 'locked': locked,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealMapsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? mapDate,
    Value<bool>? nonSchoolDay,
    Value<String?>? note,
    Value<int?>? mealsServed,
    Value<bool>? locked,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MealMapsCompanion(
      id: id ?? this.id,
      mapDate: mapDate ?? this.mapDate,
      nonSchoolDay: nonSchoolDay ?? this.nonSchoolDay,
      note: note ?? this.note,
      mealsServed: mealsServed ?? this.mealsServed,
      locked: locked ?? this.locked,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mapDate.present) {
      map['map_date'] = Variable<DateTime>(mapDate.value);
    }
    if (nonSchoolDay.present) {
      map['non_school_day'] = Variable<bool>(nonSchoolDay.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (mealsServed.present) {
      map['meals_served'] = Variable<int>(mealsServed.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealMapsCompanion(')
          ..write('id: $id, ')
          ..write('mapDate: $mapDate, ')
          ..write('nonSchoolDay: $nonSchoolDay, ')
          ..write('note: $note, ')
          ..write('mealsServed: $mealsServed, ')
          ..write('locked: $locked, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMapIdMeta = const VerificationMeta(
    'mealMapId',
  );
  @override
  late final GeneratedColumn<String> mealMapId = GeneratedColumn<String>(
    'meal_map_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meal_maps (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acceptanceMeta = const VerificationMeta(
    'acceptance',
  );
  @override
  late final GeneratedColumn<String> acceptance = GeneratedColumn<String>(
    'acceptance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealMapId,
    type,
    description,
    acceptance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_map_id')) {
      context.handle(
        _mealMapIdMeta,
        mealMapId.isAcceptableOrUnknown(data['meal_map_id']!, _mealMapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMapIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('acceptance')) {
      context.handle(
        _acceptanceMeta,
        acceptance.isAcceptableOrUnknown(data['acceptance']!, _acceptanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mealMapId, type},
  ];
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mealMapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_map_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      acceptance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acceptance'],
      ),
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final String id;
  final String mealMapId;
  final String type;
  final String? description;
  final String? acceptance;
  const Meal({
    required this.id,
    required this.mealMapId,
    required this.type,
    this.description,
    this.acceptance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_map_id'] = Variable<String>(mealMapId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || acceptance != null) {
      map['acceptance'] = Variable<String>(acceptance);
    }
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      mealMapId: Value(mealMapId),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      acceptance: acceptance == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptance),
    );
  }

  factory Meal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<String>(json['id']),
      mealMapId: serializer.fromJson<String>(json['mealMapId']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      acceptance: serializer.fromJson<String?>(json['acceptance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealMapId': serializer.toJson<String>(mealMapId),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'acceptance': serializer.toJson<String?>(acceptance),
    };
  }

  Meal copyWith({
    String? id,
    String? mealMapId,
    String? type,
    Value<String?> description = const Value.absent(),
    Value<String?> acceptance = const Value.absent(),
  }) => Meal(
    id: id ?? this.id,
    mealMapId: mealMapId ?? this.mealMapId,
    type: type ?? this.type,
    description: description.present ? description.value : this.description,
    acceptance: acceptance.present ? acceptance.value : this.acceptance,
  );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      mealMapId: data.mealMapId.present ? data.mealMapId.value : this.mealMapId,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      acceptance: data.acceptance.present
          ? data.acceptance.value
          : this.acceptance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('mealMapId: $mealMapId, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('acceptance: $acceptance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mealMapId, type, description, acceptance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.mealMapId == this.mealMapId &&
          other.type == this.type &&
          other.description == this.description &&
          other.acceptance == this.acceptance);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<String> id;
  final Value<String> mealMapId;
  final Value<String> type;
  final Value<String?> description;
  final Value<String?> acceptance;
  final Value<int> rowid;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.mealMapId = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.acceptance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsCompanion.insert({
    required String id,
    required String mealMapId,
    required String type,
    this.description = const Value.absent(),
    this.acceptance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mealMapId = Value(mealMapId),
       type = Value(type);
  static Insertable<Meal> custom({
    Expression<String>? id,
    Expression<String>? mealMapId,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? acceptance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealMapId != null) 'meal_map_id': mealMapId,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (acceptance != null) 'acceptance': acceptance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsCompanion copyWith({
    Value<String>? id,
    Value<String>? mealMapId,
    Value<String>? type,
    Value<String?>? description,
    Value<String?>? acceptance,
    Value<int>? rowid,
  }) {
    return MealsCompanion(
      id: id ?? this.id,
      mealMapId: mealMapId ?? this.mealMapId,
      type: type ?? this.type,
      description: description ?? this.description,
      acceptance: acceptance ?? this.acceptance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealMapId.present) {
      map['meal_map_id'] = Variable<String>(mealMapId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (acceptance.present) {
      map['acceptance'] = Variable<String>(acceptance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('mealMapId: $mealMapId, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('acceptance: $acceptance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMealMapsTable extends PendingMealMaps
    with TableInfo<$PendingMealMapsTable, PendingMealMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMealMapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mapDateMeta = const VerificationMeta(
    'mapDate',
  );
  @override
  late final GeneratedColumn<DateTime> mapDate = GeneratedColumn<DateTime>(
    'map_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _rejectionCodeMeta = const VerificationMeta(
    'rejectionCode',
  );
  @override
  late final GeneratedColumn<String> rejectionCode = GeneratedColumn<String>(
    'rejection_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectionMessageMeta = const VerificationMeta(
    'rejectionMessage',
  );
  @override
  late final GeneratedColumn<String> rejectionMessage = GeneratedColumn<String>(
    'rejection_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queuedAtMicrosMeta = const VerificationMeta(
    'queuedAtMicros',
  );
  @override
  late final GeneratedColumn<int> queuedAtMicros = GeneratedColumn<int>(
    'queued_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mapDate,
    payload,
    attempts,
    rejectionCode,
    rejectionMessage,
    queuedAtMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_meal_maps';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMealMap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('map_date')) {
      context.handle(
        _mapDateMeta,
        mapDate.isAcceptableOrUnknown(data['map_date']!, _mapDateMeta),
      );
    } else if (isInserting) {
      context.missing(_mapDateMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('rejection_code')) {
      context.handle(
        _rejectionCodeMeta,
        rejectionCode.isAcceptableOrUnknown(
          data['rejection_code']!,
          _rejectionCodeMeta,
        ),
      );
    }
    if (data.containsKey('rejection_message')) {
      context.handle(
        _rejectionMessageMeta,
        rejectionMessage.isAcceptableOrUnknown(
          data['rejection_message']!,
          _rejectionMessageMeta,
        ),
      );
    }
    if (data.containsKey('queued_at_micros')) {
      context.handle(
        _queuedAtMicrosMeta,
        queuedAtMicros.isAcceptableOrUnknown(
          data['queued_at_micros']!,
          _queuedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mapDate};
  @override
  PendingMealMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMealMap(
      mapDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}map_date'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      rejectionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejection_code'],
      ),
      rejectionMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejection_message'],
      ),
      queuedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queued_at_micros'],
      )!,
    );
  }

  @override
  $PendingMealMapsTable createAlias(String alias) {
    return $PendingMealMapsTable(attachedDatabase, alias);
  }
}

class PendingMealMap extends DataClass implements Insertable<PendingMealMap> {
  final DateTime mapDate;
  final String payload;

  /// Tentativas de envio seguidas sem sucesso. Comanda a espera até a
  /// próxima.
  final int attempts;

  /// Recusa que não se resolve reenviando. Enquanto existir, a fila não
  /// insiste — mas o dia continua aqui.
  final String? rejectionCode;
  final String? rejectionMessage;

  /// Quando entrou na fila, em microssegundos desde a época — um `int`, não
  /// um [DateTimeColumn], porque o armazenamento padrão do Drift trunca para
  /// o segundo, e dois dias diferentes gravados na mesma rodada de teste (ou
  /// no mesmo segundo de uso) empatariam e perderiam a ordem de envio.
  final int queuedAtMicros;
  const PendingMealMap({
    required this.mapDate,
    required this.payload,
    required this.attempts,
    this.rejectionCode,
    this.rejectionMessage,
    required this.queuedAtMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['map_date'] = Variable<DateTime>(mapDate);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || rejectionCode != null) {
      map['rejection_code'] = Variable<String>(rejectionCode);
    }
    if (!nullToAbsent || rejectionMessage != null) {
      map['rejection_message'] = Variable<String>(rejectionMessage);
    }
    map['queued_at_micros'] = Variable<int>(queuedAtMicros);
    return map;
  }

  PendingMealMapsCompanion toCompanion(bool nullToAbsent) {
    return PendingMealMapsCompanion(
      mapDate: Value(mapDate),
      payload: Value(payload),
      attempts: Value(attempts),
      rejectionCode: rejectionCode == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionCode),
      rejectionMessage: rejectionMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionMessage),
      queuedAtMicros: Value(queuedAtMicros),
    );
  }

  factory PendingMealMap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMealMap(
      mapDate: serializer.fromJson<DateTime>(json['mapDate']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      rejectionCode: serializer.fromJson<String?>(json['rejectionCode']),
      rejectionMessage: serializer.fromJson<String?>(json['rejectionMessage']),
      queuedAtMicros: serializer.fromJson<int>(json['queuedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mapDate': serializer.toJson<DateTime>(mapDate),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'rejectionCode': serializer.toJson<String?>(rejectionCode),
      'rejectionMessage': serializer.toJson<String?>(rejectionMessage),
      'queuedAtMicros': serializer.toJson<int>(queuedAtMicros),
    };
  }

  PendingMealMap copyWith({
    DateTime? mapDate,
    String? payload,
    int? attempts,
    Value<String?> rejectionCode = const Value.absent(),
    Value<String?> rejectionMessage = const Value.absent(),
    int? queuedAtMicros,
  }) => PendingMealMap(
    mapDate: mapDate ?? this.mapDate,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    rejectionCode: rejectionCode.present
        ? rejectionCode.value
        : this.rejectionCode,
    rejectionMessage: rejectionMessage.present
        ? rejectionMessage.value
        : this.rejectionMessage,
    queuedAtMicros: queuedAtMicros ?? this.queuedAtMicros,
  );
  PendingMealMap copyWithCompanion(PendingMealMapsCompanion data) {
    return PendingMealMap(
      mapDate: data.mapDate.present ? data.mapDate.value : this.mapDate,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      rejectionCode: data.rejectionCode.present
          ? data.rejectionCode.value
          : this.rejectionCode,
      rejectionMessage: data.rejectionMessage.present
          ? data.rejectionMessage.value
          : this.rejectionMessage,
      queuedAtMicros: data.queuedAtMicros.present
          ? data.queuedAtMicros.value
          : this.queuedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMealMap(')
          ..write('mapDate: $mapDate, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('rejectionCode: $rejectionCode, ')
          ..write('rejectionMessage: $rejectionMessage, ')
          ..write('queuedAtMicros: $queuedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mapDate,
    payload,
    attempts,
    rejectionCode,
    rejectionMessage,
    queuedAtMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMealMap &&
          other.mapDate == this.mapDate &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.rejectionCode == this.rejectionCode &&
          other.rejectionMessage == this.rejectionMessage &&
          other.queuedAtMicros == this.queuedAtMicros);
}

class PendingMealMapsCompanion extends UpdateCompanion<PendingMealMap> {
  final Value<DateTime> mapDate;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<String?> rejectionCode;
  final Value<String?> rejectionMessage;
  final Value<int> queuedAtMicros;
  final Value<int> rowid;
  const PendingMealMapsCompanion({
    this.mapDate = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rejectionCode = const Value.absent(),
    this.rejectionMessage = const Value.absent(),
    this.queuedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMealMapsCompanion.insert({
    required DateTime mapDate,
    required String payload,
    this.attempts = const Value.absent(),
    this.rejectionCode = const Value.absent(),
    this.rejectionMessage = const Value.absent(),
    required int queuedAtMicros,
    this.rowid = const Value.absent(),
  }) : mapDate = Value(mapDate),
       payload = Value(payload),
       queuedAtMicros = Value(queuedAtMicros);
  static Insertable<PendingMealMap> custom({
    Expression<DateTime>? mapDate,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<String>? rejectionCode,
    Expression<String>? rejectionMessage,
    Expression<int>? queuedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mapDate != null) 'map_date': mapDate,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (rejectionCode != null) 'rejection_code': rejectionCode,
      if (rejectionMessage != null) 'rejection_message': rejectionMessage,
      if (queuedAtMicros != null) 'queued_at_micros': queuedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMealMapsCompanion copyWith({
    Value<DateTime>? mapDate,
    Value<String>? payload,
    Value<int>? attempts,
    Value<String?>? rejectionCode,
    Value<String?>? rejectionMessage,
    Value<int>? queuedAtMicros,
    Value<int>? rowid,
  }) {
    return PendingMealMapsCompanion(
      mapDate: mapDate ?? this.mapDate,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      rejectionCode: rejectionCode ?? this.rejectionCode,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
      queuedAtMicros: queuedAtMicros ?? this.queuedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mapDate.present) {
      map['map_date'] = Variable<DateTime>(mapDate.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rejectionCode.present) {
      map['rejection_code'] = Variable<String>(rejectionCode.value);
    }
    if (rejectionMessage.present) {
      map['rejection_message'] = Variable<String>(rejectionMessage.value);
    }
    if (queuedAtMicros.present) {
      map['queued_at_micros'] = Variable<int>(queuedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMealMapsCompanion(')
          ..write('mapDate: $mapDate, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('rejectionCode: $rejectionCode, ')
          ..write('rejectionMessage: $rejectionMessage, ')
          ..write('queuedAtMicros: $queuedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $MealMapsTable mealMaps = $MealMapsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $PendingMealMapsTable pendingMealMaps = $PendingMealMapsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodItems,
    mealMaps,
    meals,
    pendingMealMaps,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_maps',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meals', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FoodItemsTableCreateCompanionBuilder = FoodItemsCompanion Function({
  required String id,
  required String name,
  required String unit,
  required bool active,
  Value<int> rowid,
});
typedef $$FoodItemsTableUpdateCompanionBuilder = FoodItemsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> unit,
  Value<bool> active,
  Value<int> rowid,
});

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$FoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemsTable,
          FoodItem,
          $$FoodItemsTableFilterComposer,
          $$FoodItemsTableOrderingComposer,
          $$FoodItemsTableAnnotationComposer,
          $$FoodItemsTableCreateCompanionBuilder,
          $$FoodItemsTableUpdateCompanionBuilder,
          (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
          FoodItem,
          PrefetchHooks Function()
        > {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion(
                id: id,
                name: name,
                unit: unit,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String unit,
                required bool active,
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion.insert(
                id: id,
                name: name,
                unit: unit,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodItemsTable, FoodItem>(table),
                  BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemsTable,
      FoodItem,
      $$FoodItemsTableFilterComposer,
      $$FoodItemsTableOrderingComposer,
      $$FoodItemsTableAnnotationComposer,
      $$FoodItemsTableCreateCompanionBuilder,
      $$FoodItemsTableUpdateCompanionBuilder,
      (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
      FoodItem,
      PrefetchHooks Function()
    >;
typedef $$MealMapsTableCreateCompanionBuilder = MealMapsCompanion Function({
  required String id,
  required DateTime mapDate,
  required bool nonSchoolDay,
  Value<String?> note,
  Value<int?> mealsServed,
  required bool locked,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$MealMapsTableUpdateCompanionBuilder = MealMapsCompanion Function({
  Value<String> id,
  Value<DateTime> mapDate,
  Value<bool> nonSchoolDay,
  Value<String?> note,
  Value<int?> mealsServed,
  Value<bool> locked,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$MealMapsTableReferences
    extends BaseReferences<_$AppDatabase, $MealMapsTable, MealMap> {
  $$MealMapsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealsTable, List<Meal>> _mealsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.meals,
    aliasName: 'meal_maps__id__meals__meal_map_id',
  );

  $$MealsTableProcessedTableManager get mealsRefs {
    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.mealMapId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealMapsTableFilterComposer
    extends Composer<_$AppDatabase, $MealMapsTable> {
  $$MealMapsTableFilterComposer({
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

  ColumnFilters<DateTime> get mapDate => $composableBuilder(
    column: $table.mapDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nonSchoolDay => $composableBuilder(
    column: $table.nonSchoolDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealsServed => $composableBuilder(
    column: $table.mealsServed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealsRefs(
    Expression<bool> Function($$MealsTableFilterComposer f) f,
  ) {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.mealMapId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableFilterComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealMapsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealMapsTable> {
  $$MealMapsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get mapDate => $composableBuilder(
    column: $table.mapDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nonSchoolDay => $composableBuilder(
    column: $table.nonSchoolDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealsServed => $composableBuilder(
    column: $table.mealsServed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealMapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealMapsTable> {
  $$MealMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get mapDate =>
      $composableBuilder(column: $table.mapDate, builder: (column) => column);

  GeneratedColumn<bool> get nonSchoolDay => $composableBuilder(
    column: $table.nonSchoolDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get mealsServed => $composableBuilder(
    column: $table.mealsServed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> mealsRefs<T extends Object>(
    Expression<T> Function($$MealsTableAnnotationComposer a) f,
  ) {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.mealMapId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableAnnotationComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealMapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealMapsTable,
          MealMap,
          $$MealMapsTableFilterComposer,
          $$MealMapsTableOrderingComposer,
          $$MealMapsTableAnnotationComposer,
          $$MealMapsTableCreateCompanionBuilder,
          $$MealMapsTableUpdateCompanionBuilder,
          (MealMap, $$MealMapsTableReferences),
          MealMap,
          PrefetchHooks Function({bool mealsRefs})
        > {
  $$MealMapsTableTableManager(_$AppDatabase db, $MealMapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealMapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealMapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealMapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> mapDate = const Value.absent(),
                Value<bool> nonSchoolDay = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> mealsServed = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealMapsCompanion(
                id: id,
                mapDate: mapDate,
                nonSchoolDay: nonSchoolDay,
                note: note,
                mealsServed: mealsServed,
                locked: locked,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime mapDate,
                required bool nonSchoolDay,
                Value<String?> note = const Value.absent(),
                Value<int?> mealsServed = const Value.absent(),
                required bool locked,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MealMapsCompanion.insert(
                id: id,
                mapDate: mapDate,
                nonSchoolDay: nonSchoolDay,
                note: note,
                mealsServed: mealsServed,
                locked: locked,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealMapsTable, MealMap>(table),
                  $$MealMapsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealsRefs) db.meals],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealsRefs)
                    await $_getPrefetchedData<MealMap, $MealMapsTable, Meal>(
                      currentTable: table,
                      referencedTable: $$MealMapsTableReferences
                          ._mealsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealMapsTableReferences(db, table, p0).mealsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mealMapId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealMapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealMapsTable,
      MealMap,
      $$MealMapsTableFilterComposer,
      $$MealMapsTableOrderingComposer,
      $$MealMapsTableAnnotationComposer,
      $$MealMapsTableCreateCompanionBuilder,
      $$MealMapsTableUpdateCompanionBuilder,
      (MealMap, $$MealMapsTableReferences),
      MealMap,
      PrefetchHooks Function({bool mealsRefs})
    >;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  required String id,
  required String mealMapId,
  required String type,
  Value<String?> description,
  Value<String?> acceptance,
  Value<int> rowid,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<String> id,
  Value<String> mealMapId,
  Value<String> type,
  Value<String?> description,
  Value<String?> acceptance,
  Value<int> rowid,
});

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealMapsTable _mealMapIdTable(_$AppDatabase db) =>
      db.mealMaps.createAlias('meals__meal_map_id__meal_maps__id');

  $$MealMapsTableProcessedTableManager get mealMapId {
    final $_column = $_itemColumn<String>('meal_map_id')!;

    final manager = $$MealMapsTableTableManager(
      $_db,
      $_db.mealMaps,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealMapIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptance => $composableBuilder(
    column: $table.acceptance,
    builder: (column) => ColumnFilters(column),
  );

  $$MealMapsTableFilterComposer get mealMapId {
    final $$MealMapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealMapId,
      referencedTable: $db.mealMaps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealMapsTableFilterComposer(
            $db: $db,
            $table: $db.mealMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptance => $composableBuilder(
    column: $table.acceptance,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealMapsTableOrderingComposer get mealMapId {
    final $$MealMapsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealMapId,
      referencedTable: $db.mealMaps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealMapsTableOrderingComposer(
            $db: $db,
            $table: $db.mealMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acceptance => $composableBuilder(
    column: $table.acceptance,
    builder: (column) => column,
  );

  $$MealMapsTableAnnotationComposer get mealMapId {
    final $$MealMapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealMapId,
      referencedTable: $db.mealMaps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealMapsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, $$MealsTableReferences),
          Meal,
          PrefetchHooks Function({bool mealMapId})
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mealMapId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> acceptance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion(
                id: id,
                mealMapId: mealMapId,
                type: type,
                description: description,
                acceptance: acceptance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mealMapId,
                required String type,
                Value<String?> description = const Value.absent(),
                Value<String?> acceptance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion.insert(
                id: id,
                mealMapId: mealMapId,
                type: type,
                description: description,
                acceptance: acceptance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealsTable, Meal>(table),
                  $$MealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealMapId = false}) {
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
                    if (mealMapId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mealMapId,
                        referencedTable: $$MealsTableReferences._mealMapIdTable(
                          db,
                        ),
                        referencedColumn: $$MealsTableReferences
                            ._mealMapIdTable(db)
                            .id,
                      ) as T;
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

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, $$MealsTableReferences),
      Meal,
      PrefetchHooks Function({bool mealMapId})
    >;
typedef $$PendingMealMapsTableCreateCompanionBuilder =
    PendingMealMapsCompanion Function({
      required DateTime mapDate,
      required String payload,
      Value<int> attempts,
      Value<String?> rejectionCode,
      Value<String?> rejectionMessage,
      required int queuedAtMicros,
      Value<int> rowid,
    });
typedef $$PendingMealMapsTableUpdateCompanionBuilder =
    PendingMealMapsCompanion Function({
      Value<DateTime> mapDate,
      Value<String> payload,
      Value<int> attempts,
      Value<String?> rejectionCode,
      Value<String?> rejectionMessage,
      Value<int> queuedAtMicros,
      Value<int> rowid,
    });

class $$PendingMealMapsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMealMapsTable> {
  $$PendingMealMapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get mapDate => $composableBuilder(
    column: $table.mapDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectionCode => $composableBuilder(
    column: $table.rejectionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectionMessage => $composableBuilder(
    column: $table.rejectionMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMealMapsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMealMapsTable> {
  $$PendingMealMapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get mapDate => $composableBuilder(
    column: $table.mapDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectionCode => $composableBuilder(
    column: $table.rejectionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectionMessage => $composableBuilder(
    column: $table.rejectionMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMealMapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMealMapsTable> {
  $$PendingMealMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get mapDate =>
      $composableBuilder(column: $table.mapDate, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get rejectionCode => $composableBuilder(
    column: $table.rejectionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rejectionMessage => $composableBuilder(
    column: $table.rejectionMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => column,
  );
}

class $$PendingMealMapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMealMapsTable,
          PendingMealMap,
          $$PendingMealMapsTableFilterComposer,
          $$PendingMealMapsTableOrderingComposer,
          $$PendingMealMapsTableAnnotationComposer,
          $$PendingMealMapsTableCreateCompanionBuilder,
          $$PendingMealMapsTableUpdateCompanionBuilder,
          (
            PendingMealMap,
            BaseReferences<
              _$AppDatabase,
              $PendingMealMapsTable,
              PendingMealMap
            >,
          ),
          PendingMealMap,
          PrefetchHooks Function()
        > {
  $$PendingMealMapsTableTableManager(
    _$AppDatabase db,
    $PendingMealMapsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMealMapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMealMapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMealMapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> mapDate = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> rejectionCode = const Value.absent(),
                Value<String?> rejectionMessage = const Value.absent(),
                Value<int> queuedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMealMapsCompanion(
                mapDate: mapDate,
                payload: payload,
                attempts: attempts,
                rejectionCode: rejectionCode,
                rejectionMessage: rejectionMessage,
                queuedAtMicros: queuedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime mapDate,
                required String payload,
                Value<int> attempts = const Value.absent(),
                Value<String?> rejectionCode = const Value.absent(),
                Value<String?> rejectionMessage = const Value.absent(),
                required int queuedAtMicros,
                Value<int> rowid = const Value.absent(),
              }) => PendingMealMapsCompanion.insert(
                mapDate: mapDate,
                payload: payload,
                attempts: attempts,
                rejectionCode: rejectionCode,
                rejectionMessage: rejectionMessage,
                queuedAtMicros: queuedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingMealMapsTable, PendingMealMap>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingMealMapsTable,
                    PendingMealMap
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMealMapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMealMapsTable,
      PendingMealMap,
      $$PendingMealMapsTableFilterComposer,
      $$PendingMealMapsTableOrderingComposer,
      $$PendingMealMapsTableAnnotationComposer,
      $$PendingMealMapsTableCreateCompanionBuilder,
      $$PendingMealMapsTableUpdateCompanionBuilder,
      (
        PendingMealMap,
        BaseReferences<_$AppDatabase, $PendingMealMapsTable, PendingMealMap>,
      ),
      PendingMealMap,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$MealMapsTableTableManager get mealMaps =>
      $$MealMapsTableTableManager(_db, _db.mealMaps);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$PendingMealMapsTableTableManager get pendingMealMaps =>
      $$PendingMealMapsTableTableManager(_db, _db.pendingMealMaps);
}
