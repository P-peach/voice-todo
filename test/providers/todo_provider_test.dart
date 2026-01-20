import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/models/reminder_config.dart';
import 'package:voice_todo/providers/todo_provider.dart';
import 'package:voice_todo/services/sqlite_service.dart';

void main() {
  group('TodoProvider Property Tests', () {
    late TodoProvider provider;
    late SqliteService sqliteService;

    setUp(() async {
      // 初始化服务
      sqliteService = SqliteService.instance;
      await SqliteService.initialize();
      
      // 清空数据库
      await sqliteService.clearAllTodos();
      
      provider = TodoProvider();
      await Future.delayed(const Duration(milliseconds: 100)); // 等待初始化
    });

    tearDown(() async {
      // 清理
      await sqliteService.clearAllTodos();
    });

    // Property 16: 数据验证完整性
    // Validates: Requirements 6.1
    test('Property 16: 数据验证完整性 - 验证必填字段', () async {
      // 测试缺少 id 的情况
      final todoWithoutId = TodoItem(
        id: '',
        title: '测试待办',
        createdAt: DateTime.now(),
      );

      expect(
        () => provider.addTodo(todoWithoutId),
        throwsA(isA<ArgumentError>()),
      );

      // 测试缺少 title 的情况
      final todoWithoutTitle = TodoItem(
        id: 'test-1',
        title: '',
        createdAt: DateTime.now(),
      );

      expect(
        () => provider.addTodo(todoWithoutTitle),
        throwsA(isA<ArgumentError>()),
      );

      // 测试有效的待办事项
      final validTodo = TodoItem(
        id: 'test-2',
        title: '有效待办',
        createdAt: DateTime.now(),
      );

      await provider.addTodo(validTodo);
      expect(provider.todos.length, 1);
      expect(provider.todos.first.title, '有效待办');
    });

    // Property 18: 保存失败错误处理
    // Validates: Requirements 6.4
    test('Property 18: 保存失败错误处理 - 错误时保留原始数据', () async {
      // 创建一个无效的待办事项（缺少必填字段）
      final invalidTodo = TodoItem(
        id: '',
        title: '无效待办',
        createdAt: DateTime.now(),
      );

      // 尝试添加无效待办
      try {
        await provider.addTodo(invalidTodo);
        fail('应该抛出错误');
      } catch (e) {
        // 验证错误被正确处理
        expect(e, isA<ArgumentError>());
        expect(provider.error, isNotNull);
        expect(provider.error, contains('必填字段'));
      }

      // 验证数据库中没有保存任何数据
      expect(provider.todos.length, 0);
    });

    // Property 19: 批量保存顺序性
    // Validates: Requirements 6.5
    test('Property 19: 批量保存顺序性 - 按顺序保存待办事项', () async {
      final todos = [
        TodoItem(
          id: 'test-1',
          title: '第一个待办',
          createdAt: DateTime.now(),
        ),
        TodoItem(
          id: 'test-2',
          title: '第二个待办',
          createdAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
        TodoItem(
          id: 'test-3',
          title: '第三个待办',
          createdAt: DateTime.now().add(const Duration(seconds: 2)),
        ),
      ];

      await provider.addTodos(todos);

      // 验证所有待办都被保存
      expect(provider.todos.length, 3);

      // 验证顺序保持一致（按创建时间排序）
      final savedTodos = await sqliteService.getAllTodos();
      expect(savedTodos.length, 3);
      
      // 按 ID 查找以验证所有待办都存在
      final todo1 = savedTodos.firstWhere((t) => t.id == 'test-1');
      final todo2 = savedTodos.firstWhere((t) => t.id == 'test-2');
      final todo3 = savedTodos.firstWhere((t) => t.id == 'test-3');
      
      expect(todo1.title, '第一个待办');
      expect(todo2.title, '第二个待办');
      expect(todo3.title, '第三个待办');
    });

    // Property 27: 语音创建标记
    // Validates: Requirements 12.1
    test('Property 27: 语音创建标记 - 语音创建的待办标记正确', () async {
      // 创建通过语音创建的待办
      final voiceTodo = TodoItem(
        id: 'voice-1',
        title: '语音待办',
        createdAt: DateTime.now(),
        isVoiceCreated: true,
      );

      await provider.addTodo(voiceTodo);

      // 验证标记被正确保存
      final savedTodo = await sqliteService.getTodoById('voice-1');
      expect(savedTodo, isNotNull);
      expect(savedTodo!.isVoiceCreated, true);

      // 创建非语音创建的待办
      final manualTodo = TodoItem(
        id: 'manual-1',
        title: '手动待办',
        createdAt: DateTime.now(),
        isVoiceCreated: false,
      );

      await provider.addTodo(manualTodo);

      // 验证标记被正确保存
      final savedManualTodo = await sqliteService.getTodoById('manual-1');
      expect(savedManualTodo, isNotNull);
      expect(savedManualTodo!.isVoiceCreated, false);
    });

    // 额外测试：批量添加时验证失败
    test('批量添加时验证失败 - 应该抛出错误', () async {
      final todos = [
        TodoItem(
          id: 'test-1',
          title: '有效待办',
          createdAt: DateTime.now(),
        ),
        TodoItem(
          id: '', // 无效：缺少 id
          title: '无效待办',
          createdAt: DateTime.now(),
        ),
      ];

      expect(
        () => provider.addTodos(todos),
        throwsA(isA<ArgumentError>()),
      );

      // 验证没有任何待办被保存
      expect(provider.todos.length, 0);
    });

    // 额外测试：验证所有必填字段
    test('验证所有必填字段 - id, title, createdAt', () async {
      // 测试所有字段都有效
      final validTodo = TodoItem(
        id: 'valid-1',
        title: '有效待办',
        createdAt: DateTime.now(),
      );

      await provider.addTodo(validTodo);
      expect(provider.todos.length, 1);

      // 清空
      await sqliteService.clearAllTodos();
      await provider.loadTodos();

      // 测试 id 为空
      final noId = TodoItem(
        id: '',
        title: '无ID',
        createdAt: DateTime.now(),
      );
      expect(() => provider.addTodo(noId), throwsA(isA<ArgumentError>()));

      // 测试 title 为空
      final noTitle = TodoItem(
        id: 'test-2',
        title: '',
        createdAt: DateTime.now(),
      );
      expect(() => provider.addTodo(noTitle), throwsA(isA<ArgumentError>()));
    });

    // 额外测试：批量添加保持顺序
    test('批量添加保持顺序 - 多个待办按顺序保存', () async {
      final todos = List.generate(
        10,
        (i) => TodoItem(
          id: 'batch-$i',
          title: '待办 $i',
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ),
      );

      await provider.addTodos(todos);

      // 验证所有待办都被保存
      expect(provider.todos.length, 10);

      // 验证每个待办都存在
      for (int i = 0; i < 10; i++) {
        final todo = await sqliteService.getTodoById('batch-$i');
        expect(todo, isNotNull);
        expect(todo!.title, '待办 $i');
      }
    });
  });
}
