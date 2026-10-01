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

class $MealFoodItemsTable extends MealFoodItems
    with TableInfo<$MealFoodItemsTable, MealFoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealFoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodItemIdMeta = const VerificationMeta(
    'foodItemId',
  );
  @override
  late final GeneratedColumn<String> foodItemId = GeneratedColumn<String>(
    'food_item_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mealId,
    position,
    foodItemId,
    name,
    unit,
    quantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealFoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('food_item_id')) {
      context.handle(
        _foodItemIdMeta,
        foodItemId.isAcceptableOrUnknown(
          data['food_item_id']!,
          _foodItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodItemIdMeta);
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
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mealId, foodItemId};
  @override
  MealFoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealFoodItem(
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      foodItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $MealFoodItemsTable createAlias(String alias) {
    return $MealFoodItemsTable(attachedDatabase, alias);
  }
}

class MealFoodItem extends DataClass implements Insertable<MealFoodItem> {
  final String mealId;
  final int position;
  final String foodItemId;
  final String name;
  final String? unit;
  final int quantity;
  const MealFoodItem({
    required this.mealId,
    required this.position,
    required this.foodItemId,
    required this.name,
    this.unit,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meal_id'] = Variable<String>(mealId);
    map['position'] = Variable<int>(position);
    map['food_item_id'] = Variable<String>(foodItemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  MealFoodItemsCompanion toCompanion(bool nullToAbsent) {
    return MealFoodItemsCompanion(
      mealId: Value(mealId),
      position: Value(position),
      foodItemId: Value(foodItemId),
      name: Value(name),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      quantity: Value(quantity),
    );
  }

  factory MealFoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealFoodItem(
      mealId: serializer.fromJson<String>(json['mealId']),
      position: serializer.fromJson<int>(json['position']),
      foodItemId: serializer.fromJson<String>(json['foodItemId']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String?>(json['unit']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mealId': serializer.toJson<String>(mealId),
      'position': serializer.toJson<int>(position),
      'foodItemId': serializer.toJson<String>(foodItemId),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String?>(unit),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  MealFoodItem copyWith({
    String? mealId,
    int? position,
    String? foodItemId,
    String? name,
    Value<String?> unit = const Value.absent(),
    int? quantity,
  }) => MealFoodItem(
    mealId: mealId ?? this.mealId,
    position: position ?? this.position,
    foodItemId: foodItemId ?? this.foodItemId,
    name: name ?? this.name,
    unit: unit.present ? unit.value : this.unit,
    quantity: quantity ?? this.quantity,
  );
  MealFoodItem copyWithCompanion(MealFoodItemsCompanion data) {
    return MealFoodItem(
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      position: data.position.present ? data.position.value : this.position,
      foodItemId: data.foodItemId.present
          ? data.foodItemId.value
          : this.foodItemId,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealFoodItem(')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(mealId, position, foodItemId, name, unit, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealFoodItem &&
          other.mealId == this.mealId &&
          other.position == this.position &&
          other.foodItemId == this.foodItemId &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.quantity == this.quantity);
}

class MealFoodItemsCompanion extends UpdateCompanion<MealFoodItem> {
  final Value<String> mealId;
  final Value<int> position;
  final Value<String> foodItemId;
  final Value<String> name;
  final Value<String?> unit;
  final Value<int> quantity;
  final Value<int> rowid;
  const MealFoodItemsCompanion({
    this.mealId = const Value.absent(),
    this.position = const Value.absent(),
    this.foodItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealFoodItemsCompanion.insert({
    required String mealId,
    required int position,
    required String foodItemId,
    required String name,
    this.unit = const Value.absent(),
    required int quantity,
    this.rowid = const Value.absent(),
  }) : mealId = Value(mealId),
       position = Value(position),
       foodItemId = Value(foodItemId),
       name = Value(name),
       quantity = Value(quantity);
  static Insertable<MealFoodItem> custom({
    Expression<String>? mealId,
    Expression<int>? position,
    Expression<String>? foodItemId,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mealId != null) 'meal_id': mealId,
      if (position != null) 'position': position,
      if (foodItemId != null) 'food_item_id': foodItemId,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealFoodItemsCompanion copyWith({
    Value<String>? mealId,
    Value<int>? position,
    Value<String>? foodItemId,
    Value<String>? name,
    Value<String?>? unit,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return MealFoodItemsCompanion(
      mealId: mealId ?? this.mealId,
      position: position ?? this.position,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (foodItemId.present) {
      map['food_item_id'] = Variable<String>(foodItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealFoodItemsCompanion(')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuChangesTable extends MenuChanges
    with TableInfo<$MenuChangesTable, MenuChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mealId, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuChange(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $MenuChangesTable createAlias(String alias) {
    return $MenuChangesTable(attachedDatabase, alias);
  }
}

class MenuChange extends DataClass implements Insertable<MenuChange> {
  final String id;
  final String mealId;
  final String reason;
  const MenuChange({
    required this.id,
    required this.mealId,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  MenuChangesCompanion toCompanion(bool nullToAbsent) {
    return MenuChangesCompanion(
      id: Value(id),
      mealId: Value(mealId),
      reason: Value(reason),
    );
  }

  factory MenuChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuChange(
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'reason': serializer.toJson<String>(reason),
    };
  }

  MenuChange copyWith({String? id, String? mealId, String? reason}) =>
      MenuChange(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        reason: reason ?? this.reason,
      );
  MenuChange copyWithCompanion(MenuChangesCompanion data) {
    return MenuChange(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuChange(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mealId, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuChange &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.reason == this.reason);
}

class MenuChangesCompanion extends UpdateCompanion<MenuChange> {
  final Value<String> id;
  final Value<String> mealId;
  final Value<String> reason;
  final Value<int> rowid;
  const MenuChangesCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuChangesCompanion.insert({
    required String id,
    required String mealId,
    required String reason,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mealId = Value(mealId),
       reason = Value(reason);
  static Insertable<MenuChange> custom({
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuChangesCompanion copyWith({
    Value<String>? id,
    Value<String>? mealId,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return MenuChangesCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuChangesCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuChangeFoodItemsTable extends MenuChangeFoodItems
    with TableInfo<$MenuChangeFoodItemsTable, MenuChangeFoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuChangeFoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _menuChangeIdMeta = const VerificationMeta(
    'menuChangeId',
  );
  @override
  late final GeneratedColumn<String> menuChangeId = GeneratedColumn<String>(
    'menu_change_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_changes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodItemIdMeta = const VerificationMeta(
    'foodItemId',
  );
  @override
  late final GeneratedColumn<String> foodItemId = GeneratedColumn<String>(
    'food_item_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    menuChangeId,
    position,
    foodItemId,
    name,
    unit,
    quantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_change_food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuChangeFoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('menu_change_id')) {
      context.handle(
        _menuChangeIdMeta,
        menuChangeId.isAcceptableOrUnknown(
          data['menu_change_id']!,
          _menuChangeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_menuChangeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('food_item_id')) {
      context.handle(
        _foodItemIdMeta,
        foodItemId.isAcceptableOrUnknown(
          data['food_item_id']!,
          _foodItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodItemIdMeta);
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
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {menuChangeId, foodItemId};
  @override
  MenuChangeFoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuChangeFoodItem(
      menuChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}menu_change_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      foodItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $MenuChangeFoodItemsTable createAlias(String alias) {
    return $MenuChangeFoodItemsTable(attachedDatabase, alias);
  }
}

class MenuChangeFoodItem extends DataClass
    implements Insertable<MenuChangeFoodItem> {
  final String menuChangeId;
  final int position;
  final String foodItemId;
  final String name;
  final String? unit;
  final int quantity;
  const MenuChangeFoodItem({
    required this.menuChangeId,
    required this.position,
    required this.foodItemId,
    required this.name,
    this.unit,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['menu_change_id'] = Variable<String>(menuChangeId);
    map['position'] = Variable<int>(position);
    map['food_item_id'] = Variable<String>(foodItemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  MenuChangeFoodItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuChangeFoodItemsCompanion(
      menuChangeId: Value(menuChangeId),
      position: Value(position),
      foodItemId: Value(foodItemId),
      name: Value(name),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      quantity: Value(quantity),
    );
  }

  factory MenuChangeFoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuChangeFoodItem(
      menuChangeId: serializer.fromJson<String>(json['menuChangeId']),
      position: serializer.fromJson<int>(json['position']),
      foodItemId: serializer.fromJson<String>(json['foodItemId']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String?>(json['unit']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'menuChangeId': serializer.toJson<String>(menuChangeId),
      'position': serializer.toJson<int>(position),
      'foodItemId': serializer.toJson<String>(foodItemId),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String?>(unit),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  MenuChangeFoodItem copyWith({
    String? menuChangeId,
    int? position,
    String? foodItemId,
    String? name,
    Value<String?> unit = const Value.absent(),
    int? quantity,
  }) => MenuChangeFoodItem(
    menuChangeId: menuChangeId ?? this.menuChangeId,
    position: position ?? this.position,
    foodItemId: foodItemId ?? this.foodItemId,
    name: name ?? this.name,
    unit: unit.present ? unit.value : this.unit,
    quantity: quantity ?? this.quantity,
  );
  MenuChangeFoodItem copyWithCompanion(MenuChangeFoodItemsCompanion data) {
    return MenuChangeFoodItem(
      menuChangeId: data.menuChangeId.present
          ? data.menuChangeId.value
          : this.menuChangeId,
      position: data.position.present ? data.position.value : this.position,
      foodItemId: data.foodItemId.present
          ? data.foodItemId.value
          : this.foodItemId,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuChangeFoodItem(')
          ..write('menuChangeId: $menuChangeId, ')
          ..write('position: $position, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(menuChangeId, position, foodItemId, name, unit, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuChangeFoodItem &&
          other.menuChangeId == this.menuChangeId &&
          other.position == this.position &&
          other.foodItemId == this.foodItemId &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.quantity == this.quantity);
}

class MenuChangeFoodItemsCompanion extends UpdateCompanion<MenuChangeFoodItem> {
  final Value<String> menuChangeId;
  final Value<int> position;
  final Value<String> foodItemId;
  final Value<String> name;
  final Value<String?> unit;
  final Value<int> quantity;
  final Value<int> rowid;
  const MenuChangeFoodItemsCompanion({
    this.menuChangeId = const Value.absent(),
    this.position = const Value.absent(),
    this.foodItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuChangeFoodItemsCompanion.insert({
    required String menuChangeId,
    required int position,
    required String foodItemId,
    required String name,
    this.unit = const Value.absent(),
    required int quantity,
    this.rowid = const Value.absent(),
  }) : menuChangeId = Value(menuChangeId),
       position = Value(position),
       foodItemId = Value(foodItemId),
       name = Value(name),
       quantity = Value(quantity);
  static Insertable<MenuChangeFoodItem> custom({
    Expression<String>? menuChangeId,
    Expression<int>? position,
    Expression<String>? foodItemId,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (menuChangeId != null) 'menu_change_id': menuChangeId,
      if (position != null) 'position': position,
      if (foodItemId != null) 'food_item_id': foodItemId,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuChangeFoodItemsCompanion copyWith({
    Value<String>? menuChangeId,
    Value<int>? position,
    Value<String>? foodItemId,
    Value<String>? name,
    Value<String?>? unit,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return MenuChangeFoodItemsCompanion(
      menuChangeId: menuChangeId ?? this.menuChangeId,
      position: position ?? this.position,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (menuChangeId.present) {
      map['menu_change_id'] = Variable<String>(menuChangeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (foodItemId.present) {
      map['food_item_id'] = Variable<String>(foodItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuChangeFoodItemsCompanion(')
          ..write('menuChangeId: $menuChangeId, ')
          ..write('position: $position, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
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

class $GeneratedDocumentsTable extends GeneratedDocuments
    with TableInfo<$GeneratedDocumentsTable, StoredDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datesMeta = const VerificationMeta('dates');
  @override
  late final GeneratedColumn<String> dates = GeneratedColumn<String>(
    'dates',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    requestedAt,
    completedAt,
    expiresAt,
    filePath,
    fileName,
    dates,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
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
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('dates')) {
      context.handle(
        _datesMeta,
        dates.isAcceptableOrUnknown(data['dates']!, _datesMeta),
      );
    } else if (isInserting) {
      context.missing(_datesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      dates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dates'],
      )!,
    );
  }

  @override
  $GeneratedDocumentsTable createAlias(String alias) {
    return $GeneratedDocumentsTable(attachedDatabase, alias);
  }
}

class StoredDocument extends DataClass implements Insertable<StoredDocument> {
  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? filePath;
  final String? fileName;
  final String dates;
  const StoredDocument({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.expiresAt,
    this.filePath,
    this.fileName,
    required this.dates,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    map['dates'] = Variable<String>(dates);
    return map;
  }

  GeneratedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return GeneratedDocumentsCompanion(
      id: Value(id),
      status: Value(status),
      requestedAt: Value(requestedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      dates: Value(dates),
    );
  }

  factory StoredDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredDocument(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      dates: serializer.fromJson<String>(json['dates']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'filePath': serializer.toJson<String?>(filePath),
      'fileName': serializer.toJson<String?>(fileName),
      'dates': serializer.toJson<String>(dates),
    };
  }

  StoredDocument copyWith({
    String? id,
    String? status,
    DateTime? requestedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    String? dates,
  }) => StoredDocument(
    id: id ?? this.id,
    status: status ?? this.status,
    requestedAt: requestedAt ?? this.requestedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    filePath: filePath.present ? filePath.value : this.filePath,
    fileName: fileName.present ? fileName.value : this.fileName,
    dates: dates ?? this.dates,
  );
  StoredDocument copyWithCompanion(GeneratedDocumentsCompanion data) {
    return StoredDocument(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      dates: data.dates.present ? data.dates.value : this.dates,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredDocument(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('dates: $dates')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    requestedAt,
    completedAt,
    expiresAt,
    filePath,
    fileName,
    dates,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredDocument &&
          other.id == this.id &&
          other.status == this.status &&
          other.requestedAt == this.requestedAt &&
          other.completedAt == this.completedAt &&
          other.expiresAt == this.expiresAt &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.dates == this.dates);
}

class GeneratedDocumentsCompanion extends UpdateCompanion<StoredDocument> {
  final Value<String> id;
  final Value<String> status;
  final Value<DateTime> requestedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> expiresAt;
  final Value<String?> filePath;
  final Value<String?> fileName;
  final Value<String> dates;
  final Value<int> rowid;
  const GeneratedDocumentsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.dates = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneratedDocumentsCompanion.insert({
    required String id,
    required String status,
    required DateTime requestedAt,
    this.completedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    required String dates,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       requestedAt = Value(requestedAt),
       dates = Value(dates);
  static Insertable<StoredDocument> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? dates,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (dates != null) 'dates': dates,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneratedDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<DateTime>? requestedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? expiresAt,
    Value<String?>? filePath,
    Value<String?>? fileName,
    Value<String>? dates,
    Value<int>? rowid,
  }) {
    return GeneratedDocumentsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      dates: dates ?? this.dates,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (dates.present) {
      map['dates'] = Variable<String>(dates.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('dates: $dates, ')
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
  late final $MealFoodItemsTable mealFoodItems = $MealFoodItemsTable(this);
  late final $MenuChangesTable menuChanges = $MenuChangesTable(this);
  late final $MenuChangeFoodItemsTable menuChangeFoodItems =
      $MenuChangeFoodItemsTable(this);
  late final $PendingMealMapsTable pendingMealMaps = $PendingMealMapsTable(
    this,
  );
  late final $GeneratedDocumentsTable generatedDocuments =
      $GeneratedDocumentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodItems,
    mealMaps,
    meals,
    mealFoodItems,
    menuChanges,
    menuChangeFoodItems,
    pendingMealMaps,
    generatedDocuments,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meal_food_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('menu_changes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'menu_changes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('menu_change_food_items', kind: UpdateKind.delete)],
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

  static MultiTypedResultKey<$MealFoodItemsTable, List<MealFoodItem>>
  _mealFoodItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mealFoodItems,
    aliasName: 'meals__id__meal_food_items__meal_id',
  );

  $$MealFoodItemsTableProcessedTableManager get mealFoodItemsRefs {
    final manager = $$MealFoodItemsTableTableManager(
      $_db,
      $_db.mealFoodItems,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealFoodItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MenuChangesTable, List<MenuChange>>
  _menuChangesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.menuChanges,
    aliasName: 'meals__id__menu_changes__meal_id',
  );

  $$MenuChangesTableProcessedTableManager get menuChangesRefs {
    final manager = $$MenuChangesTableTableManager(
      $_db,
      $_db.menuChanges,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_menuChangesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> mealFoodItemsRefs(
    Expression<bool> Function($$MealFoodItemsTableFilterComposer f) f,
  ) {
    final $$MealFoodItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealFoodItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealFoodItemsTableFilterComposer(
            $db: $db,
            $table: $db.mealFoodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> menuChangesRefs(
    Expression<bool> Function($$MenuChangesTableFilterComposer f) f,
  ) {
    final $$MenuChangesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuChanges,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangesTableFilterComposer(
            $db: $db,
            $table: $db.menuChanges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> mealFoodItemsRefs<T extends Object>(
    Expression<T> Function($$MealFoodItemsTableAnnotationComposer a) f,
  ) {
    final $$MealFoodItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealFoodItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealFoodItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealFoodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> menuChangesRefs<T extends Object>(
    Expression<T> Function($$MenuChangesTableAnnotationComposer a) f,
  ) {
    final $$MenuChangesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuChanges,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangesTableAnnotationComposer(
            $db: $db,
            $table: $db.menuChanges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({
            bool mealMapId,
            bool mealFoodItemsRefs,
            bool menuChangesRefs,
          })
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
          prefetchHooksCallback:
              ({
                mealMapId = false,
                mealFoodItemsRefs = false,
                menuChangesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mealFoodItemsRefs) db.mealFoodItems,
                    if (menuChangesRefs) db.menuChanges,
                  ],
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
                            referencedTable: $$MealsTableReferences
                                ._mealMapIdTable(db),
                            referencedColumn: $$MealsTableReferences
                                ._mealMapIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mealFoodItemsRefs)
                        await $_getPrefetchedData<
                          Meal,
                          $MealsTable,
                          MealFoodItem
                        >(
                          currentTable: table,
                          referencedTable: $$MealsTableReferences
                              ._mealFoodItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MealsTableReferences(
                                db,
                                table,
                                p0,
                              ).mealFoodItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mealId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (menuChangesRefs)
                        await $_getPrefetchedData<
                          Meal,
                          $MealsTable,
                          MenuChange
                        >(
                          currentTable: table,
                          referencedTable: $$MealsTableReferences
                              ._menuChangesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MealsTableReferences(
                                db,
                                table,
                                p0,
                              ).menuChangesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mealId == item.id,
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
      PrefetchHooks Function({
        bool mealMapId,
        bool mealFoodItemsRefs,
        bool menuChangesRefs,
      })
    >;
typedef $$MealFoodItemsTableCreateCompanionBuilder =
    MealFoodItemsCompanion Function({
      required String mealId,
      required int position,
      required String foodItemId,
      required String name,
      Value<String?> unit,
      required int quantity,
      Value<int> rowid,
    });
typedef $$MealFoodItemsTableUpdateCompanionBuilder =
    MealFoodItemsCompanion Function({
      Value<String> mealId,
      Value<int> position,
      Value<String> foodItemId,
      Value<String> name,
      Value<String?> unit,
      Value<int> quantity,
      Value<int> rowid,
    });

final class $$MealFoodItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MealFoodItemsTable, MealFoodItem> {
  $$MealFoodItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MealsTable _mealIdTable(_$AppDatabase db) =>
      db.meals.createAlias('meal_food_items__meal_id__meals__id');

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealFoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealFoodItemsTable> {
  $$MealFoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
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

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$MealFoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealFoodItemsTable> {
  $$MealFoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
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

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableOrderingComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealFoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealFoodItemsTable> {
  $$MealFoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$MealFoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealFoodItemsTable,
          MealFoodItem,
          $$MealFoodItemsTableFilterComposer,
          $$MealFoodItemsTableOrderingComposer,
          $$MealFoodItemsTableAnnotationComposer,
          $$MealFoodItemsTableCreateCompanionBuilder,
          $$MealFoodItemsTableUpdateCompanionBuilder,
          (MealFoodItem, $$MealFoodItemsTableReferences),
          MealFoodItem,
          PrefetchHooks Function({bool mealId})
        > {
  $$MealFoodItemsTableTableManager(_$AppDatabase db, $MealFoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealFoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealFoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealFoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mealId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> foodItemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealFoodItemsCompanion(
                mealId: mealId,
                position: position,
                foodItemId: foodItemId,
                name: name,
                unit: unit,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mealId,
                required int position,
                required String foodItemId,
                required String name,
                Value<String?> unit = const Value.absent(),
                required int quantity,
                Value<int> rowid = const Value.absent(),
              }) => MealFoodItemsCompanion.insert(
                mealId: mealId,
                position: position,
                foodItemId: foodItemId,
                name: name,
                unit: unit,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealFoodItemsTable, MealFoodItem>(table),
                  $$MealFoodItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealId = false}) {
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
                    if (mealId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mealId,
                        referencedTable: $$MealFoodItemsTableReferences
                            ._mealIdTable(db),
                        referencedColumn: $$MealFoodItemsTableReferences
                            ._mealIdTable(db)
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

typedef $$MealFoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealFoodItemsTable,
      MealFoodItem,
      $$MealFoodItemsTableFilterComposer,
      $$MealFoodItemsTableOrderingComposer,
      $$MealFoodItemsTableAnnotationComposer,
      $$MealFoodItemsTableCreateCompanionBuilder,
      $$MealFoodItemsTableUpdateCompanionBuilder,
      (MealFoodItem, $$MealFoodItemsTableReferences),
      MealFoodItem,
      PrefetchHooks Function({bool mealId})
    >;
typedef $$MenuChangesTableCreateCompanionBuilder =
    MenuChangesCompanion Function({
      required String id,
      required String mealId,
      required String reason,
      Value<int> rowid,
    });
typedef $$MenuChangesTableUpdateCompanionBuilder =
    MenuChangesCompanion Function({
      Value<String> id,
      Value<String> mealId,
      Value<String> reason,
      Value<int> rowid,
    });

final class $$MenuChangesTableReferences
    extends BaseReferences<_$AppDatabase, $MenuChangesTable, MenuChange> {
  $$MenuChangesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealsTable _mealIdTable(_$AppDatabase db) =>
      db.meals.createAlias('menu_changes__meal_id__meals__id');

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MenuChangeFoodItemsTable,
    List<MenuChangeFoodItem>
  >
  _menuChangeFoodItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.menuChangeFoodItems,
        aliasName: 'menu_changes__id__menu_change_food_items__menu_change_id',
      );

  $$MenuChangeFoodItemsTableProcessedTableManager get menuChangeFoodItemsRefs {
    final manager = $$MenuChangeFoodItemsTableTableManager(
      $_db,
      $_db.menuChangeFoodItems,
    ).filter((f) => f.menuChangeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _menuChangeFoodItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MenuChangesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuChangesTable> {
  $$MenuChangesTableFilterComposer({
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

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> menuChangeFoodItemsRefs(
    Expression<bool> Function($$MenuChangeFoodItemsTableFilterComposer f) f,
  ) {
    final $$MenuChangeFoodItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuChangeFoodItems,
      getReferencedColumn: (t) => t.menuChangeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangeFoodItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuChangeFoodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuChangesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuChangesTable> {
  $$MenuChangesTableOrderingComposer({
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

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableOrderingComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuChangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuChangesTable> {
  $$MenuChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> menuChangeFoodItemsRefs<T extends Object>(
    Expression<T> Function($$MenuChangeFoodItemsTableAnnotationComposer a) f,
  ) {
    final $$MenuChangeFoodItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.menuChangeFoodItems,
          getReferencedColumn: (t) => t.menuChangeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MenuChangeFoodItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.menuChangeFoodItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MenuChangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuChangesTable,
          MenuChange,
          $$MenuChangesTableFilterComposer,
          $$MenuChangesTableOrderingComposer,
          $$MenuChangesTableAnnotationComposer,
          $$MenuChangesTableCreateCompanionBuilder,
          $$MenuChangesTableUpdateCompanionBuilder,
          (MenuChange, $$MenuChangesTableReferences),
          MenuChange,
          PrefetchHooks Function({bool mealId, bool menuChangeFoodItemsRefs})
        > {
  $$MenuChangesTableTableManager(_$AppDatabase db, $MenuChangesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuChangesCompanion(
                id: id,
                mealId: mealId,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mealId,
                required String reason,
                Value<int> rowid = const Value.absent(),
              }) => MenuChangesCompanion.insert(
                id: id,
                mealId: mealId,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MenuChangesTable, MenuChange>(table),
                  $$MenuChangesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mealId = false, menuChangeFoodItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (menuChangeFoodItemsRefs) db.menuChangeFoodItems,
                  ],
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
                        if (mealId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.mealId,
                            referencedTable: $$MenuChangesTableReferences
                                ._mealIdTable(db),
                            referencedColumn: $$MenuChangesTableReferences
                                ._mealIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (menuChangeFoodItemsRefs)
                        await $_getPrefetchedData<
                          MenuChange,
                          $MenuChangesTable,
                          MenuChangeFoodItem
                        >(
                          currentTable: table,
                          referencedTable: $$MenuChangesTableReferences
                              ._menuChangeFoodItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MenuChangesTableReferences(
                                db,
                                table,
                                p0,
                              ).menuChangeFoodItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.menuChangeId == item.id,
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

typedef $$MenuChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuChangesTable,
      MenuChange,
      $$MenuChangesTableFilterComposer,
      $$MenuChangesTableOrderingComposer,
      $$MenuChangesTableAnnotationComposer,
      $$MenuChangesTableCreateCompanionBuilder,
      $$MenuChangesTableUpdateCompanionBuilder,
      (MenuChange, $$MenuChangesTableReferences),
      MenuChange,
      PrefetchHooks Function({bool mealId, bool menuChangeFoodItemsRefs})
    >;
typedef $$MenuChangeFoodItemsTableCreateCompanionBuilder =
    MenuChangeFoodItemsCompanion Function({
      required String menuChangeId,
      required int position,
      required String foodItemId,
      required String name,
      Value<String?> unit,
      required int quantity,
      Value<int> rowid,
    });
typedef $$MenuChangeFoodItemsTableUpdateCompanionBuilder =
    MenuChangeFoodItemsCompanion Function({
      Value<String> menuChangeId,
      Value<int> position,
      Value<String> foodItemId,
      Value<String> name,
      Value<String?> unit,
      Value<int> quantity,
      Value<int> rowid,
    });

final class $$MenuChangeFoodItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MenuChangeFoodItemsTable,
          MenuChangeFoodItem
        > {
  $$MenuChangeFoodItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MenuChangesTable _menuChangeIdTable(_$AppDatabase db) => db
      .menuChanges
      .createAlias('menu_change_food_items__menu_change_id__menu_changes__id');

  $$MenuChangesTableProcessedTableManager get menuChangeId {
    final $_column = $_itemColumn<String>('menu_change_id')!;

    final manager = $$MenuChangesTableTableManager(
      $_db,
      $_db.menuChanges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_menuChangeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MenuChangeFoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MenuChangeFoodItemsTable> {
  $$MenuChangeFoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
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

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  $$MenuChangesTableFilterComposer get menuChangeId {
    final $$MenuChangesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuChangeId,
      referencedTable: $db.menuChanges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangesTableFilterComposer(
            $db: $db,
            $table: $db.menuChanges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuChangeFoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuChangeFoodItemsTable> {
  $$MenuChangeFoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
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

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$MenuChangesTableOrderingComposer get menuChangeId {
    final $$MenuChangesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuChangeId,
      referencedTable: $db.menuChanges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangesTableOrderingComposer(
            $db: $db,
            $table: $db.menuChanges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuChangeFoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuChangeFoodItemsTable> {
  $$MenuChangeFoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$MenuChangesTableAnnotationComposer get menuChangeId {
    final $$MenuChangesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuChangeId,
      referencedTable: $db.menuChanges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuChangesTableAnnotationComposer(
            $db: $db,
            $table: $db.menuChanges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuChangeFoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuChangeFoodItemsTable,
          MenuChangeFoodItem,
          $$MenuChangeFoodItemsTableFilterComposer,
          $$MenuChangeFoodItemsTableOrderingComposer,
          $$MenuChangeFoodItemsTableAnnotationComposer,
          $$MenuChangeFoodItemsTableCreateCompanionBuilder,
          $$MenuChangeFoodItemsTableUpdateCompanionBuilder,
          (MenuChangeFoodItem, $$MenuChangeFoodItemsTableReferences),
          MenuChangeFoodItem,
          PrefetchHooks Function({bool menuChangeId})
        > {
  $$MenuChangeFoodItemsTableTableManager(
    _$AppDatabase db,
    $MenuChangeFoodItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuChangeFoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuChangeFoodItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MenuChangeFoodItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> menuChangeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> foodItemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuChangeFoodItemsCompanion(
                menuChangeId: menuChangeId,
                position: position,
                foodItemId: foodItemId,
                name: name,
                unit: unit,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String menuChangeId,
                required int position,
                required String foodItemId,
                required String name,
                Value<String?> unit = const Value.absent(),
                required int quantity,
                Value<int> rowid = const Value.absent(),
              }) => MenuChangeFoodItemsCompanion.insert(
                menuChangeId: menuChangeId,
                position: position,
                foodItemId: foodItemId,
                name: name,
                unit: unit,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MenuChangeFoodItemsTable, MenuChangeFoodItem>(
                    table,
                  ),
                  $$MenuChangeFoodItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({menuChangeId = false}) {
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
                    if (menuChangeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.menuChangeId,
                        referencedTable: $$MenuChangeFoodItemsTableReferences
                            ._menuChangeIdTable(db),
                        referencedColumn: $$MenuChangeFoodItemsTableReferences
                            ._menuChangeIdTable(db)
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

typedef $$MenuChangeFoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuChangeFoodItemsTable,
      MenuChangeFoodItem,
      $$MenuChangeFoodItemsTableFilterComposer,
      $$MenuChangeFoodItemsTableOrderingComposer,
      $$MenuChangeFoodItemsTableAnnotationComposer,
      $$MenuChangeFoodItemsTableCreateCompanionBuilder,
      $$MenuChangeFoodItemsTableUpdateCompanionBuilder,
      (MenuChangeFoodItem, $$MenuChangeFoodItemsTableReferences),
      MenuChangeFoodItem,
      PrefetchHooks Function({bool menuChangeId})
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
typedef $$GeneratedDocumentsTableCreateCompanionBuilder =
    GeneratedDocumentsCompanion Function({
      required String id,
      required String status,
      required DateTime requestedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> expiresAt,
      Value<String?> filePath,
      Value<String?> fileName,
      required String dates,
      Value<int> rowid,
    });
typedef $$GeneratedDocumentsTableUpdateCompanionBuilder =
    GeneratedDocumentsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<DateTime> requestedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> expiresAt,
      Value<String?> filePath,
      Value<String?> fileName,
      Value<String> dates,
      Value<int> rowid,
    });

class $$GeneratedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedDocumentsTable> {
  $$GeneratedDocumentsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeneratedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedDocumentsTable> {
  $$GeneratedDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneratedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedDocumentsTable> {
  $$GeneratedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get dates =>
      $composableBuilder(column: $table.dates, builder: (column) => column);
}

class $$GeneratedDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GeneratedDocumentsTable,
          StoredDocument,
          $$GeneratedDocumentsTableFilterComposer,
          $$GeneratedDocumentsTableOrderingComposer,
          $$GeneratedDocumentsTableAnnotationComposer,
          $$GeneratedDocumentsTableCreateCompanionBuilder,
          $$GeneratedDocumentsTableUpdateCompanionBuilder,
          (
            StoredDocument,
            BaseReferences<
              _$AppDatabase,
              $GeneratedDocumentsTable,
              StoredDocument
            >,
          ),
          StoredDocument,
          PrefetchHooks Function()
        > {
  $$GeneratedDocumentsTableTableManager(
    _$AppDatabase db,
    $GeneratedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneratedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneratedDocumentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String> dates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneratedDocumentsCompanion(
                id: id,
                status: status,
                requestedAt: requestedAt,
                completedAt: completedAt,
                expiresAt: expiresAt,
                filePath: filePath,
                fileName: fileName,
                dates: dates,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required DateTime requestedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                required String dates,
                Value<int> rowid = const Value.absent(),
              }) => GeneratedDocumentsCompanion.insert(
                id: id,
                status: status,
                requestedAt: requestedAt,
                completedAt: completedAt,
                expiresAt: expiresAt,
                filePath: filePath,
                fileName: fileName,
                dates: dates,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GeneratedDocumentsTable, StoredDocument>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GeneratedDocumentsTable,
                    StoredDocument
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeneratedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GeneratedDocumentsTable,
      StoredDocument,
      $$GeneratedDocumentsTableFilterComposer,
      $$GeneratedDocumentsTableOrderingComposer,
      $$GeneratedDocumentsTableAnnotationComposer,
      $$GeneratedDocumentsTableCreateCompanionBuilder,
      $$GeneratedDocumentsTableUpdateCompanionBuilder,
      (
        StoredDocument,
        BaseReferences<_$AppDatabase, $GeneratedDocumentsTable, StoredDocument>,
      ),
      StoredDocument,
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
  $$MealFoodItemsTableTableManager get mealFoodItems =>
      $$MealFoodItemsTableTableManager(_db, _db.mealFoodItems);
  $$MenuChangesTableTableManager get menuChanges =>
      $$MenuChangesTableTableManager(_db, _db.menuChanges);
  $$MenuChangeFoodItemsTableTableManager get menuChangeFoodItems =>
      $$MenuChangeFoodItemsTableTableManager(_db, _db.menuChangeFoodItems);
  $$PendingMealMapsTableTableManager get pendingMealMaps =>
      $$PendingMealMapsTableTableManager(_db, _db.pendingMealMaps);
  $$GeneratedDocumentsTableTableManager get generatedDocuments =>
      $$GeneratedDocumentsTableTableManager(_db, _db.generatedDocuments);
}
