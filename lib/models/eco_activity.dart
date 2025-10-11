import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EcoActivity {
  final String id;
  final String userId;
  final String type;
  final String title;
  final int count;
  final DateTime createdAt;
  final String? note;
  final String? imageUrl;

  EcoActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.count,
    required this.createdAt,
    this.note,
    this.imageUrl,
  });

  EcoActivity copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    int? count,
    DateTime? createdAt,
    String? note,
    String? imageUrl,
  }) {
    return EcoActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'count': count,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
      'imageUrl': imageUrl,
    };
  }

  factory EcoActivity.fromJson(Map<String, dynamic> json) {
    return EcoActivity(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      count: json['count'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      note: json['note'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class EcoActivityData {
  static final EcoActivityData _instance = EcoActivityData._internal();
  factory EcoActivityData() => _instance;
  EcoActivityData._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<EcoActivity> _activities = [];

  List<EcoActivity> get activities => List.unmodifiable(_activities);

  Map<String, int> get activityCounts {
    Map<String, int> counts = {};
    for (var activity in _activities) {
      counts[activity.type] = (counts[activity.type] ?? 0) + activity.count;
    }
    return counts;
  }

  Future<void> loadActivitiesFromFirestore(User user) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final loadedActivities = snapshot.docs
          .map(
            (doc) => EcoActivity.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      _activities.clear();
      _activities.addAll(loadedActivities);
    } catch (e) {
      print("Error loading activities from Firestore: $e");
      clearActivities();
    }
  }

  void addActivity(EcoActivity activity) {
    _activities.insert(0, activity);
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
