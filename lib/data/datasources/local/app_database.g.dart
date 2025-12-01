// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    color,
    icon,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final DateTime createdAt;
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      createdAt: Value(createdAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String?>(icon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Category copyWith({
    int? id,
    String? userId,
    String? name,
    String? color,
    Value<String?> icon = const Value.absent(),
    DateTime? createdAt,
  }) => Category(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon.present ? icon.value : this.icon,
    createdAt: createdAt ?? this.createdAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, color, icon, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> color;
  final Value<String?> icon;
  final Value<DateTime> createdAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String name,
    required String color,
    this.icon = const Value.absent(),
    required DateTime createdAt,
  }) : userId = Value(userId),
       name = Value(name),
       color = Value(color),
       createdAt = Value(createdAt);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? color,
    Value<String?>? icon,
    Value<DateTime>? createdAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, Todo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
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
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
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
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationTimeMeta = const VerificationMeta(
    'notificationTime',
  );
  @override
  late final GeneratedColumn<DateTime> notificationTime =
      GeneratedColumn<DateTime>(
        'notification_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentRecurringTodoIdMeta =
      const VerificationMeta('parentRecurringTodoId');
  @override
  late final GeneratedColumn<int> parentRecurringTodoId = GeneratedColumn<int>(
    'parent_recurring_todo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeCountMeta = const VerificationMeta(
    'snoozeCount',
  );
  @override
  late final GeneratedColumn<int> snoozeCount = GeneratedColumn<int>(
    'snooze_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSnoozeTimeMeta = const VerificationMeta(
    'lastSnoozeTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastSnoozeTime =
      GeneratedColumn<DateTime>(
        'last_snooze_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _locationLatitudeMeta = const VerificationMeta(
    'locationLatitude',
  );
  @override
  late final GeneratedColumn<double> locationLatitude = GeneratedColumn<double>(
    'location_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLongitudeMeta = const VerificationMeta(
    'locationLongitude',
  );
  @override
  late final GeneratedColumn<double> locationLongitude =
      GeneratedColumn<double>(
        'location_longitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationRadiusMeta = const VerificationMeta(
    'locationRadius',
  );
  @override
  late final GeneratedColumn<double> locationRadius = GeneratedColumn<double>(
    'location_radius',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationTriggeredAtMeta =
      const VerificationMeta('locationTriggeredAt');
  @override
  late final GeneratedColumn<DateTime> locationTriggeredAt =
      GeneratedColumn<DateTime>(
        'location_triggered_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    isCompleted,
    categoryId,
    createdAt,
    completedAt,
    dueDate,
    notificationTime,
    recurrenceRule,
    parentRecurringTodoId,
    snoozeCount,
    lastSnoozeTime,
    locationLatitude,
    locationLongitude,
    locationName,
    locationRadius,
    locationTriggeredAt,
    position,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Todo> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('notification_time')) {
      context.handle(
        _notificationTimeMeta,
        notificationTime.isAcceptableOrUnknown(
          data['notification_time']!,
          _notificationTimeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('parent_recurring_todo_id')) {
      context.handle(
        _parentRecurringTodoIdMeta,
        parentRecurringTodoId.isAcceptableOrUnknown(
          data['parent_recurring_todo_id']!,
          _parentRecurringTodoIdMeta,
        ),
      );
    }
    if (data.containsKey('snooze_count')) {
      context.handle(
        _snoozeCountMeta,
        snoozeCount.isAcceptableOrUnknown(
          data['snooze_count']!,
          _snoozeCountMeta,
        ),
      );
    }
    if (data.containsKey('last_snooze_time')) {
      context.handle(
        _lastSnoozeTimeMeta,
        lastSnoozeTime.isAcceptableOrUnknown(
          data['last_snooze_time']!,
          _lastSnoozeTimeMeta,
        ),
      );
    }
    if (data.containsKey('location_latitude')) {
      context.handle(
        _locationLatitudeMeta,
        locationLatitude.isAcceptableOrUnknown(
          data['location_latitude']!,
          _locationLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('location_longitude')) {
      context.handle(
        _locationLongitudeMeta,
        locationLongitude.isAcceptableOrUnknown(
          data['location_longitude']!,
          _locationLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('location_radius')) {
      context.handle(
        _locationRadiusMeta,
        locationRadius.isAcceptableOrUnknown(
          data['location_radius']!,
          _locationRadiusMeta,
        ),
      );
    }
    if (data.containsKey('location_triggered_at')) {
      context.handle(
        _locationTriggeredAtMeta,
        locationTriggeredAt.isAcceptableOrUnknown(
          data['location_triggered_at']!,
          _locationTriggeredAtMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Todo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      notificationTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notification_time'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      parentRecurringTodoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_recurring_todo_id'],
      ),
      snoozeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_count'],
      )!,
      lastSnoozeTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_snooze_time'],
      ),
      locationLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_latitude'],
      ),
      locationLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_longitude'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      locationRadius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_radius'],
      ),
      locationTriggeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}location_triggered_at'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class Todo extends DataClass implements Insertable<Todo> {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime? notificationTime;
  final String? recurrenceRule;
  final int? parentRecurringTodoId;
  final int snoozeCount;
  final DateTime? lastSnoozeTime;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationName;
  final double? locationRadius;
  final DateTime? locationTriggeredAt;
  final int position;
  final String priority;
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.categoryId,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
    this.notificationTime,
    this.recurrenceRule,
    this.parentRecurringTodoId,
    required this.snoozeCount,
    this.lastSnoozeTime,
    this.locationLatitude,
    this.locationLongitude,
    this.locationName,
    this.locationRadius,
    this.locationTriggeredAt,
    required this.position,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || notificationTime != null) {
      map['notification_time'] = Variable<DateTime>(notificationTime);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || parentRecurringTodoId != null) {
      map['parent_recurring_todo_id'] = Variable<int>(parentRecurringTodoId);
    }
    map['snooze_count'] = Variable<int>(snoozeCount);
    if (!nullToAbsent || lastSnoozeTime != null) {
      map['last_snooze_time'] = Variable<DateTime>(lastSnoozeTime);
    }
    if (!nullToAbsent || locationLatitude != null) {
      map['location_latitude'] = Variable<double>(locationLatitude);
    }
    if (!nullToAbsent || locationLongitude != null) {
      map['location_longitude'] = Variable<double>(locationLongitude);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || locationRadius != null) {
      map['location_radius'] = Variable<double>(locationRadius);
    }
    if (!nullToAbsent || locationTriggeredAt != null) {
      map['location_triggered_at'] = Variable<DateTime>(locationTriggeredAt);
    }
    map['position'] = Variable<int>(position);
    map['priority'] = Variable<String>(priority);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      isCompleted: Value(isCompleted),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      notificationTime: notificationTime == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationTime),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      parentRecurringTodoId: parentRecurringTodoId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRecurringTodoId),
      snoozeCount: Value(snoozeCount),
      lastSnoozeTime: lastSnoozeTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSnoozeTime),
      locationLatitude: locationLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLatitude),
      locationLongitude: locationLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLongitude),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      locationRadius: locationRadius == null && nullToAbsent
          ? const Value.absent()
          : Value(locationRadius),
      locationTriggeredAt: locationTriggeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(locationTriggeredAt),
      position: Value(position),
      priority: Value(priority),
    );
  }

  factory Todo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      notificationTime: serializer.fromJson<DateTime?>(
        json['notificationTime'],
      ),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      parentRecurringTodoId: serializer.fromJson<int?>(
        json['parentRecurringTodoId'],
      ),
      snoozeCount: serializer.fromJson<int>(json['snoozeCount']),
      lastSnoozeTime: serializer.fromJson<DateTime?>(json['lastSnoozeTime']),
      locationLatitude: serializer.fromJson<double?>(json['locationLatitude']),
      locationLongitude: serializer.fromJson<double?>(
        json['locationLongitude'],
      ),
      locationName: serializer.fromJson<String?>(json['locationName']),
      locationRadius: serializer.fromJson<double?>(json['locationRadius']),
      locationTriggeredAt: serializer.fromJson<DateTime?>(
        json['locationTriggeredAt'],
      ),
      position: serializer.fromJson<int>(json['position']),
      priority: serializer.fromJson<String>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'categoryId': serializer.toJson<int?>(categoryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'notificationTime': serializer.toJson<DateTime?>(notificationTime),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'parentRecurringTodoId': serializer.toJson<int?>(parentRecurringTodoId),
      'snoozeCount': serializer.toJson<int>(snoozeCount),
      'lastSnoozeTime': serializer.toJson<DateTime?>(lastSnoozeTime),
      'locationLatitude': serializer.toJson<double?>(locationLatitude),
      'locationLongitude': serializer.toJson<double?>(locationLongitude),
      'locationName': serializer.toJson<String?>(locationName),
      'locationRadius': serializer.toJson<double?>(locationRadius),
      'locationTriggeredAt': serializer.toJson<DateTime?>(locationTriggeredAt),
      'position': serializer.toJson<int>(position),
      'priority': serializer.toJson<String>(priority),
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    Value<int?> categoryId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> notificationTime = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<int?> parentRecurringTodoId = const Value.absent(),
    int? snoozeCount,
    Value<DateTime?> lastSnoozeTime = const Value.absent(),
    Value<double?> locationLatitude = const Value.absent(),
    Value<double?> locationLongitude = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    Value<double?> locationRadius = const Value.absent(),
    Value<DateTime?> locationTriggeredAt = const Value.absent(),
    int? position,
    String? priority,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    isCompleted: isCompleted ?? this.isCompleted,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    notificationTime: notificationTime.present
        ? notificationTime.value
        : this.notificationTime,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    parentRecurringTodoId: parentRecurringTodoId.present
        ? parentRecurringTodoId.value
        : this.parentRecurringTodoId,
    snoozeCount: snoozeCount ?? this.snoozeCount,
    lastSnoozeTime: lastSnoozeTime.present
        ? lastSnoozeTime.value
        : this.lastSnoozeTime,
    locationLatitude: locationLatitude.present
        ? locationLatitude.value
        : this.locationLatitude,
    locationLongitude: locationLongitude.present
        ? locationLongitude.value
        : this.locationLongitude,
    locationName: locationName.present ? locationName.value : this.locationName,
    locationRadius: locationRadius.present
        ? locationRadius.value
        : this.locationRadius,
    locationTriggeredAt: locationTriggeredAt.present
        ? locationTriggeredAt.value
        : this.locationTriggeredAt,
    position: position ?? this.position,
    priority: priority ?? this.priority,
  );
  Todo copyWithCompanion(TodosCompanion data) {
    return Todo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      notificationTime: data.notificationTime.present
          ? data.notificationTime.value
          : this.notificationTime,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      parentRecurringTodoId: data.parentRecurringTodoId.present
          ? data.parentRecurringTodoId.value
          : this.parentRecurringTodoId,
      snoozeCount: data.snoozeCount.present
          ? data.snoozeCount.value
          : this.snoozeCount,
      lastSnoozeTime: data.lastSnoozeTime.present
          ? data.lastSnoozeTime.value
          : this.lastSnoozeTime,
      locationLatitude: data.locationLatitude.present
          ? data.locationLatitude.value
          : this.locationLatitude,
      locationLongitude: data.locationLongitude.present
          ? data.locationLongitude.value
          : this.locationLongitude,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      locationRadius: data.locationRadius.present
          ? data.locationRadius.value
          : this.locationRadius,
      locationTriggeredAt: data.locationTriggeredAt.present
          ? data.locationTriggeredAt.value
          : this.locationTriggeredAt,
      position: data.position.present ? data.position.value : this.position,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('notificationTime: $notificationTime, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('parentRecurringTodoId: $parentRecurringTodoId, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('lastSnoozeTime: $lastSnoozeTime, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationName: $locationName, ')
          ..write('locationRadius: $locationRadius, ')
          ..write('locationTriggeredAt: $locationTriggeredAt, ')
          ..write('position: $position, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    isCompleted,
    categoryId,
    createdAt,
    completedAt,
    dueDate,
    notificationTime,
    recurrenceRule,
    parentRecurringTodoId,
    snoozeCount,
    lastSnoozeTime,
    locationLatitude,
    locationLongitude,
    locationName,
    locationRadius,
    locationTriggeredAt,
    position,
    priority,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.isCompleted == this.isCompleted &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.dueDate == this.dueDate &&
          other.notificationTime == this.notificationTime &&
          other.recurrenceRule == this.recurrenceRule &&
          other.parentRecurringTodoId == this.parentRecurringTodoId &&
          other.snoozeCount == this.snoozeCount &&
          other.lastSnoozeTime == this.lastSnoozeTime &&
          other.locationLatitude == this.locationLatitude &&
          other.locationLongitude == this.locationLongitude &&
          other.locationName == this.locationName &&
          other.locationRadius == this.locationRadius &&
          other.locationTriggeredAt == this.locationTriggeredAt &&
          other.position == this.position &&
          other.priority == this.priority);
}

class TodosCompanion extends UpdateCompanion<Todo> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> description;
  final Value<bool> isCompleted;
  final Value<int?> categoryId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> notificationTime;
  final Value<String?> recurrenceRule;
  final Value<int?> parentRecurringTodoId;
  final Value<int> snoozeCount;
  final Value<DateTime?> lastSnoozeTime;
  final Value<double?> locationLatitude;
  final Value<double?> locationLongitude;
  final Value<String?> locationName;
  final Value<double?> locationRadius;
  final Value<DateTime?> locationTriggeredAt;
  final Value<int> position;
  final Value<String> priority;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notificationTime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.parentRecurringTodoId = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.lastSnoozeTime = const Value.absent(),
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    this.locationName = const Value.absent(),
    this.locationRadius = const Value.absent(),
    this.locationTriggeredAt = const Value.absent(),
    this.position = const Value.absent(),
    this.priority = const Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String description,
    this.isCompleted = const Value.absent(),
    this.categoryId = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notificationTime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.parentRecurringTodoId = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.lastSnoozeTime = const Value.absent(),
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    this.locationName = const Value.absent(),
    this.locationRadius = const Value.absent(),
    this.locationTriggeredAt = const Value.absent(),
    this.position = const Value.absent(),
    this.priority = const Value.absent(),
  }) : title = Value(title),
       description = Value(description),
       createdAt = Value(createdAt);
  static Insertable<Todo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? isCompleted,
    Expression<int>? categoryId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? notificationTime,
    Expression<String>? recurrenceRule,
    Expression<int>? parentRecurringTodoId,
    Expression<int>? snoozeCount,
    Expression<DateTime>? lastSnoozeTime,
    Expression<double>? locationLatitude,
    Expression<double>? locationLongitude,
    Expression<String>? locationName,
    Expression<double>? locationRadius,
    Expression<DateTime>? locationTriggeredAt,
    Expression<int>? position,
    Expression<String>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (dueDate != null) 'due_date': dueDate,
      if (notificationTime != null) 'notification_time': notificationTime,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (parentRecurringTodoId != null)
        'parent_recurring_todo_id': parentRecurringTodoId,
      if (snoozeCount != null) 'snooze_count': snoozeCount,
      if (lastSnoozeTime != null) 'last_snooze_time': lastSnoozeTime,
      if (locationLatitude != null) 'location_latitude': locationLatitude,
      if (locationLongitude != null) 'location_longitude': locationLongitude,
      if (locationName != null) 'location_name': locationName,
      if (locationRadius != null) 'location_radius': locationRadius,
      if (locationTriggeredAt != null)
        'location_triggered_at': locationTriggeredAt,
      if (position != null) 'position': position,
      if (priority != null) 'priority': priority,
    });
  }

  TodosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? description,
    Value<bool>? isCompleted,
    Value<int?>? categoryId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? notificationTime,
    Value<String?>? recurrenceRule,
    Value<int?>? parentRecurringTodoId,
    Value<int>? snoozeCount,
    Value<DateTime?>? lastSnoozeTime,
    Value<double?>? locationLatitude,
    Value<double?>? locationLongitude,
    Value<String?>? locationName,
    Value<double?>? locationRadius,
    Value<DateTime?>? locationTriggeredAt,
    Value<int>? position,
    Value<String>? priority,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      notificationTime: notificationTime ?? this.notificationTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentRecurringTodoId:
          parentRecurringTodoId ?? this.parentRecurringTodoId,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozeTime: lastSnoozeTime ?? this.lastSnoozeTime,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationName: locationName ?? this.locationName,
      locationRadius: locationRadius ?? this.locationRadius,
      locationTriggeredAt: locationTriggeredAt ?? this.locationTriggeredAt,
      position: position ?? this.position,
      priority: priority ?? this.priority,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (notificationTime.present) {
      map['notification_time'] = Variable<DateTime>(notificationTime.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (parentRecurringTodoId.present) {
      map['parent_recurring_todo_id'] = Variable<int>(
        parentRecurringTodoId.value,
      );
    }
    if (snoozeCount.present) {
      map['snooze_count'] = Variable<int>(snoozeCount.value);
    }
    if (lastSnoozeTime.present) {
      map['last_snooze_time'] = Variable<DateTime>(lastSnoozeTime.value);
    }
    if (locationLatitude.present) {
      map['location_latitude'] = Variable<double>(locationLatitude.value);
    }
    if (locationLongitude.present) {
      map['location_longitude'] = Variable<double>(locationLongitude.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (locationRadius.present) {
      map['location_radius'] = Variable<double>(locationRadius.value);
    }
    if (locationTriggeredAt.present) {
      map['location_triggered_at'] = Variable<DateTime>(
        locationTriggeredAt.value,
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('notificationTime: $notificationTime, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('parentRecurringTodoId: $parentRecurringTodoId, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('lastSnoozeTime: $lastSnoozeTime, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationName: $locationName, ')
          ..write('locationRadius: $locationRadius, ')
          ..write('locationTriggeredAt: $locationTriggeredAt, ')
          ..write('position: $position, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, email, password, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String email;
  final String password;
  final String name;
  final DateTime createdAt;
  const User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['email'] = Variable<String>(email);
    map['password'] = Variable<String>(password);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      password: Value(password),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      password: serializer.fromJson<String>(json['password']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'email': serializer.toJson<String>(email),
      'password': serializer.toJson<String>(password),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    password: password ?? this.password,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      password: data.password.present ? data.password.value : this.password,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, email, password, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.password == this.password &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> email;
  final Value<String> password;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.password = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String email,
    required String password,
    required String name,
    required DateTime createdAt,
  }) : email = Value(email),
       password = Value(password),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? email,
    Expression<String>? password,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? email,
    Value<String>? password,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<int> todoId = GeneratedColumn<int>(
    'todo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES todos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    todoId,
    userId,
    title,
    isCompleted,
    position,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('todo_id')) {
      context.handle(
        _todoIdMeta,
        todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_todoIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      todoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}todo_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final int id;
  final int todoId;
  final String userId;
  final String title;
  final bool isCompleted;
  final int position;
  final DateTime createdAt;
  final DateTime? completedAt;
  const Subtask({
    required this.id,
    required this.todoId,
    required this.userId,
    required this.title,
    required this.isCompleted,
    required this.position,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['todo_id'] = Variable<int>(todoId);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      todoId: Value(todoId),
      userId: Value(userId),
      title: Value(title),
      isCompleted: Value(isCompleted),
      position: Value(position),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<int>(json['id']),
      todoId: serializer.fromJson<int>(json['todoId']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'todoId': serializer.toJson<int>(todoId),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Subtask copyWith({
    int? id,
    int? todoId,
    String? userId,
    String? title,
    bool? isCompleted,
    int? position,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => Subtask(
    id: id ?? this.id,
    todoId: todoId ?? this.todoId,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    todoId,
    userId,
    title,
    isCompleted,
    position,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.todoId == this.todoId &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<int> id;
  final Value<int> todoId;
  final Value<String> userId;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.todoId = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  SubtasksCompanion.insert({
    this.id = const Value.absent(),
    required int todoId,
    required String userId,
    required String title,
    this.isCompleted = const Value.absent(),
    required int position,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
  }) : todoId = Value(todoId),
       userId = Value(userId),
       title = Value(title),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<Subtask> custom({
    Expression<int>? id,
    Expression<int>? todoId,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (todoId != null) 'todo_id': todoId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  SubtasksCompanion copyWith({
    Value<int>? id,
    Value<int>? todoId,
    Value<String>? userId,
    Value<String>? title,
    Value<bool>? isCompleted,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<int>(todoId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<int> todoId = GeneratedColumn<int>(
    'todo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES todos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
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
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    todoId,
    userId,
    fileName,
    filePath,
    fileSize,
    mimeType,
    storagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('todo_id')) {
      context.handle(
        _todoIdMeta,
        todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_todoIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      todoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}todo_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final int id;
  final int todoId;
  final String userId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String storagePath;
  final DateTime createdAt;
  const Attachment({
    required this.id,
    required this.todoId,
    required this.userId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['todo_id'] = Variable<int>(todoId);
    map['user_id'] = Variable<String>(userId);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['mime_type'] = Variable<String>(mimeType);
    map['storage_path'] = Variable<String>(storagePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      todoId: Value(todoId),
      userId: Value(userId),
      fileName: Value(fileName),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      mimeType: Value(mimeType),
      storagePath: Value(storagePath),
      createdAt: Value(createdAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<int>(json['id']),
      todoId: serializer.fromJson<int>(json['todoId']),
      userId: serializer.fromJson<String>(json['userId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'todoId': serializer.toJson<int>(todoId),
      'userId': serializer.toJson<String>(userId),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'mimeType': serializer.toJson<String>(mimeType),
      'storagePath': serializer.toJson<String>(storagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Attachment copyWith({
    int? id,
    int? todoId,
    String? userId,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    DateTime? createdAt,
  }) => Attachment(
    id: id ?? this.id,
    todoId: todoId ?? this.todoId,
    userId: userId ?? this.userId,
    fileName: fileName ?? this.fileName,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    mimeType: mimeType ?? this.mimeType,
    storagePath: storagePath ?? this.storagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      userId: data.userId.present ? data.userId.value : this.userId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('storagePath: $storagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    todoId,
    userId,
    fileName,
    filePath,
    fileSize,
    mimeType,
    storagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.todoId == this.todoId &&
          other.userId == this.userId &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.mimeType == this.mimeType &&
          other.storagePath == this.storagePath &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<int> id;
  final Value<int> todoId;
  final Value<String> userId;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<String> mimeType;
  final Value<String> storagePath;
  final Value<DateTime> createdAt;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.todoId = const Value.absent(),
    this.userId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int todoId,
    required String userId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String storagePath,
    required DateTime createdAt,
  }) : todoId = Value(todoId),
       userId = Value(userId),
       fileName = Value(fileName),
       filePath = Value(filePath),
       fileSize = Value(fileSize),
       mimeType = Value(mimeType),
       storagePath = Value(storagePath),
       createdAt = Value(createdAt);
  static Insertable<Attachment> custom({
    Expression<int>? id,
    Expression<int>? todoId,
    Expression<String>? userId,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<String>? mimeType,
    Expression<String>? storagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (todoId != null) 'todo_id': todoId,
      if (userId != null) 'user_id': userId,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (storagePath != null) 'storage_path': storagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? todoId,
    Value<String>? userId,
    Value<String>? fileName,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<String>? mimeType,
    Value<String>? storagePath,
    Value<DateTime>? createdAt,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<int>(todoId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('storagePath: $storagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodosTable todos = $TodosTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    todos,
    users,
    subtasks,
    attachments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('todos', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'todos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subtasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'todos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String userId,
      required String name,
      required String color,
      Value<String?> icon,
      required DateTime createdAt,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> name,
      Value<String> color,
      Value<String?> icon,
      Value<DateTime> createdAt,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TodosTable, List<Todo>> _todosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.todos,
    aliasName: $_aliasNameGenerator(db.categories.id, db.todos.categoryId),
  );

  $$TodosTableProcessedTableManager get todosRefs {
    final manager = $$TodosTableTableManager(
      $_db,
      $_db.todos,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_todosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> todosRefs(
    Expression<bool> Function($$TodosTableFilterComposer f) f,
  ) {
    final $$TodosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableFilterComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> todosRefs<T extends Object>(
    Expression<T> Function($$TodosTableAnnotationComposer a) f,
  ) {
    final $$TodosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableAnnotationComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool todosRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String name,
                required String color,
                Value<String?> icon = const Value.absent(),
                required DateTime createdAt,
              }) => CategoriesCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (todosRefs) db.todos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (todosRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Todo>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._todosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(db, table, p0).todosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool todosRefs})
    >;
typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      required String title,
      required String description,
      Value<bool> isCompleted,
      Value<int?> categoryId,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> dueDate,
      Value<DateTime?> notificationTime,
      Value<String?> recurrenceRule,
      Value<int?> parentRecurringTodoId,
      Value<int> snoozeCount,
      Value<DateTime?> lastSnoozeTime,
      Value<double?> locationLatitude,
      Value<double?> locationLongitude,
      Value<String?> locationName,
      Value<double?> locationRadius,
      Value<DateTime?> locationTriggeredAt,
      Value<int> position,
      Value<String> priority,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> description,
      Value<bool> isCompleted,
      Value<int?> categoryId,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> dueDate,
      Value<DateTime?> notificationTime,
      Value<String?> recurrenceRule,
      Value<int?> parentRecurringTodoId,
      Value<int> snoozeCount,
      Value<DateTime?> lastSnoozeTime,
      Value<double?> locationLatitude,
      Value<double?> locationLongitude,
      Value<String?> locationName,
      Value<double?> locationRadius,
      Value<DateTime?> locationTriggeredAt,
      Value<int> position,
      Value<String> priority,
    });

final class $$TodosTableReferences
    extends BaseReferences<_$AppDatabase, $TodosTable, Todo> {
  $$TodosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias($_aliasNameGenerator(db.todos.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubtasksTable, List<Subtask>> _subtasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subtasks,
    aliasName: $_aliasNameGenerator(db.todos.id, db.subtasks.todoId),
  );

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager(
      $_db,
      $_db.subtasks,
    ).filter((f) => f.todoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(db.todos.id, db.attachments.todoId),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.todoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentRecurringTodoId => $composableBuilder(
    column: $table.parentRecurringTodoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSnoozeTime => $composableBuilder(
    column: $table.lastSnoozeTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationRadius => $composableBuilder(
    column: $table.locationRadius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get locationTriggeredAt => $composableBuilder(
    column: $table.locationTriggeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subtasksRefs(
    Expression<bool> Function($$SubtasksTableFilterComposer f) f,
  ) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.todoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableFilterComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.todoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentRecurringTodoId => $composableBuilder(
    column: $table.parentRecurringTodoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSnoozeTime => $composableBuilder(
    column: $table.lastSnoozeTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationRadius => $composableBuilder(
    column: $table.locationRadius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get locationTriggeredAt => $composableBuilder(
    column: $table.locationTriggeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parentRecurringTodoId => $composableBuilder(
    column: $table.parentRecurringTodoId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSnoozeTime => $composableBuilder(
    column: $table.lastSnoozeTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationRadius => $composableBuilder(
    column: $table.locationRadius,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get locationTriggeredAt => $composableBuilder(
    column: $table.locationTriggeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subtasksRefs<T extends Object>(
    Expression<T> Function($$SubtasksTableAnnotationComposer a) f,
  ) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.todoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.todoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodosTable,
          Todo,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (Todo, $$TodosTableReferences),
          Todo,
          PrefetchHooks Function({
            bool categoryId,
            bool subtasksRefs,
            bool attachmentsRefs,
          })
        > {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> notificationTime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> parentRecurringTodoId = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<DateTime?> lastSnoozeTime = const Value.absent(),
                Value<double?> locationLatitude = const Value.absent(),
                Value<double?> locationLongitude = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> locationRadius = const Value.absent(),
                Value<DateTime?> locationTriggeredAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> priority = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                description: description,
                isCompleted: isCompleted,
                categoryId: categoryId,
                createdAt: createdAt,
                completedAt: completedAt,
                dueDate: dueDate,
                notificationTime: notificationTime,
                recurrenceRule: recurrenceRule,
                parentRecurringTodoId: parentRecurringTodoId,
                snoozeCount: snoozeCount,
                lastSnoozeTime: lastSnoozeTime,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                locationName: locationName,
                locationRadius: locationRadius,
                locationTriggeredAt: locationTriggeredAt,
                position: position,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String description,
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> notificationTime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> parentRecurringTodoId = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<DateTime?> lastSnoozeTime = const Value.absent(),
                Value<double?> locationLatitude = const Value.absent(),
                Value<double?> locationLongitude = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> locationRadius = const Value.absent(),
                Value<DateTime?> locationTriggeredAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> priority = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                description: description,
                isCompleted: isCompleted,
                categoryId: categoryId,
                createdAt: createdAt,
                completedAt: completedAt,
                dueDate: dueDate,
                notificationTime: notificationTime,
                recurrenceRule: recurrenceRule,
                parentRecurringTodoId: parentRecurringTodoId,
                snoozeCount: snoozeCount,
                lastSnoozeTime: lastSnoozeTime,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                locationName: locationName,
                locationRadius: locationRadius,
                locationTriggeredAt: locationTriggeredAt,
                position: position,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TodosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                subtasksRefs = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subtasksRefs) db.subtasks,
                    if (attachmentsRefs) db.attachments,
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$TodosTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$TodosTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subtasksRefs)
                        await $_getPrefetchedData<Todo, $TodosTable, Subtask>(
                          currentTable: table,
                          referencedTable: $$TodosTableReferences
                              ._subtasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TodosTableReferences(
                                db,
                                table,
                                p0,
                              ).subtasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.todoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Todo,
                          $TodosTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$TodosTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TodosTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.todoId == item.id,
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

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodosTable,
      Todo,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (Todo, $$TodosTableReferences),
      Todo,
      PrefetchHooks Function({
        bool categoryId,
        bool subtasksRefs,
        bool attachmentsRefs,
      })
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String email,
      required String password,
      required String name,
      required DateTime createdAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> email,
      Value<String> password,
      Value<String> name,
      Value<DateTime> createdAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                password: password,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String email,
                required String password,
                required String name,
                required DateTime createdAt,
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                password: password,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$SubtasksTableCreateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      required int todoId,
      required String userId,
      required String title,
      Value<bool> isCompleted,
      required int position,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
    });
typedef $$SubtasksTableUpdateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      Value<int> todoId,
      Value<String> userId,
      Value<String> title,
      Value<bool> isCompleted,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
    });

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, Subtask> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TodosTable _todoIdTable(_$AppDatabase db) => db.todos.createAlias(
    $_aliasNameGenerator(db.subtasks.todoId, db.todos.id),
  );

  $$TodosTableProcessedTableManager get todoId {
    final $_column = $_itemColumn<int>('todo_id')!;

    final manager = $$TodosTableTableManager(
      $_db,
      $_db.todos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_todoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TodosTableFilterComposer get todoId {
    final $$TodosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableFilterComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TodosTableOrderingComposer get todoId {
    final $$TodosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableOrderingComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$TodosTableAnnotationComposer get todoId {
    final $$TodosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableAnnotationComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, $$SubtasksTableReferences),
          Subtask,
          PrefetchHooks Function({bool todoId})
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> todoId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                todoId: todoId,
                userId: userId,
                title: title,
                isCompleted: isCompleted,
                position: position,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int todoId,
                required String userId,
                required String title,
                Value<bool> isCompleted = const Value.absent(),
                required int position,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                todoId: todoId,
                userId: userId,
                title: title,
                isCompleted: isCompleted,
                position: position,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todoId = false}) {
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
                    if (todoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.todoId,
                                referencedTable: $$SubtasksTableReferences
                                    ._todoIdTable(db),
                                referencedColumn: $$SubtasksTableReferences
                                    ._todoIdTable(db)
                                    .id,
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

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, $$SubtasksTableReferences),
      Subtask,
      PrefetchHooks Function({bool todoId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      required int todoId,
      required String userId,
      required String fileName,
      required String filePath,
      required int fileSize,
      required String mimeType,
      required String storagePath,
      required DateTime createdAt,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      Value<int> todoId,
      Value<String> userId,
      Value<String> fileName,
      Value<String> filePath,
      Value<int> fileSize,
      Value<String> mimeType,
      Value<String> storagePath,
      Value<DateTime> createdAt,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TodosTable _todoIdTable(_$AppDatabase db) => db.todos.createAlias(
    $_aliasNameGenerator(db.attachments.todoId, db.todos.id),
  );

  $$TodosTableProcessedTableManager get todoId {
    final $_column = $_itemColumn<int>('todo_id')!;

    final manager = $$TodosTableTableManager(
      $_db,
      $_db.todos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_todoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TodosTableFilterComposer get todoId {
    final $$TodosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableFilterComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TodosTableOrderingComposer get todoId {
    final $$TodosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableOrderingComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TodosTableAnnotationComposer get todoId {
    final $$TodosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoId,
      referencedTable: $db.todos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableAnnotationComposer(
            $db: $db,
            $table: $db.todos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool todoId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> todoId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> storagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                todoId: todoId,
                userId: userId,
                fileName: fileName,
                filePath: filePath,
                fileSize: fileSize,
                mimeType: mimeType,
                storagePath: storagePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int todoId,
                required String userId,
                required String fileName,
                required String filePath,
                required int fileSize,
                required String mimeType,
                required String storagePath,
                required DateTime createdAt,
              }) => AttachmentsCompanion.insert(
                id: id,
                todoId: todoId,
                userId: userId,
                fileName: fileName,
                filePath: filePath,
                fileSize: fileSize,
                mimeType: mimeType,
                storagePath: storagePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todoId = false}) {
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
                    if (todoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.todoId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._todoIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._todoIdTable(db)
                                    .id,
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

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool todoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
}
