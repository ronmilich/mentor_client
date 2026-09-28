typedef Json = Map<String, dynamic>;

enum LevelItemType {
  doItem('DO', 'Do'),
  avoid('AVOID', 'Avoid');

  const LevelItemType(this.value, this.label);
  final String value;
  final String label;
  static LevelItemType parse(String value) =>
      values.firstWhere((e) => e.value == value);
}

class MentorUser {
  const MentorUser({required this.id, required this.name});
  factory MentorUser.fromJson(Json json) =>
      MentorUser(id: json['id'], name: json['name']);
  final String id;
  final String name;
}

class Level {
  const Level({
    required this.id,
    required this.userId,
    required this.number,
    this.name,
    this.description,
    required this.requiredDays,
    required this.maxFailedAttempts,
    this.items = const [],
    this.attempts = const [],
  });
  factory Level.fromJson(Json json) => Level(
    id: json['id'],
    userId: json['userId'],
    number: json['number'],
    name: json['name'],
    description: json['description'],
    requiredDays: json['requiredDays'],
    maxFailedAttempts: json['maxFailedAttempts'],
    items: (json['items'] as List? ?? [])
        .map((e) => LevelItem.fromJson(e))
        .toList(),
    attempts: (json['attempts'] as List? ?? [])
        .map((e) => LevelAttempt.fromJson(e))
        .toList(),
  );
  final String id;
  final String userId;
  final int number;
  final String? name;
  final String? description;
  final int requiredDays;
  final int maxFailedAttempts;
  final List<LevelItem> items;
  final List<LevelAttempt> attempts;
  String get title => name == null || name!.isEmpty ? 'Level $number' : name!;
  List<LevelItem> get activeItems =>
      items.where((item) => item.isActive).toList();
  LevelAttempt? get activeAttempt =>
      attempts.where((a) => a.status == 'IN_PROGRESS').firstOrNull;
}

class LevelItem {
  const LevelItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.sortOrder = 0,
    this.isActive = true,
  });
  factory LevelItem.fromJson(Json json) => LevelItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: LevelItemType.parse(json['type']),
    sortOrder: json['sortOrder'],
    isActive: json['isActive'],
  );
  final String id;
  final String title;
  final String? description;
  final LevelItemType type;
  final int sortOrder;
  final bool isActive;
}

class LevelAttempt {
  const LevelAttempt({
    required this.id,
    required this.levelId,
    required this.status,
    required this.requiredDays,
    required this.startedAt,
    this.endedAt,
    this.failedOnDay,
    this.days = const [],
  });
  factory LevelAttempt.fromJson(Json json) => LevelAttempt(
    id: json['id'],
    levelId: json['levelId'],
    status: json['status'],
    requiredDays: json['requiredDays'],
    startedAt: DateTime.parse(json['startedAt']),
    endedAt: json['endedAt'] == null ? null : DateTime.parse(json['endedAt']),
    failedOnDay: json['failedOnDay'],
    days: (json['days'] as List? ?? [])
        .map((e) => LevelAttemptDay.fromJson(e))
        .toList(),
  );
  final String id;
  final String levelId;
  final String status;
  final int requiredDays;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? failedOnDay;
  final List<LevelAttemptDay> days;
  int get completedDays =>
      days.where((day) => day.status == 'COMPLETED').length;
}

class LevelAttemptDay {
  const LevelAttemptDay({
    required this.id,
    required this.dayNumber,
    required this.date,
    required this.status,
    this.itemResults = const [],
  });
  factory LevelAttemptDay.fromJson(Json json) => LevelAttemptDay(
    id: json['id'],
    dayNumber: json['dayNumber'],
    date: json['date'],
    status: json['status'],
    itemResults: (json['itemResults'] as List? ?? [])
        .map((e) => LevelItemResult.fromJson(e))
        .toList(),
  );
  final String id;
  final int dayNumber;
  final String date;
  final String status;
  final List<LevelItemResult> itemResults;
}

class LevelItemResult {
  const LevelItemResult({
    required this.id,
    required this.titleSnapshot,
    required this.typeSnapshot,
    required this.status,
  });
  factory LevelItemResult.fromJson(Json json) => LevelItemResult(
    id: json['id'],
    titleSnapshot: json['titleSnapshot'],
    typeSnapshot: LevelItemType.parse(json['typeSnapshot']),
    status: json['status'],
  );
  final String id;
  final String titleSnapshot;
  final LevelItemType typeSnapshot;
  final String status;
}
