import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_todo/components/vocabulary/add_vocabulary_entry_dialog.dart';
import 'package:voice_todo/services/custom_vocabulary_service.dart';

void main() {
  group('AddVocabularyEntryDialog', () {
    setUp(() async {
      // 初始化 SharedPreferences 的测试环境
      SharedPreferences.setMockInitialValues({});
      final service = CustomVocabularyService.instance;
      await service.reinitialize();
    });

    testWidgets('displays dialog with title and description',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证标题
      expect(find.text('添加词汇条目'), findsOneWidget);
      expect(find.text('添加常见的语音识别错误及其正确映射'), findsOneWidget);
    });

    testWidgets('displays two text fields with labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证文本字段
      expect(find.text('错误识别的词汇'), findsOneWidget);
      expect(find.text('正确的词汇'), findsOneWidget);
    });

    testWidgets('displays cancel and save buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证按钮
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('shows error when incorrect field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 只填写正确词汇字段
      await tester.enterText(
        find.widgetWithText(TextField, '正确的词汇'),
        '大白菜',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误提示
      expect(find.text('请输入错误识别的词汇'), findsOneWidget);
    });

    testWidgets('shows error when correct field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 只填写错误词汇字段
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '白菜',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误提示
      expect(find.text('请输入正确的词汇'), findsOneWidget);
    });

    testWidgets('shows error when both fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 点击保存按钮（不填写任何字段）
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误提示
      expect(find.text('请输入错误识别的词汇'), findsOneWidget);
      expect(find.text('请输入正确的词汇'), findsOneWidget);
    });

    testWidgets('clears error when user starts typing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 点击保存按钮触发验证错误
      await tester.tap(find.text('保存'));
      await tester.pump();

      // 验证错误提示存在
      expect(find.text('请输入错误识别的词汇'), findsOneWidget);

      // 开始输入
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '白',
      );
      await tester.pump();

      // 验证错误提示已清除
      expect(find.text('请输入错误识别的词汇'), findsNothing);
    });

    testWidgets('saves entry and closes dialog when valid',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddVocabularyEntryDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 打开对话框
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 填写字段
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '白菜',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '正确的词汇'),
        '大白菜',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭且返回 true
      expect(dialogResult, true);

      // 验证词汇已保存
      final service = CustomVocabularyService.instance;
      final entries = service.getAllEntries();
      expect(entries['白菜'], '大白菜');
    });

    testWidgets('closes dialog without saving when cancel is pressed',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddVocabularyEntryDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 打开对话框
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 填写字段
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '白菜',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '正确的词汇'),
        '大白菜',
      );

      // 点击取消按钮
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭且返回 false
      expect(dialogResult, false);

      // 验证词汇未保存
      final service = CustomVocabularyService.instance;
      final entries = service.getAllEntries();
      expect(entries.containsKey('白菜'), false);
    });

    testWidgets('disables text fields while saving',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 填写字段
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '白菜',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '正确的词汇'),
        '大白菜',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pump(); // 触发状态更新但不等待完成

      // 验证文本字段被禁用
      final incorrectField = tester.widget<TextField>(
        find.widgetWithText(TextField, '错误识别的词汇'),
      );
      expect(incorrectField.enabled, false);

      final correctField = tester.widget<TextField>(
        find.widgetWithText(TextField, '正确的词汇'),
      );
      expect(correctField.enabled, false);
    });

    testWidgets('trims whitespace from input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddVocabularyEntryDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 打开对话框
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 填写字段（带有前后空格）
      await tester.enterText(
        find.widgetWithText(TextField, '错误识别的词汇'),
        '  白菜  ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '正确的词汇'),
        '  大白菜  ',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证词汇已保存且空格已去除
      final service = CustomVocabularyService.instance;
      final entries = service.getAllEntries();
      expect(entries['白菜'], '大白菜');
      expect(entries.containsKey('  白菜  '), false);
    });

    testWidgets('uses Material 3 styling with rounded corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证 Dialog 使用圆角
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16.0));
    });

    testWidgets('uses FilledButton for save and TextButton for cancel',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证按钮类型
      expect(find.widgetWithText(FilledButton, '保存'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '取消'), findsOneWidget);
    });

    testWidgets('displays appropriate icons for text fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddVocabularyEntryDialog(),
          ),
        ),
      );

      // 验证图标
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
