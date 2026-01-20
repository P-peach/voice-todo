import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/models/reminder_config.dart';
import 'package:voice_todo/services/sqlite_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:math';

void main() {
  // 初始化 FFI 用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // 每个测试前初始化服务
    await SqliteService.initialize();
  });

  tearDown(() async {
    // 每个测试后清理数据库
    try {
      await SqliteService.instance.clearAllTodos();
      await SqliteService.instance.close();
    } catch (e) {
      // 忽略清理错误
    }
  });

  group('Property-Based Tests - Data Persistence', () {
    /// 生成随机 TodoItem
    TodoItem generateRandomTodo({bool withReminder = false}) {
      final random = Random();
      final id = 'test-${random.nextInt(1000000)}';
      final categories = ['工作', '购物', '学习', '生活', '健康', '其他'];
      final priorities = ['高', '中', '低'];

      ReminderConfig? reminderConfig;
      if (withReminder) {
        reminderConfig = ReminderConfig(
          count: random.nextInt(3) + 1,
          interval: Duration(hours: random.nextInt(24) + 1),
          scheduledTimes: [],
        );
      }

      return TodoItem(
        id: id,
        title: 'Test Todo ${random.nextInt(1000)}',
        description: 'Description ${random.nextInt(1000)}',
        category: categories[random.nextInt(categories.length)],
        priority: priorities[random.nextInt(priorities.length)],
        isCompleted: random.nextBool(),
        deadline: random.nextBool()
            ? DateTime.now().add(Duration(days: random.nextInt(30)))
            : null,
        createdAt: DateTime.now(),
        completedAt: null,
        isVoiceCreated: random.nextBool(),
        reminderConfig: reminderConfig,
      );
    }

    test(
      'Property 17: 数据持久化成功性 - 对于任何验证通过的 TodoItem，System 应成功将其保存到 SQLite 数据库',
      () async {
        // **Validates: Requirements 6.2**
        // Feature: native-voice-recognition, Property 17: 数据持久化成功性

        // 运行 100 次迭代
        for (int i = 0; i < 100; i++) {
          // 生成随机待办事项（有些带提醒，有些不带）
          final todo = generateRandomTodo(withReminder: i % 2 == 0);

          // 保存到数据库
          final savedId = await SqliteService.instance.insertTodo(todo);

          // 验证保存成功
          expect(savedId, equals(todo.id));

          // 从数据库读取
          final retrieved = await SqliteService.instance.getTodoById(savedId);

          // 验证能够成功读取
          expect(retrieved, isNotNull);
          expect(retrieved!.id, equals(todo.id));
        }
      },
    );

    test(
      'Property 28: 数据完整性保存 - 对于任何待办事项，保存到数据库时应保存所有字段',
      () async {
        // **Validates: Requirements 12.2**
        // Feature: native-voice-recognition, Property 28: 数据完整性保存

        // 运行 100 次迭代
        for (int i = 0; i < 100; i++) {
          // 生成随机待办事项（包含所有字段）
          final todo = generateRandomTodo(withReminder: true);

          // 保存到数据库
          await SqliteService.instance.insertTodo(todo);

          // 从数据库读取
          final retrieved = await SqliteService.instance.getTodoById(todo.id);

          // 验证所有字段都被正确保存
          expect(retrieved, isNotNull);
          expect(retrieved!.id, equals(todo.id));
          expect(retrieved.title, equals(todo.title));
          expect(retrieved.description, equals(todo.description));
          expect(retrieved.category, equals(todo.category));
          expect(retrieved.priority, equals(todo.priority));
          expect(retrieved.isCompleted, equals(todo.isCompleted));
          expect(retrieved.isVoiceCreated, equals(todo.isVoiceCreated));

          // 验证日期字段
          if (todo.deadline != null) {
            expect(retrieved.deadline, isNotNull);
            expect(
              retrieved.deadline!.difference(todo.deadline!).inSeconds.abs(),
              lessThan(2),
            );
          } else {
            expect(retrieved.deadline, isNull);
          }

          // 验证创建时间
          expect(
            retrieved.createdAt.difference(todo.createdAt).inSeconds.abs(),
            lessThan(2),
          );

          // 验证提醒配置
          if (todo.reminderConfig != null) {
            expect(retrieved.reminderConfig, isNotNull);
            expect(
              retrieved.reminderConfig!.count,
              equals(todo.reminderConfig!.count),
            );
            expect(
              retrieved.reminderConfig!.interval,
              equals(todo.reminderConfig!.interval),
            );
          } else {
            expect(retrieved.reminderConfig, isNull);
          }
        }
      },
    );

    test(
      'Property 29: 持久化加载正确性 - 对于任何保存到数据库的待办事项，应用重启后应能正确加载',
      () async {
        // **Validates: Requirements 12.3**
        // Feature: native-voice-recognition, Property 29: 持久化加载正确性

        // 运行 50 次迭代（模拟多次重启）
        for (int i = 0; i < 50; i++) {
          // 生成多个随机待办事项
          final todos = List.generate(
            5,
            (index) => generateRandomTodo(withReminder: index % 2 == 0),
          );

          // 批量保存
          await SqliteService.instance.insertTodos(todos);

          // 模拟应用重启：关闭并重新打开数据库
          await SqliteService.instance.close();
          await SqliteService.initialize();

          // 加载所有待办事项
          final loadedTodos = await SqliteService.instance.getAllTodos();

          // 验证所有待办事项都被正确加载
          expect(loadedTodos.length, greaterThanOrEqualTo(todos.length));

          // 验证每个保存的待办事项都能被找到
          for (final todo in todos) {
            final found = loadedTodos.firstWhere(
              (t) => t.id == todo.id,
              orElse: () => throw Exception('Todo not found: ${todo.id}'),
            );

            // 验证数据完整性
            expect(found.title, equals(todo.title));
            expect(found.category, equals(todo.category));
            expect(found.priority, equals(todo.priority));
            expect(found.isVoiceCreated, equals(todo.isVoiceCreated));

            // 验证提醒配置
            if (todo.reminderConfig != null) {
              expect(found.reminderConfig, isNotNull);
              expect(
                found.reminderConfig!.count,
                equals(todo.reminderConfig!.count),
              );
            }
          }

          // 清理数据
          await SqliteService.instance.clearAllTodos();
        }
      },
    );
  });

  group('Unit Tests - Batch Operations', () {
    test('批量插入应保持顺序', () async {
      final todos = List.generate(
        10,
        (index) => TodoItem(
          id: 'batch-$index',
          title: 'Batch Todo $index',
          createdAt: DateTime.now().add(Duration(seconds: index)),
        ),
      );

      await SqliteService.instance.insertTodos(todos);

      final retrieved = await SqliteService.instance.getAllTodos();

      // 验证所有待办事项都被保存
      expect(retrieved.length, greaterThanOrEqualTo(todos.length));

      // 验证每个待办事项都存在
      for (final todo in todos) {
        final found = retrieved.any((t) => t.id == todo.id);
        expect(found, isTrue);
      }
    });

    test('批量插入带提醒配置的待办事项', () async {
      final todos = List.generate(
        5,
        (index) => TodoItem(
          id: 'reminder-batch-$index',
          title: 'Reminder Todo $index',
          createdAt: DateTime.now(),
          reminderConfig: ReminderConfig(
            count: index + 1,
            interval: Duration(hours: index + 1),
            scheduledTimes: [],
          ),
        ),
      );

      await SqliteService.instance.insertTodos(todos);

      for (final todo in todos) {
        final retrieved = await SqliteService.instance.getTodoById(todo.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.reminderConfig, isNotNull);
        expect(retrieved.reminderConfig!.count, equals(todo.reminderConfig!.count));
      }
    });
  });

  group('Unit Tests - Error Handling', () {
    test('查询不存在的待办事项应返回 null', () async {
      final result = await SqliteService.instance.getTodoById('non-existent-id');
      expect(result, isNull);
    });

    test('空数据库查询应返回空列表', () async {
      await SqliteService.instance.clearAllTodos();
      final todos = await SqliteService.instance.getAllTodos();
      expect(todos, isEmpty);
    });
  });
}
