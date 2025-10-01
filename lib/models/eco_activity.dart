class EcoActivity {
  final String id;
  final String userId;
  final String type;
  final String title;
  final int count;
  final DateTime createdAt;

  EcoActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.count,
    required this.createdAt,
  });

  EcoActivity copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    int? count,
    DateTime? createdAt,
  }) {
    return EcoActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'count': count,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EcoActivity.fromJson(Map<String, dynamic> json) {
    return EcoActivity(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      count: json['count'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class EcoActivityData {
  static final EcoActivityData _instance = EcoActivityData._internal();
  factory EcoActivityData() => _instance;
  EcoActivityData._internal();

  final List<EcoActivity> _activities = [];

  List<EcoActivity> get activities => List.unmodifiable(_activities);

  Map<String, int> get activityCounts {
    Map<String, int> counts = {};
    for (var activity in _activities) {
      counts[activity.type] = (counts[activity.type] ?? 0) + activity.count;
    }
    return counts;
  }

  void addActivity(EcoActivity activity) {
    _activities.add(activity);
  }

  void removeActivity(String id) {
    _activities.removeWhere((activity) => activity.id == id);
  }

  void clearActivities() {
    _activities.clear();
  }

  int getTotalCount() {
    return _activities.fold(0, (sum, activity) => sum + activity.count);
  }

  Map<String, int> getStats() {
    Map<String, int> stats = {};
    for (var activity in _activities) {
      stats[activity.type] = (stats[activity.type] ?? 0) + activity.count;
    }
    return stats;
  }
}
