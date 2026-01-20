import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/models/reminder_config.dart';
import 'dart:math';

void main() {
  group('TodoItem Serialization Property Tests', () {
    // **Property 30: TodoItem 序列化 Round-Trip**
    // **Validates: Requirements 12.4, 12.5**
    test('Property 30: TodoItem serialization round-trip preserves all fields',
        () {
      final random = Random(42);

      // Run 100 iterations with random TodoItem instances
      for (int i = 0; i < 100; i++) {
        final original = _generateRandomTodoItem(random);

        // Serialize to Map and back
        final map = original.toMap();
        final fromMap = TodoItem.fromMap(map);

        // Verify all fields are preserved
        expect(fromMap.id, original.id, reason: 'id should be preserved');
        expect(fromMap.title, original.title,
            reason: 'title should be preserved');
        expect(fromMap.description, original.description,
            reason: 'description should be preserved');
        expect(fromMap.category, original.category,
            reason: 'category should be preserved');
        expect(fromMap.priority, original.priority,
            reason: 'priority should be preserved');
        expect(fromMap.isCompleted, original.isCompleted,
            reason: 'isCompleted should be preserved');
        expect(fromMap.isVoiceCreated, original.isVoiceCreated,
            reason: 'isVoiceCreated should be preserved');

        // Compare DateTime fields (allowing for millisecond precision)
        if (original.deadline != null) {
          expect(fromMap.deadline, isNotNull,
              reason: 'deadline should not be null');
          expect(
              fromMap.deadline!.millisecondsSinceEpoch,
              original.deadline!.millisecondsSinceEpoch,
              reason: 'deadline should be preserved');
        } else {
          expect(fromMap.deadline, isNull, reason: 'deadline should be null');
        }

        expect(
            fromMap.createdAt.millisecondsSinceEpoch,
            original.createdAt.millisecondsSinceEpoch,
            reason: 'createdAt should be preserved');

        if (original.completedAt != null) {
          expect(fromMap.completedAt, isNotNull,
              reason: 'completedAt should not be null');
          expect(
              fromMap.completedAt!.millisecondsSinceEpoch,
              original.completedAt!.millisecondsSinceEpoch,
              reason: 'completedAt should be preserved');
        } else {
          expect(fromMap.completedAt, isNull,
              reason: 'completedAt should be null');
        }

        // Compare ReminderConfig
        if (original.reminderConfig != null) {
          expect(fromMap.reminderConfig, isNotNull,
              reason: 'reminderConfig should not be null');
          expect(fromMap.reminderConfig!.count, original.reminderConfig!.count,
              reason: 'reminderConfig.count should be preserved');
          expect(
              fromMap.reminderConfig!.interval.inMilliseconds,
              original.reminderConfig!.interval.inMilliseconds,
              reason: 'reminderConfig.interval should be preserved');
          expect(
              fromMap.reminderConfig!.scheduledTimes.length,
              original.reminderConfig!.scheduledTimes.length,
              reason: 'reminderConfig.scheduledTimes length should be preserved');
          for (int j = 0;
              j < original.reminderConfig!.scheduledTimes.length;
              j++) {
            expect(
                fromMap.reminderConfig!.scheduledTimes[j]
                    .millisecondsSinceEpoch,
                original.reminderConfig!.scheduledTimes[j]
                    .millisecondsSinceEpoch,
                reason:
                    'reminderConfig.scheduledTimes[$j] should be preserved');
          }
        } else {
          expect(fromMap.reminderConfig, isNull,
              reason: 'reminderConfig should be null');
        }
      }
    });

    test(
        'Property 30: TodoItem JSON serialization round-trip preserves all fields',
        () {
      final random = Random(43);

      // Run 100 iterations with random TodoItem instances
      for (int i = 0; i < 100; i++) {
        final original = _generateRandomTodoItem(random);

        // Serialize to JSON and back
        final json = original.toJson();
        final fromJson = TodoItem.fromJson(json);

        // Verify all fields are preserved
        expect(fromJson.id, original.id, reason: 'id should be preserved');
        expect(fromJson.title, original.title,
            reason: 'title should be preserved');
        expect(fromJson.description, original.description,
            reason: 'description should be preserved');
        expect(fromJson.category, original.category,
            reason: 'category should be preserved');
        expect(fromJson.priority, original.priority,
            reason: 'priority should be preserved');
        expect(fromJson.isCompleted, original.isCompleted,
            reason: 'isCompleted should be preserved');
        expect(fromJson.isVoiceCreated, original.isVoiceCreated,
            reason: 'isVoiceCreated should be preserved');

        // Compare DateTime fields
        if (original.deadline != null) {
          expect(fromJson.deadline, isNotNull,
              reason: 'deadline should not be null');
          expect(
              fromJson.deadline!.millisecondsSinceEpoch,
              original.deadline!.millisecondsSinceEpoch,
              reason: 'deadline should be preserved');
        } else {
          expect(fromJson.deadline, isNull, reason: 'deadline should be null');
        }

        expect(
            fromJson.createdAt.millisecondsSinceEpoch,
            original.createdAt.millisecondsSinceEpoch,
            reason: 'createdAt should be preserved');

        if (original.completedAt != null) {
          expect(fromJson.completedAt, isNotNull,
              reason: 'completedAt should not be null');
          expect(
              fromJson.completedAt!.millisecondsSinceEpoch,
              original.completedAt!.millisecondsSinceEpoch,
              reason: 'completedAt should be preserved');
        } else {
          expect(fromJson.completedAt, isNull,
              reason: 'completedAt should be null');
        }

        // Compare ReminderConfig
        if (original.reminderConfig != null) {
          expect(fromJson.reminderConfig, isNotNull,
              reason: 'reminderConfig should not be null');
          expect(fromJson.reminderConfig!.count, original.reminderConfig!.count,
              reason: 'reminderConfig.count should be preserved');
          expect(
              fromJson.reminderConfig!.interval.inMilliseconds,
              original.reminderConfig!.interval.inMilliseconds,
              reason: 'reminderConfig.interval should be preserved');
          expect(
              fromJson.reminderConfig!.scheduledTimes.length,
              original.reminderConfig!.scheduledTimes.length,
              reason: 'reminderConfig.scheduledTimes length should be preserved');
          for (int j = 0;
              j < original.reminderConfig!.scheduledTimes.length;
              j++) {
            expect(
                fromJson.reminderConfig!.scheduledTimes[j]
                    .millisecondsSinceEpoch,
                original.reminderConfig!.scheduledTimes[j]
                    .millisecondsSinceEpoch,
                reason:
                    'reminderConfig.scheduledTimes[$j] should be preserved');
          }
        } else {
          expect(fromJson.reminderConfig, isNull,
              reason: 'reminderConfig should be null');
        }
      }
    });
  });
}

