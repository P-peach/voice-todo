import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/voice_recognition_service.dart';
import 'package:voice_todo/services/todo_parser_service.dart';
import 'package:voice_todo/services/sqlite_service.dart';
import 'package:voice_todo/services/notification_service.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/models/reminder_config.dart';

/// 端到端集成测试
///
/// 测试完整的语音识别到待办创建流程
void main() {
  group('End-to-End Integration Tests', () {
    late TodoParserService parserService;
    late SqliteService sqliteService;

    setUp(() async {
      // 初始化服务
      parserService = TodoParserService.instance;
      sqliteService = SqliteService.instance;
      
      // 初始化数据库
      await SqliteService.initialize();
      
      // 清空数据库
      await sqliteService.clearAllTodos();
    });

    tearDown(() async {
      // 清理测试数据
      await sqliteService.clearAllTodos();
    });

    group('1. 完整的语音识别到待办创建流程', () {
      test('单个待办事项：解析 -> 保存 -> 验证', () async {
        // 模拟语音识别结果
        const recognizedText = '明天上午开会讨论项目进度';

        // 步骤1: 解析文本
        final todos = parserService.parse(recognizedText);

        // 验证解析结果
        expect(todos, isNotEmpty);
        expect(todos.length, 1);
        expect(todos.first.title, contains('开会'));
        expect(todos.first.category, '工作');
        expect(todos.first.deadline, isNotNull);
        expect(todos.first.isVoiceCreated, true);

        // 步骤2: 保存到数据库
        final todoId = await sqliteService.insertTodo(todos.first);
        expect(todoId, isNotEmpty);

        // 步骤3: 从数据库读取验证
        final savedTodo = await sqliteService.getTodoById(todoId);
        expect(savedTodo, isNotNull);
        expect(savedTodo!.title, todos.first.title);
        expect(savedTodo.category, todos.first.category);
        expect(savedTodo.isVoiceCreated, true);

        // 步骤4: 验证数据完整性
        expect(savedTodo.id, todoId);
        expect(savedTodo.deadline, isNotNull);
        expect(savedTodo.createdAt, isNotNull);
      });

      test('带时间和分类的待办事项：完整流程', () async {
        const recognizedText = '后天下午3点去超市买菜';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos, isNotEmpty);
        expect(todos.first.title, contains('买菜'));
        expect(todos.first.category, '购物');
        expect(todos.first.deadline, isNotNull);

        // 保存
        await sqliteService.insertTodo(todos.first);

        // 验证：按分类查询
        final shoppingTodos = await sqliteService.getTodosByCategory('购物');
        expect(shoppingTodos, isNotEmpty);
        expect(shoppingTodos.any((t) => t.title.contains('买菜')), true);
      });

      test('带优先级的待办事项：完整流程', () async {
        const recognizedText = '紧急！马上处理项目报告';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos, isNotEmpty);
        expect(todos.first.priority, '高');
        expect(todos.first.category, '工作');

        // 保存
        await sqliteService.insertTodo(todos.first);

        // 验证：按优先级查询
        final highPriorityTodos = await sqliteService.getTodosByPriority('高');
        expect(highPriorityTodos, isNotEmpty);
        expect(highPriorityTodos.any((t) => t.title.contains('项目报告')), true);
      });
    });

    group('2. 列表模式的完整流程', () {
      test('购物清单：解析 -> 批量保存 -> 验证', () async {
        const recognizedText = '去超市买苹果两箱，茼蒿10把，草莓，土豆一箱';

        // 步骤1: 解析列表
        final todos = parserService.parse(recognizedText);

        // 验证解析结果
        expect(todos.length, 4);
        expect(todos[0].title, contains('苹果'));
        expect(todos[0].title, contains('两箱'));
        expect(todos[1].title, contains('茼蒿'));
        expect(todos[1].title, contains('10把'));
        expect(todos[2].title, contains('草莓'));
        expect(todos[3].title, contains('土豆'));
        expect(todos[3].title, contains('一箱'));

        // 验证所有项共享分类
        expect(todos.every((t) => t.category == '购物'), true);
        expect(todos.every((t) => t.isVoiceCreated), true);

        // 步骤2: 修复ID冲突（为每个待办生成唯一ID）
        final todosWithUniqueIds = <TodoItem>[];
        for (var i = 0; i < todos.length; i++) {
          await Future.delayed(const Duration(milliseconds: 2)); // 确保ID唯一
          final todo = todos[i];
          todosWithUniqueIds.add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            description: todo.description,
            category: todo.category,
            priority: todo.priority,
            deadline: todo.deadline,
            createdAt: todo.createdAt,
            isVoiceCreated: todo.isVoiceCreated,
          ));
        }

        // 步骤3: 批量保存
        await sqliteService.insertTodos(todosWithUniqueIds);

        // 步骤4: 验证保存结果
        final allTodos = await sqliteService.getAllTodos();
        expect(allTodos.length, greaterThanOrEqualTo(4));

        // 验证每个项都被保存
        expect(allTodos.any((t) => t.title.contains('苹果')), true);
        expect(allTodos.any((t) => t.title.contains('茼蒿')), true);
        expect(allTodos.any((t) => t.title.contains('草莓')), true);
        expect(allTodos.any((t) => t.title.contains('土豆')), true);
      });

      test('列表模式带时间：共享属性验证', () async {
        const recognizedText = '明天去超市买苹果，香蕉，橙子';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos.length, 3);

        // 验证共享属性
        expect(todos.every((t) => t.category == '购物'), true);
        expect(todos.every((t) => t.deadline != null), true);

        // 验证所有项的截止日期相同
        final firstDeadline = todos.first.deadline;
        expect(todos.every((t) => t.deadline?.day == firstDeadline?.day), true);

        // 修复ID冲突
        final todosWithUniqueIds = <TodoItem>[];
        for (var i = 0; i < todos.length; i++) {
          await Future.delayed(const Duration(milliseconds: 2));
          final todo = todos[i];
          todosWithUniqueIds.add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            description: todo.description,
            category: todo.category,
            priority: todo.priority,
            deadline: todo.deadline,
            createdAt: todo.createdAt,
            isVoiceCreated: todo.isVoiceCreated,
          ));
        }

        // 批量保存
        await sqliteService.insertTodos(todosWithUniqueIds);

        // 验证
        final shoppingTodos = await sqliteService.getTodosByCategory('购物');
        expect(shoppingTodos.length, greaterThanOrEqualTo(3));
      });

      test('列表模式数量信息保留', () async {
        const recognizedText = '买苹果5斤，香蕉3串，橙子一箱';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos.length, 3);

        // 验证数量信息被保留在标题中
        expect(todos[0].title, contains('5斤'));
        expect(todos[1].title, contains('3串'));
        expect(todos[2].title, contains('一箱'));

        // 修复ID冲突
        final todosWithUniqueIds = <TodoItem>[];
        for (var i = 0; i < todos.length; i++) {
          await Future.delayed(const Duration(milliseconds: 2));
          final todo = todos[i];
          todosWithUniqueIds.add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            description: todo.description,
            category: todo.category,
            priority: todo.priority,
            deadline: todo.deadline,
            createdAt: todo.createdAt,
            isVoiceCreated: todo.isVoiceCreated,
          ));
        }

        // 保存并验证
        await sqliteService.insertTodos(todosWithUniqueIds);
        final allTodos = await sqliteService.getAllTodos();
        
        expect(allTodos.any((t) => t.title.contains('5斤')), true);
        expect(allTodos.any((t) => t.title.contains('3串')), true);
        expect(allTodos.any((t) => t.title.contains('一箱')), true);
      });

      test('列表模式无数量项处理', () async {
        const recognizedText = '买苹果，香蕉，橙子';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos.length, 3);

        // 验证所有项都被创建，即使没有数量
        expect(todos[0].title, contains('苹果'));
        expect(todos[1].title, contains('香蕉'));
        expect(todos[2].title, contains('橙子'));

        // 修复ID冲突
        final todosWithUniqueIds = <TodoItem>[];
        for (var i = 0; i < todos.length; i++) {
          await Future.delayed(const Duration(milliseconds: 2));
          final todo = todos[i];
          todosWithUniqueIds.add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            description: todo.description,
            category: todo.category,
            priority: todo.priority,
            deadline: todo.deadline,
            createdAt: todo.createdAt,
            isVoiceCreated: todo.isVoiceCreated,
          ));
        }

        // 保存
        await sqliteService.insertTodos(todosWithUniqueIds);

        // 验证
        final allTodos = await sqliteService.getAllTodos();
        expect(allTodos.length, greaterThanOrEqualTo(3));
      });
    });

    group('3. 提醒设置的完整流程', () {
      test('带提醒关键词的待办：解析 -> 保存 -> 验证', () async {
        const recognizedText = '提醒我明天下午3点开会';

        // 解析
        final todos = parserService.parse(recognizedText);
        expect(todos, isNotEmpty);
        expect(todos.first.title, contains('开会'));
        expect(todos.first.deadline, isNotNull);

        // 创建带提醒配置的待办
        final todoWithReminder = TodoItem(
          id: todos.first.id,
          title: todos.first.title,
          description: todos.first.description,
          category: todos.first.category,
          priority: todos.first.priority,
          deadline: todos.first.deadline,
          createdAt: todos.first.createdAt,
          isVoiceCreated: todos.first.isVoiceCreated,
          reminderConfig: ReminderConfig(
            count: 2,
            interval: const Duration(hours: 1),
            scheduledTimes: [
              todos.first.deadline!.subtract(const Duration(hours: 2)),
              todos.first.deadline!.subtract(const Duration(hours: 1)),
            ],
          ),
        );

        // 保存
        await sqliteService.insertTodo(todoWithReminder);

        // 验证
        final savedTodo = await sqliteService.getTodoById(todoWithReminder.id);
        expect(savedTodo, isNotNull);
        expect(savedTodo!.reminderConfig, isNotNull);
        expect(savedTodo.reminderConfig!.count, 2);
        expect(savedTodo.reminderConfig!.interval, const Duration(hours: 1));
        expect(savedTodo.reminderConfig!.scheduledTimes.length, 2);
      });

      test('提醒配置序列化和反序列化', () async {
        final deadline = DateTime.now().add(const Duration(days: 1));
        final reminderConfig = ReminderConfig(
          count: 3,
          interval: const Duration(hours: 24),
          scheduledTimes: [
            deadline.subtract(const Duration(days: 3)),
            deadline.subtract(const Duration(days: 2)),
            deadline.subtract(const Duration(days: 1)),
          ],
        );

        final todo = TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '重要会议',
          category: '工作',
          priority: '高',
          deadline: deadline,
          createdAt: DateTime.now(),
          isVoiceCreated: true,
          reminderConfig: reminderConfig,
        );

        // 保存
        await sqliteService.insertTodo(todo);

        // 读取
        final savedTodo = await sqliteService.getTodoById(todo.id);
        expect(savedTodo, isNotNull);
        expect(savedTodo!.reminderConfig, isNotNull);
        expect(savedTodo.reminderConfig!.count, 3);
        expect(savedTodo.reminderConfig!.interval.inHours, 24);
        expect(savedTodo.reminderConfig!.scheduledTimes.length, 3);
      });
    });

    group('4. 复杂场景集成测试', () {
      test('多个待办事项混合场景', () async {
        const recognizedText = '明天开项目会议。后天去超市买菜。下周五提交工作报告';

        // 解析
        final todos = parserService.parse(recognizedText);
        
        // 验证至少解析出多个待办
        expect(todos.length, greaterThanOrEqualTo(2));

        // 验证有购物类别的待办
        final shoppingTodos = todos.where((t) => t.category == '购物').toList();
        expect(shoppingTodos.length, greaterThanOrEqualTo(1));

        // 修复ID冲突
        final todosWithUniqueIds = <TodoItem>[];
        for (var i = 0; i < todos.length; i++) {
          await Future.delayed(const Duration(milliseconds: 2));
          final todo = todos[i];
          todosWithUniqueIds.add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            description: todo.description,
            category: todo.category,
            priority: todo.priority,
            deadline: todo.deadline,
            createdAt: todo.createdAt,
            isVoiceCreated: todo.isVoiceCreated,
          ));
        }

        // 批量保存
        await sqliteService.insertTodos(todosWithUniqueIds);

        // 验证统计
        final stats = await sqliteService.getTodoStatistics();
        expect(stats['totalCount'], greaterThanOrEqualTo(2));
        expect(stats['incompleteCount'], greaterThanOrEqualTo(2));
        expect(stats['categoryStats'], isNotEmpty);
      });

      test('数据持久化和加载', () async {
        // 创建多个待办
        final todos = [
          TodoItem(
            id: '1',
            title: '开会',
            category: '工作',
            priority: '高',
            deadline: DateTime.now().add(const Duration(days: 1)),
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
          TodoItem(
            id: '2',
            title: '买菜',
            category: '购物',
            priority: '中',
            deadline: DateTime.now().add(const Duration(days: 2)),
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
          TodoItem(
            id: '3',
            title: '运动',
            category: '健康',
            priority: '低',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
        ];

        // 保存
        await sqliteService.insertTodos(todos);

        // 模拟应用重启：重新加载
        final loadedTodos = await sqliteService.getAllTodos();
        expect(loadedTodos.length, greaterThanOrEqualTo(3));

        // 验证数据完整性
        for (final original in todos) {
          final loaded = loadedTodos.firstWhere((t) => t.id == original.id);
          expect(loaded.title, original.title);
          expect(loaded.category, original.category);
          expect(loaded.priority, original.priority);
          expect(loaded.isVoiceCreated, original.isVoiceCreated);
        }
      });

      test('搜索功能集成', () async {
        // 创建测试数据
        final todos = [
          TodoItem(
            id: '1',
            title: '开会讨论项目',
            category: '工作',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
          TodoItem(
            id: '2',
            title: '项目进度汇报',
            category: '工作',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
          TodoItem(
            id: '3',
            title: '买菜做饭',
            category: '生活',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
        ];

        await sqliteService.insertTodos(todos);

        // 搜索"项目"
        final searchResults = await sqliteService.searchTodos('项目');
        expect(searchResults.length, 2);
        expect(searchResults.every((t) => t.title.contains('项目')), true);
      });

      test('完成状态更新流程', () async {
        // 创建待办
        final todo = TodoItem(
          id: '1',
          title: '测试任务',
          category: '工作',
          createdAt: DateTime.now(),
          isVoiceCreated: true,
        );

        await sqliteService.insertTodo(todo);

        // 标记为完成
        final completedTodo = TodoItem(
          id: todo.id,
          title: todo.title,
          category: todo.category,
          priority: todo.priority,
          deadline: todo.deadline,
          createdAt: todo.createdAt,
          isCompleted: true,
          completedAt: DateTime.now(),
          isVoiceCreated: todo.isVoiceCreated,
        );

        await sqliteService.updateTodo(completedTodo);

        // 验证
        final updated = await sqliteService.getTodoById(todo.id);
        expect(updated, isNotNull);
        expect(updated!.isCompleted, true);
        expect(updated.completedAt, isNotNull);

        // 验证统计
        final stats = await sqliteService.getTodoStatistics();
        expect(stats['completedCount'], greaterThanOrEqualTo(1));
      });
    });

    group('5. 错误处理和边界情况', () {
      test('空文本处理', () async {
        final todos = parserService.parse('');
        expect(todos, isEmpty);

        final todos2 = parserService.parse('   ');
        expect(todos2, isEmpty);
      });

      test('无效待办事项处理', () async {
        // 只有标点符号
        final todos = parserService.parse('，。；');
        expect(todos, isEmpty);
      });

      test('数据库错误恢复', () async {
        // 尝试获取不存在的待办
        final nonExistent = await sqliteService.getTodoById('non-existent-id');
        expect(nonExistent, isNull);

        // 尝试删除不存在的待办（应该不抛出异常）
        await sqliteService.deleteTodo('non-existent-id');
      });

      test('批量操作空列表', () async {
        // 批量插入空列表
        await sqliteService.insertTodos([]);

        // 批量删除空列表
        await sqliteService.deleteTodos([]);

        // 验证数据库状态
        final todos = await sqliteService.getAllTodos();
        expect(todos, isEmpty);
      });
    });

    group('6. 性能和并发测试', () {
      test('大量待办事项处理', () async {
        // 创建100个待办事项
        final todos = List.generate(
          100,
          (i) => TodoItem(
            id: 'perf-test-$i',
            title: '测试任务 $i',
            category: i % 2 == 0 ? '工作' : '生活',
            priority: i % 3 == 0 ? '高' : '中',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
        );

        // 批量保存
        final stopwatch = Stopwatch()..start();
        await sqliteService.insertTodos(todos);
        stopwatch.stop();

        // 验证性能（应该在合理时间内完成）
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内

        // 验证数据
        final allTodos = await sqliteService.getAllTodos();
        expect(allTodos.length, greaterThanOrEqualTo(100));

        // 清理
        await sqliteService.clearAllTodos();
      });

      test('并发查询', () async {
        // 创建测试数据
        final todos = List.generate(
          20,
          (i) => TodoItem(
            id: 'concurrent-$i',
            title: '任务 $i',
            category: '工作',
            createdAt: DateTime.now(),
            isVoiceCreated: true,
          ),
        );

        await sqliteService.insertTodos(todos);

        // 并发执行多个查询
        final futures = [
          sqliteService.getAllTodos(),
          sqliteService.getTodosByCategory('工作'),
          sqliteService.getIncompleteTodos(),
          sqliteService.getTodoStatistics(),
        ];

        final results = await Future.wait(futures);

        // 验证所有查询都成功
        expect(results[0], isNotEmpty); // getAllTodos
        expect(results[1], isNotEmpty); // getTodosByCategory
        expect(results[2], isNotEmpty); // getIncompleteTodos
        expect(results[3], isNotEmpty); // getTodoStatistics
      });
    });
  });
}
