import 'dart:convert';

/// 提醒配置模型
class ReminderConfig {
  final int count; // 提醒次数
  final Duration interval; // 提醒间隔
  final List<DateTime> scheduledTimes; // 已调度的提醒时间

  ReminderConfig({
    required this.count,
    required this.interval,
    this.scheduledTimes = const [],
  });

  // 从 Map 创建
  factory ReminderConfig.fromMap(Map<String, dynamic> map) {
    return ReminderConfig(
      count: map['count'] as int,
      interval: Duration(milliseconds: map['interval_ms'] as int),
      scheduledTimes: (map['scheduled_times'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'interval_ms': interval.inMilliseconds,
      'scheduled_times': scheduledTimes.map((e) => e.toIso8601String()).toList(),
    };
  }

  // 从 JSON 创建
  factory ReminderConfig.fromJson(String json) {
    return ReminderConfig.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // 转换为 JSON
  String toJson() {
    return jsonEncode(toMap());
  }

  // 复制并更新
  ReminderConfig copyWith({
    int? count,
    Duration? interval,
    List<DateTime>? scheduledTimes,
  }) {
    return ReminderConfig(
      count: count ?? this.count,
      interval: interval ?? this.interval,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReminderConfig) return false;

    return count == other.count &&
        interval == other.interval &&
        _listEquals(scheduledTimes, other.scheduledTimes);
  }

  @override
  int get hashCode => Object.hash(count, interval, scheduledTimes);

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
