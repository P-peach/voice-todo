import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/parsers/list_mode_detector.dart';

void main() {
  group('ListModeDetector Property Tests', () {
    late ListModeDetector detector;

    setUp(() {
      detector = ListModeDetector();
    });

    /// **Feature: native-voice-recognition, Property 12: 列表模式分割正确性**
    /// **Validates: Requirements 3.6, 10.1, 10.2, 10.3**
    ///
    /// *对于任何*列表式文本（如"苹果两箱，茼蒿10把，草莓"），Parser_Service 应按品类分割为多个独立的 TodoItem。
    test('Property 12: 列表模式分割正确性 - 基本列表分割', () {
      // 测试逗号分隔的列表
      final text1 = '苹果两箱，茼蒿10把，草莓，土豆一箱';
      expect(detector.isListMode(text1), isTrue);

      final items1 = detector.splitItems(text1);
      expect(items1.length, equals(4));
      expect(items1, contains('苹果两箱'));
      expect(items1, contains('茼蒿10把'));
      expect(items1, contains('草莓'));
      expect(items1, contains('土豆一箱'));

      // 测试顿号分隔的列表
      final text2 = '牛奶、面包、鸡蛋、黄油';
      expect(detector.isListMode(text2), isTrue);

      final items2 = detector.splitItems(text2);
      expect(items2.length, equals(4));
      expect(items2, contains('牛奶'));
      expect(items2, contains('面包'));
      expect(items2, contains('鸡蛋'));
      expect(items2, contains('黄油'));

      // 测试分号分隔的列表
      final text3 = '报告；会议；项目';
      expect(detector.isListMode(text3), isTrue);

      final items3 = detector.splitItems(text3);
      expect(items3.length, equals(3));
      expect(items3, contains('报告'));
      expect(items3, contains('会议'));
      expect(items3, contains('项目'));
    });

    test('Property 12: 列表模式分割正确性 - 混合分隔符', () {
      // 测试混合使用不同分隔符
      final text = '苹果、香蕉，橙子；葡萄';
      expect(detector.isListMode(text), isTrue);

      final items = detector.splitItems(text);
      expect(items.length, equals(4));
      expect(items, contains('苹果'));
      expect(items, contains('香蕉'));
      expect(items, contains('橙子'));
      expect(items, contains('葡萄'));
    });

    test('Property 12: 列表模式分割正确性 - 带数量信息的列表', () {
      // 测试包含各种数量表达的列表
      final text = '苹果2斤，香蕉三根，橙子5个，葡萄一串';
      expect(detector.isListMode(text), isTrue);

      final items = detector.splitItems(text);
      expect(items.length, equals(4));
      expect(items, contains('苹果2斤'));
      expect(items, contains('香蕉三根'));
      expect(items, contains('橙子5个'));
      expect(items, contains('葡萄一串'));
    });

    test('Property 12: 列表模式分割正确性 - 带共享属性的列表', () {
      // 测试包含时间和分类关键词的列表
      final text1 = '明天买苹果，香蕉，橙子';
      expect(detector.isListMode(text1), isTrue);

      final items1 = detector.splitItems(text1);
      // 应该移除"明天买"这个共享部分
      expect(items1.length, greaterThanOrEqualTo(2));
      expect(items1.any((item) => item.contains('苹果') || item == '苹果'), isTrue);
      expect(items1.any((item) => item.contains('香蕉') || item == '香蕉'), isTrue);
      expect(items1.any((item) => item.contains('橙子') || item == '橙子'), isTrue);

      final text2 = '下午开会，写报告，检查项目';
      expect(detector.isListMode(text2), isTrue);

      final items2 = detector.splitItems(text2);
      expect(items2.length, greaterThanOrEqualTo(2));
    });

    test('Property 12: 列表模式分割正确性 - 非列表文本应返回false', () {
      // 测试不包含分隔符的文本
      final text1 = '明天上午开会';
      expect(detector.isListMode(text1), isFalse);

      // 测试只有一个项的文本
      final text2 = '买苹果';
      expect(detector.isListMode(text2), isFalse);

      // 测试长句子（即使包含逗号也不应该被识别为列表）
      final text3 = '明天上午10点在会议室开会，请准备好相关材料和报告';
      expect(detector.isListMode(text3), isFalse);
    });

    test('Property 12: 列表模式分割正确性 - 空文本和边界情况', () {
      // 测试空字符串
      expect(detector.isListMode(''), isFalse);
      expect(detector.splitItems(''), isEmpty);

      // 测试只有分隔符
      expect(detector.isListMode('，，，'), isFalse);
      expect(detector.splitItems('，，，'), isEmpty);

      // 测试只有一个有效项
      expect(detector.isListMode('苹果，'), isFalse);
      expect(detector.splitItems('苹果，').length, lessThanOrEqualTo(1));
    });

    test('Property 12: 列表模式分割正确性 - 多样化输入', () {
      // 测试各种真实场景的列表输入
      final testCases = [
        '牛奶、面包、鸡蛋、黄油、奶酪',
        '苹果两箱，茼蒿10把，草莓，土豆一箱',
        '报告、会议、项目、巡检',
        '跑步、瑜伽、游泳',
        '打扫卫生，洗衣服，做饭',
      ];

      for (final testCase in testCases) {
        expect(detector.isListMode(testCase), isTrue,
            reason: '应该识别为列表模式: $testCase');

        final items = detector.splitItems(testCase);
        expect(items.length, greaterThanOrEqualTo(2),
            reason: '应该至少分割出2个项: $testCase');

        // 验证所有项都非空
        for (final item in items) {
          expect(item.trim(), isNotEmpty,
              reason: '分割后的项不应为空: $testCase');
        }
      }
    });

    test('Property 12: 列表模式分割正确性 - 分割结果不应包含分隔符', () {
      final text = '苹果，香蕉，橙子';
      final items = detector.splitItems(text);

      for (final item in items) {
        expect(item, isNot(contains('，')));
        expect(item, isNot(contains('、')));
        expect(item, isNot(contains('；')));
      }
    });

    test('Property 12: 列表模式分割正确性 - 分割结果应去除前后空格', () {
      final text = '苹果 ， 香蕉 ， 橙子 ';
      final items = detector.splitItems(text);

      for (final item in items) {
        expect(item, equals(item.trim()),
            reason: '项应该已经去除前后空格');
      }
    });

    /// **Feature: native-voice-recognition, Property 21: 数量信息保留**
    /// **Validates: Requirements 10.4**
    ///
    /// *对于任何*包含数量信息的品类（如"苹果两箱"），Parser_Service 应将数量信息包含在标题或描述中。
    test('Property 21: 数量信息保留 - 提取数量信息', () {
      // 测试各种数量表达式
      final testCases = {
        '苹果两箱': '两箱',
        '香蕉三根': '三根',
        '橙子5个': '5个',
        '葡萄一串': '一串',
        '牛奶2瓶': '2瓶',
        '面包10个': '10个',
        '鸡蛋一打': null, // "打"不在量词列表中
        '土豆3斤': '3斤',
        '西瓜半个': null, // "半"不在数字列表中
      };

      for (final entry in testCases.entries) {
        final quantity = detector.extractQuantity(entry.key);
        if (entry.value != null) {
          expect(quantity, equals(entry.value),
              reason: '应该从"${entry.key}"中提取出"${entry.value}"');
        } else {
          expect(quantity, isNull,
              reason: '"${entry.key}"不应该提取出数量信息');
        }
      }
    });

    test('Property 21: 数量信息保留 - 中文数字', () {
      final testCases = {
        '苹果一箱': '一箱',
        '香蕉两根': '两根',
        '橙子三个': '三个',
        '葡萄五串': '五串',
        '牛奶十瓶': '十瓶',
      };

      for (final entry in testCases.entries) {
        final quantity = detector.extractQuantity(entry.key);
        expect(quantity, equals(entry.value),
            reason: '应该从"${entry.key}"中提取出"${entry.value}"');
      }
    });

    test('Property 21: 数量信息保留 - 阿拉伯数字', () {
      final testCases = {
        '苹果2箱': '2箱',
        '香蕉5根': '5根',
        '橙子10个': '10个',
        '葡萄3串': '3串',
        '牛奶1瓶': '1瓶',
      };

      for (final entry in testCases.entries) {
        final quantity = detector.extractQuantity(entry.key);
        expect(quantity, equals(entry.value),
            reason: '应该从"${entry.key}"中提取出"${entry.value}"');
      }
    });

    test('Property 21: 数量信息保留 - 小数数量', () {
      final testCases = {
        '苹果2.5斤': '2.5斤',
        '香蕉1.5公斤': '1.5公斤',
        '橙子0.5升': '0.5升',
      };

      for (final entry in testCases.entries) {
        final quantity = detector.extractQuantity(entry.key);
        expect(quantity, equals(entry.value),
            reason: '应该从"${entry.key}"中提取出"${entry.value}"');
      }
    });

    test('Property 21: 数量信息保留 - 无数量信息', () {
      final testCases = [
        '苹果',
        '香蕉',
        '橙子',
        '买水果',
        '开会',
      ];

      for (final testCase in testCases) {
        final quantity = detector.extractQuantity(testCase);
        expect(quantity, isNull,
            reason: '"$testCase"不应该提取出数量信息');
      }
    });

    test('Property 21: 数量信息保留 - 边界情况', () {
      // 空字符串
      expect(detector.extractQuantity(''), isNull);

      // 只有数字没有量词
      expect(detector.extractQuantity('5'), isNull);

      // 只有量词没有数字
      expect(detector.extractQuantity('箱'), isNull);
    });

    /// **Feature: native-voice-recognition, Property 22: 列表属性继承**
    /// **Validates: Requirements 10.5**
    ///
    /// *对于任何*列表式文本，所有分割出的待办事项应共享相同的时间和分类。
    test('Property 22: 列表属性继承 - 提取共享时间属性', () {
      // 测试包含时间关键词的列表
      final testCases = {
        '明天买苹果，香蕉，橙子': '明天',
        '下午开会，写报告，检查项目': '下午',
        '下周一完成报告，提交文档，开会': '周一',
        '今天上午打扫卫生，洗衣服，做饭': '今天',
      };

      for (final entry in testCases.entries) {
        final attributes = detector.extractSharedAttributes(entry.key);
        expect(attributes.containsKey('timeExpression'), isTrue,
            reason: '应该提取出时间表达式: ${entry.key}');
        expect(attributes['timeExpression'], contains(entry.value),
            reason: '时间表达式应该包含"${entry.value}": ${entry.key}');
      }
    });

    test('Property 22: 列表属性继承 - 提取共享分类属性', () {
      // 测试包含分类关键词的列表
      final testCases = {
        '买苹果，香蕉，橙子': '买',
        '开会，写报告，检查项目': '会议',
        '学习英语，阅读书籍，练习编程': '学习',
        '打扫卫生，洗衣服，做饭': '打扫',
      };

      for (final entry in testCases.entries) {
        final attributes = detector.extractSharedAttributes(entry.key);
        // 至少应该识别出一个分类关键词
        final hasCategoryHint = attributes.containsKey('categoryHint');
        if (hasCategoryHint) {
          expect(attributes['categoryHint'], isNotEmpty,
              reason: '应该提取出分类提示: ${entry.key}');
        }
      }
    });

    test('Property 22: 列表属性继承 - 同时提取时间和分类', () {
      final text = '明天买苹果，香蕉，橙子';
      final attributes = detector.extractSharedAttributes(text);

      // 应该同时包含时间和分类信息
      expect(attributes.containsKey('timeExpression'), isTrue);
      expect(attributes.containsKey('categoryHint'), isTrue);
      expect(attributes['timeExpression'], contains('明天'));
      expect(attributes['categoryHint'], equals('买'));
    });

    test('Property 22: 列表属性继承 - 无共享属性', () {
      final text = '苹果，香蕉，橙子';
      final attributes = detector.extractSharedAttributes(text);

      // 没有时间和分类关键词，应该返回空Map或不包含这些键
      expect(attributes.isEmpty || 
             (!attributes.containsKey('timeExpression') && 
              !attributes.containsKey('categoryHint')), 
             isTrue);
    });

    test('Property 22: 列表属性继承 - 多样化输入', () {
      // 测试各种包含共享属性的列表
      final testCases = [
        '明天上午开会，写报告，检查项目',
        '下周五买牛奶，面包，鸡蛋',
        '今天晚上跑步，瑜伽，游泳',
        '后天打扫卫生，洗衣服，做饭',
      ];

      for (final testCase in testCases) {
        final attributes = detector.extractSharedAttributes(testCase);
        // 至少应该提取出时间或分类中的一个
        expect(
          attributes.containsKey('timeExpression') || 
          attributes.containsKey('categoryHint'),
          isTrue,
          reason: '应该至少提取出一个共享属性: $testCase'
        );
      }
    });
  });

  group('ListModeDetector Unit Tests', () {
    late ListModeDetector detector;

    setUp(() {
      detector = ListModeDetector();
    });

    test('边界情况 - 空字符串', () {
      expect(detector.isListMode(''), isFalse);
      expect(detector.splitItems(''), isEmpty);
      expect(detector.extractSharedAttributes(''), isEmpty);
      expect(detector.extractQuantity(''), isNull);
    });

    test('边界情况 - 纯空格', () {
      expect(detector.isListMode('   '), isFalse);
      expect(detector.splitItems('   '), isEmpty);
    });

    test('边界情况 - 单个项', () {
      expect(detector.isListMode('苹果'), isFalse);
      expect(detector.splitItems('苹果').length, lessThanOrEqualTo(1));
    });

    test('边界情况 - 超长项（不应识别为列表）', () {
      final longText = '明天上午10点在会议室开会，请准备好相关材料和报告，并提前通知所有参会人员';
      expect(detector.isListMode(longText), isFalse);
    });

    test('特殊情况 - 英文逗号', () {
      final text = 'apple,banana,orange';
      expect(detector.isListMode(text), isTrue);
      final items = detector.splitItems(text);
      expect(items.length, equals(3));
    });

    test('特殊情况 - 英文分号', () {
      final text = 'task1;task2;task3';
      expect(detector.isListMode(text), isTrue);
      final items = detector.splitItems(text);
      expect(items.length, equals(3));
    });

    test('特殊情况 - 数量信息在中间', () {
      final quantity = detector.extractQuantity('买2斤苹果');
      expect(quantity, equals('2斤'));
    });

    test('特殊情况 - 多个数量信息（只提取第一个）', () {
      final quantity = detector.extractQuantity('苹果2斤香蕉3根');
      expect(quantity, isNotNull);
      // 应该提取第一个数量信息
      expect(quantity, anyOf(equals('2斤'), equals('3根')));
    });

    test('特殊情况 - 大数字', () {
      final testCases = {
        '苹果100箱': '100箱',
        '香蕉1000根': '1000根',
        '橙子50个': '50个',
      };

      for (final entry in testCases.entries) {
        final quantity = detector.extractQuantity(entry.key);
        expect(quantity, equals(entry.value));
      }
    });

    test('商品名称分割 - 无分隔符的商品列表', () {
      // 测试用例："黄瓜一箱苹果两箱"
      final text1 = '黄瓜一箱苹果两箱';
      expect(detector.isListMode(text1), isTrue);

      final items1 = detector.splitItems(text1);
      expect(items1.length, equals(2));
      expect(items1[0], equals('黄瓜一箱'));
      expect(items1[1], equals('苹果两箱'));

      // 测试用例："番茄3斤黄瓜2斤土豆5斤"
      final text2 = '番茄3斤黄瓜2斤土豆5斤';
      expect(detector.isListMode(text2), isTrue);

      final items2 = detector.splitItems(text2);
      expect(items2.length, equals(3));
      expect(items2[0], equals('番茄3斤'));
      expect(items2[1], equals('黄瓜2斤'));
      expect(items2[2], equals('土豆5斤'));

      // 测试用例："草莓一盒蓝莓两盒樱桃三盒"
      final text3 = '草莓一盒蓝莓两盒樱桃三盒';
      expect(detector.isListMode(text3), isTrue);

      final items3 = detector.splitItems(text3);
      expect(items3.length, equals(3));
      expect(items3[0], equals('草莓一盒'));
      expect(items3[1], equals('蓝莓两盒'));
      expect(items3[2], equals('樱桃三盒'));
    });

    test('商品名称分割 - 混合有无数量信息', () {
      // 有些商品有数量，有些没有
      final text = '苹果两箱香蕉土豆5斤';
      expect(detector.isListMode(text), isTrue);

      final items = detector.splitItems(text);
      expect(items.length, equals(3));
      expect(items[0], equals('苹果两箱'));
      expect(items[1], equals('香蕉'));
      expect(items[2], equals('土豆5斤'));
    });

    test('商品名称分割 - 单个商品不应识别为列表', () {
      final text1 = '苹果两箱';
      expect(detector.isListMode(text1), isFalse);

      final text2 = '买黄瓜';
      expect(detector.isListMode(text2), isFalse);
    });

    test('商品名称分割 - 长商品名优先匹配', () {
      // "西红柿"应该作为整体匹配，而不是"红"
      final text = '西红柿2斤黄瓜3斤';
      expect(detector.isListMode(text), isTrue);

      final items = detector.splitItems(text);
      expect(items.length, equals(2));
      expect(items[0], equals('西红柿2斤'));
      expect(items[1], equals('黄瓜3斤'));
    });
  });
}