// Helper function to generate random TodoItem instances
TodoItem _generateRandomTodoItem(Random random) {
  final categories = ['工作', '购物', '学习', '生活', '健康', '其他'];
  final priorities = ['高', '中', '低'];

  final hasDeadline = random.nextBool();
  final hasCompletedAt = random.nextBool();
  final hasReminderConfig = random.nextBool();

  return TodoItem(
    id: 'todo_${random.nextInt(100000)}',
    title: 'Task ${random.nextInt(1000)}',
    description: random.nextBool() ? 'Description ${random.nextInt(100)}' : '',
    category: categories[random.nextInt(categories.length)],
    priority: priorities[random.nextInt(priorities.length)],
    isCompleted: random.nextBool(),
    deadline: hasDeadline
        ? DateTime.now().add(Duration(days: random.nextInt(30)))
        : null,
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(100))),
    completedAt: hasCompletedAt
        ? DateTime.now().subtract(Duration(days: random.nextInt(10)))
        : null,
    isVoiceCreated: random.nextBool(),
    reminderConfig: hasReminderConfig
        ? ReminderConfig(
            count: random.nextInt(5) + 1,
            interval: Duration(hours: random.nextInt(24) + 1),
            scheduledTimes: List.generate(
              random.nextInt(3),
              (index) => DateTime.now().add(Duration(hours: index + 1)),
            ),
          )
        : null,
  );
}
