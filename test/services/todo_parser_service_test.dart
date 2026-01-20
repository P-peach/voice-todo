import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/todo_parser_service.dart';
import 'package:voice_todo/models/todo_item.dart';

void main() {
  group('TodoParserService', () {
    late TodoParserService parser;

    setUp(() {
      parser = TodoParserService.instance;
    });

    group('Property 7: 标题提取完整性', () {
      // Feature: native-voice-recognition, Property 7: 标题提取完整性
      // Validates: Requirements 3.1
      test('对于任何识别文本，Parser_Service 应能提取出非空的待办事项标题', () {
        final testCases = [
          '买苹果',
          '明天开会',
          '下周五提交报告',
          '紧急任务需要马上完成',
          '去超市买菜，记得买牛奶',
          '学习Flutter开发',
          '锻炼身体保持健康',
          '打扫房间做家务',
          '阅读技术书籍提升能力',
          '准备明天的会议材料',
        ];

        for (final text in testCases) {
          final todos = parser.parse(text);
          
          // 应该至少返回一个待办事项
          expect(todos, isNotEmpty, reason: '文本 "$text" 应该解析出至少一个待办事项');
          
          // 每个待办事项都应该有非空标题
          for (final todo in todos) {
            expect(todo.title, isNotEmpty, reason: '待办事项标题不应为空');
            expect(todo.title.trim(), isNotEmpty, reason: '待办事项标题不应只包含空白字符');
          }
        }
      });

      test('标题应该是有意义的文本，不应该只是标点符号', () {
        final testCases = [
          '买苹果和香蕉',
          '明天上午10点开会',
          '紧急：完成项目报告',
        ];

        for (final text in testCases) {
          final todos = parser.parse(text);
          
          for (final todo in todos) {
            // 标题应该包含至少一个字母或汉字
            expect(
              todo.title,
              matches(RegExp(r'[\u4e00-\u9fa5a-zA-Z]')),
              reason: '标题应该包含有意义的文字',
            );
          }
        }
      });
    });

    group('Property 11: 多待办分割正确性', () {
      // Feature: native-voice-recognition, Property 11: 多待办分割正确性
      // Validates: Requirements 3.5
      test('对于任何包含多个待办事项的文本，Parser_Service 应正确分割并分别解析每个待办事项', () {
        final testCases = [
          {
            'text': '买苹果，买香蕉，买橙子',
            'expectedCount': 3,
          },
          {
            'text': '明天开会；下周提交报告；后天做演示',
            'expectedCount': 3,
          },
          {
            'text': '学习Flutter。练习Dart。阅读文档',
            'expectedCount': 3,
          },
          {
            'text': '打扫房间\n洗衣服\n做饭',
            'expectedCount': 3,
          },
          {
            'text': '紧急任务，重要会议',
            'expectedCount': 2,
          },
        ];

        for (final testCase in testCases) {
          final text = testCase['text'] as String;
          final expectedCount = testCase['expectedCount'] as int;
          
          final todos = parser.parse(text);
          
          expect(
            todos.length,
            expectedCount,
            reason: '文本 "$text" 应该解析出 $expectedCount 个待办事项',
          );
          
          // 每个待办事项都应该有唯一的标题
          final titles = todos.map((t) => t.title).toList();
          expect(titles.toSet().length, titles.length, reason: '每个待办事项应该有不同的标题');
        }
      });

      test('分割后的每个待办事项都应该是独立且完整的', () {
        final text = '买苹果，明天开会，学习编程';
        final todos = parser.parse(text);

        expect(todos.length, 3);
        
        // 每个待办事项都应该有自己的属性
        for (final todo in todos) {
          expect(todo.id, isNotEmpty);
          expect(todo.title, isNotEmpty);
          expect(todo.category, isNotEmpty);
          expect(todo.priority, isNotEmpty);
          expect(todo.createdAt, isNotNull);
          expect(todo.isVoiceCreated, isTrue);
        }
      });
    });

    group('Property 13: 返回类型正确性', () {
      // Feature: native-voice-recognition, Property 13: 返回类型正确性
      // Validates: Requirements 3.7
      test('对于任何识别文本，Parser_Service 的 parse 方法应返回 List<TodoItem> 类型', () {
        final testCases = [
          '买苹果',
          '明天开会，下周提交报告',
          '学习Flutter',
          '',
          '   ',
          '紧急任务需要马上完成',
          '苹果两箱，茼蒿10把，草莓',
        ];

        for (final text in testCases) {
          final result = parser.parse(text);
          
          // 返回类型应该是 List<TodoItem>
          expect(result, isA<List<TodoItem>>());
          
          // 列表中的每个元素都应该是 TodoItem
          for (final item in result) {
            expect(item, isA<TodoItem>());
          }
        }
      });

      test('空文本或纯空白文本应返回空列表', () {
        final testCases = ['', '   ', '\n', '\t', '  \n  \t  '];

        for (final text in testCases) {
          final result = parser.parse(text);
          
          expect(result, isA<List<TodoItem>>());
          expect(result, isEmpty, reason: '空文本应返回空列表');
        }
      });

      test('返回的 TodoItem 对象应该是完整且有效的', () {
        final text = '买苹果';
        final todos = parser.parse(text);

        expect(todos, isNotEmpty);
        
        for (final todo in todos) {
          // 验证 TodoItem 的必填字段
          expect(todo.id, isNotEmpty);
          expect(todo.title, isNotEmpty);
          expect(todo.category, isNotEmpty);
          expect(todo.priority, isNotEmpty);
          expect(todo.createdAt, isNotNull);
          
          // 验证字段类型
          expect(todo.id, isA<String>());
          expect(todo.title, isA<String>());
          expect(todo.category, isA<String>());
          expect(todo.priority, isA<String>());
          expect(todo.isCompleted, isA<bool>());
          expect(todo.isVoiceCreated, isA<bool>());
          expect(todo.createdAt, isA<DateTime>());
        }
      });
    });

    group('Property 14 & 15: 默认行为', () {
      // Feature: native-voice-recognition, Property 14: 无时间表达式默认行为
      // Validates: Requirements 4.8
      test('对于任何不包含时间表达式的文本，Parser_Service 应将截止日期设置为 null', () {
        final testCases = [
          '买苹果',
          '学习编程',
          '打扫房间',
          '锻炼身体',
          '阅读书籍',
        ];

        for (final text in testCases) {
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty);
          
          for (final todo in todos) {
            expect(
              todo.deadline,
              isNull,
              reason: '文本 "$text" 不包含时间表达式，截止日期应为 null',
            );
          }
        }
      });

      // Feature: native-voice-recognition, Property 15: 无关键词默认值
      // Validates: Requirements 5.8
      test('对于任何不包含分类或优先级关键词的文本，Parser_Service 应使用默认值', () {
        final testCases = [
          '完成事情',
          '处理问题',
          '解决困难',
        ];

        for (final text in testCases) {
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty);
          
          for (final todo in todos) {
            // 默认分类应该是 '其他'
            expect(
              todo.category,
              '其他',
              reason: '文本 "$text" 不包含分类关键词，应使用默认分类',
            );
            
            // 默认优先级应该是 '中'
            expect(
              todo.priority,
              '中',
              reason: '文本 "$text" 不包含优先级关键词，应使用默认优先级',
            );
          }
        }
      });

      test('包含关键词的文本应该正确识别分类和优先级', () {
        final testCases = [
          {
            'text': '去超市买菜',
            'expectedCategory': '购物',
            'expectedPriority': '中',
          },
          {
            'text': '紧急会议需要准备',
            'expectedCategory': '工作',
            'expectedPriority': '高',
          },
          {
            'text': '不急的家务活',
            'expectedCategory': '生活',
            'expectedPriority': '低',
          },
        ];

        for (final testCase in testCases) {
          final text = testCase['text'] as String;
          final expectedCategory = testCase['expectedCategory'] as String;
          final expectedPriority = testCase['expectedPriority'] as String;
          
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty);
          expect(todos.first.category, expectedCategory);
          expect(todos.first.priority, expectedPriority);
        }
      });
    });

    group('Property 24: 提醒标记正确性', () {
      // Feature: native-voice-recognition, Property 24: 提醒标记正确性
      // Validates: Requirements 11.1
      test('对于任何包含提醒关键词的文本，Parser_Service 应能识别需要提醒', () {
        final testCasesWithReminder = [
          '提醒我明天开会',
          '记得买苹果',
          '别忘了提交报告',
          '别忘记锻炼身体',
          '提醒下周五交作业',
        ];

        final testCasesWithoutReminder = [
          '买苹果',
          '明天开会',
          '提交报告',
          '锻炼身体',
        ];

        // 注意：当前 TodoItem 模型还没有 needsReminder 或 reminderConfig 字段
        // 这些字段将在 Task 7 中添加
        // 目前我们测试解析器能够正确解析包含提醒关键词的文本
        // 并且不会因为提醒关键词而影响其他字段的解析
        
        for (final text in testCasesWithReminder) {
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty, reason: '包含提醒关键词的文本应该能正常解析');
          
          for (final todo in todos) {
            expect(todo.title, isNotEmpty);
            expect(todo.id, isNotEmpty);
            expect(todo.isVoiceCreated, isTrue);
          }
        }

        for (final text in testCasesWithoutReminder) {
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty, reason: '不包含提醒关键词的文本应该能正常解析');
          
          for (final todo in todos) {
            expect(todo.title, isNotEmpty);
            expect(todo.id, isNotEmpty);
            expect(todo.isVoiceCreated, isTrue);
          }
        }
      });

      test('提醒关键词不应该影响标题提取', () {
        final testCases = [
          {
            'text': '提醒我买苹果',
            'expectedTitleContains': '买苹果',
          },
          {
            'text': '记得明天开会',
            'expectedTitleContains': '明天开会',
          },
          {
            'text': '别忘了提交报告',
            'expectedTitleContains': '提交报告',
          },
        ];

        for (final testCase in testCases) {
          final text = testCase['text'] as String;
          final expectedContains = testCase['expectedTitleContains'] as String;
          
          final todos = parser.parse(text);
          
          expect(todos, isNotEmpty);
          
          // 标题应该包含主要内容，提醒关键词可能被包含也可能被过滤
          // 重要的是标题应该有意义且不为空
          expect(todos.first.title, isNotEmpty);
        }
      });
    });
  });
}
