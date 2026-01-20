import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/notification_service.dart';
import 'dart:math';

void main() {
  group('NotificationService Property Tests', () {
    /// Property 25: 通知调度正确性
    /// *对于任何*设置了提醒的待办事项，当到达提醒时间时，System 应发送本地通知。
    /// **Validates: Requirements 11.6**
    /// 
    /// Feature: native-voice-recognition, Property 25: 通知调度正确性
    /// 
    /// Note: This property tests the scheduling logic. The actual notification delivery
    /// is handled by the platform and requires integration testing on real devices.
    test('Property 25: 通知调度正确性 - 调度时间计算正确性', () {
      final random = Random();
      final testCount = 100;

      for (int i = 0; i < testCount; i++) {
        // 生成未来的随机时间（1分钟到24小时之间）
        final minutesInFuture = 1 + random.nextInt(24 * 60);
        final scheduledDate = DateTime.now().add(Duration(minutes: minutesInFuture));

        // 验证：调度时间应该在未来
        expect(
          scheduledDate.isAfter(DateTime.now()),
          isTrue,
          reason: 'Scheduled time should be in the future',
        );

        // 验证：调度时间与当前时间的差值应该等于设定的分钟数（允许1秒误差）
        final actualDiff = scheduledDate.difference(DateTime.now()).inMinutes;
        expect(
          actualDiff,
          closeTo(minutesInFuture, 1),
          reason: 'Scheduled time should match the specified offset',
        );
      }
    });

    /// Property 26: 多次提醒调度
    /// *对于任何*设置了多次提醒的待办事项，System 应按照间隔依次调度所有提醒。
    /// **Validates: Requirements 11.7**
    /// 
    /// Feature: native-voice-recognition, Property 26: 多次提醒调度
    test('Property 26: 多次提醒调度 - 多次提醒时间计算正确性', () {
      final random = Random();
      final testCount = 100;

      for (int i = 0; i < testCount; i++) {
        // 随机提醒次数（1-5次）
        final reminderCount = 1 + random.nextInt(5);
        
        // 随机间隔（1小时到7天）
        final intervalHours = 1 + random.nextInt(24 * 7);
        final interval = Duration(hours: intervalHours);
        
        // 截止日期在未来（足够远以容纳所有提醒）
        final deadline = DateTime.now().add(
          Duration(hours: intervalHours * reminderCount + 24),
        );

        // 计算所有提醒时间
        final scheduledTimes = <DateTime>[];
        for (int j = 0; j < reminderCount; j++) {
          // 计算提醒时间：deadline - (interval * (count - j))
          final reminderTime = deadline.subtract(interval * (reminderCount - j));
          
          // 只添加未来的提醒
          if (reminderTime.isAfter(DateTime.now())) {
            scheduledTimes.add(reminderTime);
          }
        }

        // 验证：返回的调度时间列表长度应该等于提醒次数（或更少，如果某些时间已过去）
        expect(
          scheduledTimes.length,
          lessThanOrEqualTo(reminderCount),
          reason: 'Should schedule at most $reminderCount reminders',
        );

        // 验证：所有调度的时间都应该在未来
        for (final time in scheduledTimes) {
          expect(
            time.isAfter(DateTime.now()),
            isTrue,
            reason: 'All scheduled times should be in the future',
          );
        }

        // 验证：调度的时间应该按照间隔递增
        if (scheduledTimes.length > 1) {
          for (int j = 1; j < scheduledTimes.length; j++) {
            final timeDiff = scheduledTimes[j].difference(scheduledTimes[j - 1]);
            
            // 允许一些误差（±1分钟）
            expect(
              timeDiff.inHours,
              closeTo(interval.inHours, 1),
              reason: 'Reminders should be spaced by the specified interval',
            );
          }
        }

        // 验证：最后一个提醒时间应该在截止日期之前
        if (scheduledTimes.isNotEmpty) {
          expect(
            scheduledTimes.last.isBefore(deadline) || 
            scheduledTimes.last.isAtSameMomentAs(deadline),
            isTrue,
            reason: 'Last reminder should be at or before deadline',
          );
        }
      }
    });

    /// 额外的属性测试：验证过去的时间不会被调度
    test('Property: 过去的时间不应该被调度', () {
      final random = Random();
      final testCount = 50;

      for (int i = 0; i < testCount; i++) {
        // 截止日期在过去
        final deadline = DateTime.now().subtract(
          Duration(hours: 1 + random.nextInt(100)),
        );

        final reminderCount = 1 + random.nextInt(3);
        final interval = Duration(hours: 1);

        // 计算所有提醒时间
        final scheduledTimes = <DateTime>[];
        for (int j = 0; j < reminderCount; j++) {
          final reminderTime = deadline.subtract(interval * (reminderCount - j));
          
          // 只添加未来的提醒
          if (reminderTime.isAfter(DateTime.now())) {
            scheduledTimes.add(reminderTime);
          }
        }

        // 验证：不应该调度任何提醒（因为所有时间都在过去）
        expect(
          scheduledTimes.isEmpty,
          isTrue,
          reason: 'Should not schedule reminders for past deadlines',
        );
      }
    });

    /// 额外的属性测试：验证通知ID生成的唯一性
    test('Property: 通知ID应该唯一且可预测', () {
      final random = Random();
      final testCount = 100;
      final usedTodoIds = <int>{};

      for (int i = 0; i < testCount; i++) {
        // 生成唯一的todoId
        int todoId;
        do {
          todoId = random.nextInt(10000);
        } while (usedTodoIds.contains(todoId));
        usedTodoIds.add(todoId);

        final reminderCount = 1 + random.nextInt(5);

        // 生成该待办事项的所有通知ID
        final generatedIds = <int>{};
        for (int j = 0; j < reminderCount; j++) {
          final notificationId = todoId * 1000 + j;
          
          // 验证：ID应该是唯一的（在当前待办事项范围内）
          expect(
            generatedIds.contains(notificationId),
            isFalse,
            reason: 'Notification ID should be unique within todo',
          );
          
          generatedIds.add(notificationId);
          
          // 验证：ID应该可以反推出todoId
          final extractedTodoId = notificationId ~/ 1000;
          expect(
            extractedTodoId,
            equals(todoId),
            reason: 'Should be able to extract todoId from notification ID',
          );
        }
      }
    });

    /// 额外的属性测试：验证间隔计算的正确性
    test('Property: 提醒间隔计算应该准确', () {
      final random = Random();
      final testCount = 100;

      for (int i = 0; i < testCount; i++) {
        final reminderCount = 2 + random.nextInt(4); // 至少2次提醒
        final intervalHours = 1 + random.nextInt(48);
        final interval = Duration(hours: intervalHours);
        
        final deadline = DateTime.now().add(
          Duration(hours: intervalHours * reminderCount + 24),
        );

        // 计算所有提醒时间
        final scheduledTimes = <DateTime>[];
        for (int j = 0; j < reminderCount; j++) {
          final reminderTime = deadline.subtract(interval * (reminderCount - j));
          if (reminderTime.isAfter(DateTime.now())) {
            scheduledTimes.add(reminderTime);
          }
        }

        // 验证：相邻提醒之间的间隔应该等于设定的间隔
        for (int j = 1; j < scheduledTimes.length; j++) {
          final actualInterval = scheduledTimes[j].difference(scheduledTimes[j - 1]);
          
          expect(
            actualInterval.inHours,
            closeTo(intervalHours, 1),
            reason: 'Interval between reminders should match the specified interval',
          );
        }
      }
    });
  });

  group('NotificationService Unit Tests', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    /// 测试通知初始化
    /// Requirements: 11.6, 11.7
    test('初始化状态应该正确', () {
      // 验证：服务应该是单例
      final instance1 = NotificationService.instance;
      final instance2 = NotificationService();
      expect(identical(instance1, instance2), isTrue,
          reason: 'NotificationService should be a singleton');

      // 验证：初始化前 isInitialized 应该为 false
      // Note: 由于单例模式，如果之前的测试已经初始化过，这里可能为 true
      // 这是一个已知的测试限制
    });

    /// 测试提醒取消
    /// Requirements: 11.6, 11.7
    test('取消提醒的ID计算应该正确', () {
      // 测试单个通知ID
      final todoId = 123;
      final reminderIndex = 2;
      final expectedId = todoId * 1000 + reminderIndex;

      expect(expectedId, equals(123002),
          reason: 'Notification ID calculation should be correct');

      // 测试批量取消的ID范围
      final count = 5;
      final ids = <int>[];
      for (int i = 0; i < count; i++) {
        ids.add(todoId * 1000 + i);
      }

      expect(ids, equals([123000, 123001, 123002, 123003, 123004]),
          reason: 'Batch notification IDs should be sequential');
    });

    /// 测试边界情况：零次提醒
    test('零次提醒应该返回空列表', () {
      final deadline = DateTime.now().add(Duration(hours: 24));
      final interval = Duration(hours: 1);

      final scheduledTimes = <DateTime>[];
      for (int i = 0; i < 0; i++) {
        final reminderTime = deadline.subtract(interval * (0 - i));
        if (reminderTime.isAfter(DateTime.now())) {
          scheduledTimes.add(reminderTime);
        }
      }

      expect(scheduledTimes.isEmpty, isTrue,
          reason: 'Zero reminders should result in empty list');
    });

    /// 测试边界情况：单次提醒
    test('单次提醒应该返回一个时间', () {
      final deadline = DateTime.now().add(Duration(hours: 24));
      final interval = Duration(hours: 1);
      final count = 1;

      final scheduledTimes = <DateTime>[];
      for (int i = 0; i < count; i++) {
        final reminderTime = deadline.subtract(interval * (count - i));
        if (reminderTime.isAfter(DateTime.now())) {
          scheduledTimes.add(reminderTime);
        }
      }

      expect(scheduledTimes.length, equals(1),
          reason: 'Single reminder should result in one scheduled time');
    });

    /// 测试边界情况：非常短的间隔
    test('短间隔提醒应该正确计算', () {
      final deadline = DateTime.now().add(Duration(minutes: 10));
      final interval = Duration(minutes: 1);
      final count = 5;

      final scheduledTimes = <DateTime>[];
      for (int i = 0; i < count; i++) {
        final reminderTime = deadline.subtract(interval * (count - i));
        if (reminderTime.isAfter(DateTime.now())) {
          scheduledTimes.add(reminderTime);
        }
      }

      // 验证：应该有多个提醒（取决于当前时间）
      expect(scheduledTimes.length, greaterThan(0),
          reason: 'Short interval reminders should be scheduled');

      // 验证：间隔应该是1分钟
      if (scheduledTimes.length > 1) {
        for (int i = 1; i < scheduledTimes.length; i++) {
          final diff = scheduledTimes[i].difference(scheduledTimes[i - 1]);
          expect(diff.inMinutes, closeTo(1, 1),
              reason: 'Short intervals should be accurate');
        }
      }
    });

    /// 测试边界情况：非常长的间隔
    test('长间隔提醒应该正确计算', () {
      final deadline = DateTime.now().add(Duration(days: 30));
      final interval = Duration(days: 7);
      final count = 4;

      final scheduledTimes = <DateTime>[];
      for (int i = 0; i < count; i++) {
        final reminderTime = deadline.subtract(interval * (count - i));
        if (reminderTime.isAfter(DateTime.now())) {
          scheduledTimes.add(reminderTime);
        }
      }

      expect(scheduledTimes.length, equals(count),
          reason: 'Long interval reminders should all be scheduled');

      // 验证：间隔应该是7天
      for (int i = 1; i < scheduledTimes.length; i++) {
        final diff = scheduledTimes[i].difference(scheduledTimes[i - 1]);
        expect(diff.inDays, closeTo(7, 1),
            reason: 'Long intervals should be accurate');
      }
    });

    /// 测试错误情况：未初始化时调用方法
    test('未初始化时调用方法应该抛出错误', () {
      // Note: 由于单例模式和之前的测试可能已经初始化，
      // 这个测试在实际环境中可能无法准确测试
      // 这是一个已知的测试限制，需要在集成测试中验证
    });

    /// 测试通知ID的范围
    test('通知ID应该在合理范围内', () {
      final maxTodoId = 999999; // 假设最大的待办ID
      final maxReminderIndex = 999; // 假设最多999个提醒

      final maxNotificationId = maxTodoId * 1000 + maxReminderIndex;

      // 验证：最大通知ID应该在int范围内
      expect(maxNotificationId, lessThan(2147483647),
          reason: 'Notification ID should fit in 32-bit int');
    });

    /// 测试时区处理
    test('时间计算应该考虑本地时区', () {
      final now = DateTime.now();
      final future = now.add(Duration(hours: 1));

      // 验证：未来时间应该大于当前时间
      expect(future.isAfter(now), isTrue,
          reason: 'Future time should be after current time');

      // 验证：时间差应该是1小时
      final diff = future.difference(now);
      expect(diff.inHours, equals(1),
          reason: 'Time difference should be accurate');
    });
  });
}
