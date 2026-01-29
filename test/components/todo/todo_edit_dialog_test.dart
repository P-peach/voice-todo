import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:voice_todo/components/todo/todo_edit_dialog.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/providers/todo_provider.dart';

import '../../mocks.mocks.dart';

void main() {
  late MockTodoProvider mockTodoProvider;

  setUp(() {
    mockTodoProvider = MockTodoProvider();
  });

  Widget createTestWidget(TodoItem todo) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<TodoProvider>.value(
          value: mockTodoProvider,
          child: TodoEditDialog(todo: todo),
        ),
      ),
    );
  }

  group('TodoEditDialog Widget Tests', () {
    testWidgets('displays all form fields with initial values', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '测试描述',
        category: '工作',
        priority: '高',
        deadline: DateTime(2026, 2, 1, 10, 0),
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 验证对话框标题
      expect(find.text('编辑待办事项'), findsOneWidget);

      // 验证标题输入框
      expect(find.widgetWithText(TextField, '测试待办'), findsOneWidget);

      // 验证描述输入框
      expect(find.widgetWithText(TextField, '测试描述'), findsOneWidget);

      // 验证分类下拉框
      expect(find.text('工作'), findsOneWidget);

      // 验证优先级下拉框
      expect(find.text('高'), findsAtLeastNWidgets(1));

      // 验证按钮
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('shows error when title is empty', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 清空标题
      final titleField = find.widgetWithText(TextField, '测试待办');
      await tester.enterText(titleField, '');
      await tester.pump();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误提示
      expect(find.text('标题不能为空'), findsOneWidget);

      // 验证没有调用 updateTodoWithValidation
      verifyNever(mockTodoProvider.updateTodoWithValidation(any));
    });

    testWidgets('can edit title and description', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '原标题',
        description: '原描述',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 修改标题
      final titleField = find.widgetWithText(TextField, '原标题');
      await tester.enterText(titleField, '新标题');
      await tester.pump();

      // 修改描述
      final descField = find.widgetWithText(TextField, '原描述');
      await tester.enterText(descField, '新描述');
      await tester.pump();

      // 验证文本已更改
      expect(find.text('新标题'), findsOneWidget);
      expect(find.text('新描述'), findsOneWidget);
    });

    testWidgets('can change category', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 点击分类下拉框
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // 选择新分类
      await tester.tap(find.text('购物').last);
      await tester.pumpAndSettle();

      // 验证分类已更改
      expect(find.text('购物'), findsOneWidget);
    });

    testWidgets('can change priority', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 点击优先级下拉框
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // 选择新优先级
      await tester.tap(find.text('低').last);
      await tester.pumpAndSettle();

      // 验证优先级已更改
      expect(find.text('低'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel button closes dialog without saving', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 修改标题
      final titleField = find.widgetWithText(TextField, '测试待办');
      await tester.enterText(titleField, '新标题');
      await tester.pump();

      // 点击取消按钮
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证没有调用 updateTodoWithValidation
      verifyNever(mockTodoProvider.updateTodoWithValidation(any));
    });

    testWidgets('save button calls updateTodoWithValidation', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '测试描述',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      when(mockTodoProvider.updateTodoWithValidation(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget(todo));

      // 修改标题
      final titleField = find.widgetWithText(TextField, '测试待办');
      await tester.enterText(titleField, '新标题');
      await tester.pump();

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证调用了 updateTodoWithValidation
      verify(mockTodoProvider.updateTodoWithValidation(any)).called(1);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 点击删除按钮
      await tester.tap(find.text('删除').first);
      await tester.pumpAndSettle();

      // 验证确认对话框出现
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('确定要删除这个待办事项吗？此操作无法撤销。'), findsOneWidget);
    });

    testWidgets('can clear deadline', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: '测试待办',
        description: '',
        category: '工作',
        priority: '中',
        deadline: DateTime(2026, 2, 1, 10, 0),
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 查找清除按钮（suffixIcon）
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      // 点击清除按钮
      await tester.tap(clearButton);
      await tester.pump();

      // 验证截止日期已清除
      expect(find.text('选择截止日期（可选）'), findsOneWidget);
    });
  });

  group('TodoEditDialog Validation Tests', () {
    testWidgets('validates empty title', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: 'Test',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 清空标题
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      // 点击保存
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误消息
      expect(find.text('标题不能为空'), findsOneWidget);
    });

    testWidgets('clears title error when user types', (tester) async {
      final todo = TodoItem(
        id: '1',
        title: 'Test',
        description: '',
        category: '工作',
        priority: '中',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(todo));

      // 清空标题并触发错误
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('标题不能为空'), findsOneWidget);

      // 输入新文本
      await tester.enterText(find.byType(TextField).first, '新标题');
      await tester.pump();

      // 验证错误消息消失
      expect(find.text('标题不能为空'), findsNothing);
    });
  });
}
