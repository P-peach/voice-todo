import 'dart:convert';

/// 自定义词汇条目数据模型
/// 用于存储语音识别中常见的错误识别词汇及其正确映射
class VocabularyEntry {
  final String incorrect; // 错误识别的词汇
  final String correct; // 正确的词汇
  final int usageCount; // 使用次数（应用此纠正的次数）
  final DateTime createdAt; // 创建时间

  VocabularyEntry({
    required this.incorrect,
    required this.correct,
    this.usageCount = 0,
    required this.createdAt,
  });

  // 从 Map 创建
  factory VocabularyEntry.fromMap(Map<String, dynamic> map) {
    return VocabularyEntry(
      incorrect: map['incorrect'] as String,
      correct: map['correct'] as String,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'incorrect': incorrect,
      'correct': correct,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 从 JSON 创建
  factory VocabularyEntry.fromJson(String json) {
    return VocabularyEntry.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // 转换为 JSON
  String toJson() {
    return jsonEncode(toMap());
  }

  // 增加使用次数
  VocabularyEntry incrementUsage() {
    return VocabularyEntry(
      incorrect: incorrect,
      correct: correct,
      usageCount: usageCount + 1,
      createdAt: createdAt,
    );
  }

  // 复制并更新
  VocabularyEntry copyWith({
    String? incorrect,
    String? correct,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return VocabularyEntry(
      incorrect: incorrect ?? this.incorrect,
      correct: correct ?? this.correct,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VocabularyEntry &&
        other.incorrect == incorrect &&
        other.correct == correct &&
        other.usageCount == usageCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return incorrect.hashCode ^
        correct.hashCode ^
        usageCount.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'VocabularyEntry(incorrect: $incorrect, correct: $correct, usageCount: $usageCount, createdAt: $createdAt)';
  }
}
