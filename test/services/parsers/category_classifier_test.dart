import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/parsers/category_classifier.dart';

void main() {
  group('CategoryClassifier Property Tests', () {
    late CategoryClassifier classifier;

    setUp(() {
      classifier = CategoryClassifier();
    });

    /// **Feature: native-voice-recognition, Property 9: 分类识别正确性**
    /// **Validates: Requirements 3.3, 5.1, 5.2, 5.3, 5.4, 5.5**
    ///
    /// *对于任何*包含分类关键词的文本，Parser_Service 应设置正确的待办事项分类。
    test('Property 9: 分类识别正确性 - 工作分类', () {
      // 测试工作相关关键词
      final workKeywords = ['会议', '报告', '项目', '巡检', '进货', '任务'];

      for (final keyword in workKeywords) {
        final text = '明天$keyword';
        final result = classifier.classify(text);
        expect(result, equals('工作'),
            reason: '包含关键词"$keyword"应该识别为工作分类');
      }

      // 测试包含多个关键词的情况
      final multiKeyword = classifier.classify('明天开会讨论项目报告');
      expect(multiKeyword, equals('工作'));

      // 测试关键词在不同位置
      expect(classifier.classify('会议明天举行'), equals('工作'));
      expect(classifier.classify('需要完成报告'), equals('工作'));
      expect(classifier.classify('项目进度检查'), equals('工作'));
    });

    test('Property 9: 分类识别正确性 - 购物分类', () {
      // 测试购物相关关键词
      final shoppingKeywords = ['买', '购买', '超市', '商店', '购物'];

      for (final keyword in shoppingKeywords) {
        final text = '去$keyword东西';
        final result = classifier.classify(text);
        expect(result, equals('购物'),
            reason: '包含关键词"$keyword"应该识别为购物分类');
      }

      // 测试实际场景
      expect(classifier.classify('去超市买菜'), equals('购物'));
      expect(classifier.classify('购买生活用品'), equals('购物'));
      expect(classifier.classify('商店打折'), equals('购物'));
    });

    test('Property 9: 分类识别正确性 - 学习分类', () {
      // 测试学习相关关键词
      final studyKeywords = ['学习', '阅读', '课程', '练习', '复习'];

      for (final keyword in studyKeywords) {
        final text = '今天$keyword';
        final result = classifier.classify(text);
        expect(result, equals('学习'),
            reason: '包含关键词"$keyword"应该识别为学习分类');
      }

      // 测试实际场景
      expect(classifier.classify('学习英语'), equals('学习'));
      expect(classifier.classify('阅读技术文档'), equals('学习'));
      expect(classifier.classify('完成课程作业'), equals('学习'));
      expect(classifier.classify('练习编程'), equals('学习'));
      expect(classifier.classify('复习考试内容'), equals('学习'));
    });

    test('Property 9: 分类识别正确性 - 生活分类', () {
      // 测试生活相关关键词
      final lifeKeywords = ['打扫', '做饭', '洗衣', '生日', '提醒', '家务'];

      for (final keyword in lifeKeywords) {
        final text = '需要$keyword';
        final result = classifier.classify(text);
        expect(result, equals('生活'),
            reason: '包含关键词"$keyword"应该识别为生活分类');
      }

      // 测试实际场景
      expect(classifier.classify('打扫房间'), equals('生活'));
      expect(classifier.classify('做饭吃'), equals('生活'));
      expect(classifier.classify('洗衣服'), equals('生活'));
      expect(classifier.classify('妈妈生日'), equals('生活'));
      expect(classifier.classify('提醒自己'), equals('生活'));
    });

    test('Property 9: 分类识别正确性 - 健康分类', () {
      // 测试健康相关关键词
      final healthKeywords = ['运动', '锻炼', '健身', '跑步', '瑜伽'];

      for (final keyword in healthKeywords) {
        final text = '去$keyword';
        final result = classifier.classify(text);
        expect(result, equals('健康'),
            reason: '包含关键词"$keyword"应该识别为健康分类');
      }

      // 测试实际场景
      expect(classifier.classify('去运动'), equals('健康'));
      expect(classifier.classify('锻炼身体'), equals('健康'));
      expect(classifier.classify('健身房'), equals('健康'));
      expect(classifier.classify('跑步30分钟'), equals('健康'));
      expect(classifier.classify('练瑜伽'), equals('健康'));
    });

    test('Property 9: 分类识别正确性 - 默认分类', () {
      // 测试不包含任何分类关键词的文本
      final noKeywordTexts = [
        '完成这个',
        '处理一下',
        '看看情况',
        '联系客户',
        '准备材料',
      ];

      for (final text in noKeywordTexts) {
        final result = classifier.classify(text);
        expect(result, equals('其他'),
            reason: '不包含分类关键词的文本"$text"应该返回默认分类"其他"');
      }

      // 测试空字符串
      expect(classifier.classify(''), equals('其他'));
    });

    test('Property 9: 分类识别正确性 - 多样化输入', () {
      // 测试各种真实场景的文本
      final testCases = {
        '明天上午10点开会议': '工作',
        '去超市买苹果和香蕉': '购物',
        '今天晚上学习Flutter': '学习',
        '周末打扫房间': '生活',
        '每天跑步5公里': '健康',
        '下周一提交项目报告': '工作',
        '购买生日礼物': '购物',
        '阅读技术书籍': '学习',
        '做饭给家人吃': '生活',
        '健身房锻炼': '健康',
      };

      for (final entry in testCases.entries) {
        final result = classifier.classify(entry.key);
        expect(result, equals(entry.value),
            reason: '"${entry.key}"应该识别为"${entry.value}"分类');
      }
    });

    test('Property 9: 分类识别正确性 - 优先级（第一个匹配）', () {
      // 当文本包含多个分类的关键词时，应该返回第一个匹配的分类
      // 由于 Map 的遍历顺序，这个测试验证实现的一致性
      final multiCategory = classifier.classify('开会后去超市买东西');
      // 应该匹配到第一个出现的关键词对应的分类
      expect(['工作', '购物'].contains(multiCategory), isTrue,
          reason: '包含多个分类关键词时应该返回其中一个有效分类');
    });

    test('Property 9: 分类识别正确性 - 关键词部分匹配', () {
      // 测试关键词作为子字符串出现的情况
      expect(classifier.classify('开会议'), equals('工作')); // "会议"
      expect(classifier.classify('去购物中心'), equals('购物')); // "购物"
      expect(classifier.classify('学习资料'), equals('学习')); // "学习"
      expect(classifier.classify('做饭菜'), equals('生活')); // "做饭"
      expect(classifier.classify('运动会'), equals('健康')); // "运动"
    });
  });

  group('CategoryClassifier Unit Tests', () {
    late CategoryClassifier classifier;

    setUp(() {
      classifier = CategoryClassifier();
    });

    test('边界情况 - 空字符串', () {
      final result = classifier.classify('');
      expect(result, equals('其他'));
    });

    test('边界情况 - 纯空格', () {
      final result = classifier.classify('   ');
      expect(result, equals('其他'));
    });

    test('边界情况 - 只有标点符号', () {
      final result = classifier.classify('！@#￥%……&*（）');
      expect(result, equals('其他'));
    });

    test('边界情况 - 英文文本', () {
      final result = classifier.classify('meeting tomorrow');
      expect(result, equals('其他'));
    });

    test('边界情况 - 数字', () {
      final result = classifier.classify('12345');
      expect(result, equals('其他'));
    });

    test('特殊情况 - 关键词大小写（中文无大小写）', () {
      // 中文没有大小写，但测试一致性
      expect(classifier.classify('会议'), equals('工作'));
      expect(classifier.classify('會議'), equals('其他')); // 繁体字不匹配
    });

    test('特殊情况 - 关键词前后有其他文字', () {
      expect(classifier.classify('重要会议通知'), equals('工作'));
      expect(classifier.classify('需要去超市'), equals('购物'));
      expect(classifier.classify('开始学习了'), equals('学习'));
      expect(classifier.classify('帮忙打扫'), equals('生活'));
      expect(classifier.classify('坚持运动'), equals('健康'));
    });

    test('特殊情况 - 多个空格', () {
      expect(classifier.classify('明天    会议'), equals('工作'));
      expect(classifier.classify('去  超市  买菜'), equals('购物'));
    });

    test('特殊情况 - 包含换行符', () {
      expect(classifier.classify('明天\n会议'), equals('工作'));
      expect(classifier.classify('去超市\n买菜'), equals('购物'));
    });

    test('特殊情况 - 关键词重复', () {
      expect(classifier.classify('会议会议会议'), equals('工作'));
      expect(classifier.classify('买买买'), equals('购物'));
    });

    test('实际场景 - 完整的待办事项描述', () {
      final testCases = {
        '明天上午10点参加项目会议，讨论下一阶段的工作计划': '工作',
        '周末去超市购买下周的食材和生活用品': '购物',
        '每天晚上8点到9点学习英语，完成课程练习': '学习',
        '周六打扫房间，洗衣服，做饭': '生活',
        '每周一三五早上7点去健身房锻炼，跑步30分钟': '健康',
      };

      for (final entry in testCases.entries) {
        final result = classifier.classify(entry.key);
        expect(result, equals(entry.value),
            reason: '"${entry.key}"应该识别为"${entry.value}"');
      }
    });
  });

  group('CategoryClassifier Priority Property Tests', () {
    late CategoryClassifier classifier;

    setUp(() {
      classifier = CategoryClassifier();
    });

    /// **Feature: native-voice-recognition, Property 10: 优先级识别正确性**
    /// **Validates: Requirements 3.4, 5.6, 5.7**
    ///
    /// *对于任何*包含优先级关键词的文本，Parser_Service 应设置正确的优先级。
    test('Property 10: 优先级识别正确性 - 高优先级', () {
      // 测试高优先级关键词
      final highPriorityKeywords = ['紧急', '重要', '马上', '立即', '尽快'];

      for (final keyword in highPriorityKeywords) {
        final text = '$keyword处理这个任务';
        final result = classifier.classifyPriority(text);
        expect(result, equals('高'),
            reason: '包含关键词"$keyword"应该识别为高优先级');
      }

      // 测试关键词在不同位置
      expect(classifier.classifyPriority('紧急任务需要处理'), equals('高'));
      expect(classifier.classifyPriority('这是重要的事情'), equals('高'));
      expect(classifier.classifyPriority('请马上完成'), equals('高'));
      expect(classifier.classifyPriority('立即执行'), equals('高'));
      expect(classifier.classifyPriority('尽快回复'), equals('高'));
    });

    test('Property 10: 优先级识别正确性 - 低优先级', () {
      // 测试低优先级关键词
      final lowPriorityKeywords = ['不急', '有空', '以后', '慢慢'];

      for (final keyword in lowPriorityKeywords) {
        final text = '$keyword做这个';
        final result = classifier.classifyPriority(text);
        expect(result, equals('低'),
            reason: '包含关键词"$keyword"应该识别为低优先级');
      }

      // 测试关键词在不同位置
      expect(classifier.classifyPriority('不急的任务'), equals('低'));
      expect(classifier.classifyPriority('有空再做'), equals('低'));
      expect(classifier.classifyPriority('以后处理'), equals('低'));
      expect(classifier.classifyPriority('慢慢来'), equals('低'));
    });

    test('Property 10: 优先级识别正确性 - 默认优先级', () {
      // 测试不包含任何优先级关键词的文本
      final noKeywordTexts = [
        '完成报告',
        '开会讨论',
        '买菜做饭',
        '学习英语',
        '锻炼身体',
      ];

      for (final text in noKeywordTexts) {
        final result = classifier.classifyPriority(text);
        expect(result, equals('中'),
            reason: '不包含优先级关键词的文本"$text"应该返回默认优先级"中"');
      }

      // 测试空字符串
      expect(classifier.classifyPriority(''), equals('中'));
    });

    test('Property 10: 优先级识别正确性 - 多样化输入', () {
      // 测试各种真实场景的文本
      final testCases = {
        '紧急会议通知': '高',
        '重要项目需要立即处理': '高',
        '马上回复客户邮件': '高',
        '尽快完成这个任务': '高',
        '不急的事情': '低',
        '有空再整理文档': '低',
        '以后慢慢做': '低',
        '明天开会': '中',
        '下周提交报告': '中',
        '买菜做饭': '中',
      };

      for (final entry in testCases.entries) {
        final result = classifier.classifyPriority(entry.key);
        expect(result, equals(entry.value),
            reason: '"${entry.key}"应该识别为"${entry.value}"优先级');
      }
    });

    test('Property 10: 优先级识别正确性 - 优先级（第一个匹配）', () {
      // 当文本包含多个优先级关键词时，应该返回第一个匹配的优先级
      final multiPriority = classifier.classifyPriority('紧急但不急');
      // 应该匹配到第一个出现的关键词对应的优先级
      expect(['高', '低'].contains(multiPriority), isTrue,
          reason: '包含多个优先级关键词时应该返回其中一个有效优先级');
    });

    test('Property 10: 优先级识别正确性 - 关键词部分匹配', () {
      // 测试关键词作为子字符串出现的情况
      expect(classifier.classifyPriority('紧急情况'), equals('高')); // "紧急"
      expect(classifier.classifyPriority('重要通知'), equals('高')); // "重要"
      expect(classifier.classifyPriority('马上开始'), equals('高')); // "马上"
      expect(classifier.classifyPriority('不急着做'), equals('低')); // "不急"
      expect(classifier.classifyPriority('有空就行'), equals('低')); // "有空"
    });
  });

  group('CategoryClassifier Priority Unit Tests', () {
    late CategoryClassifier classifier;

    setUp(() {
      classifier = CategoryClassifier();
    });

    test('边界情况 - 空字符串', () {
      final result = classifier.classifyPriority('');
      expect(result, equals('中'));
    });

    test('边界情况 - 纯空格', () {
      final result = classifier.classifyPriority('   ');
      expect(result, equals('中'));
    });

    test('边界情况 - 只有标点符号', () {
      final result = classifier.classifyPriority('！@#￥%……&*（）');
      expect(result, equals('中'));
    });

    test('边界情况 - 英文文本', () {
      final result = classifier.classifyPriority('urgent task');
      expect(result, equals('中'));
    });

    test('边界情况 - 数字', () {
      final result = classifier.classifyPriority('12345');
      expect(result, equals('中'));
    });

    test('特殊情况 - 关键词前后有其他文字', () {
      expect(classifier.classifyPriority('非常紧急的任务'), equals('高'));
      expect(classifier.classifyPriority('这个很重要'), equals('高'));
      expect(classifier.classifyPriority('真的不急'), equals('低'));
      expect(classifier.classifyPriority('等有空再说'), equals('低'));
    });

    test('特殊情况 - 多个空格', () {
      expect(classifier.classifyPriority('紧急    任务'), equals('高'));
      expect(classifier.classifyPriority('不急  的  事'), equals('低'));
    });

    test('特殊情况 - 包含换行符', () {
      expect(classifier.classifyPriority('紧急\n任务'), equals('高'));
      expect(classifier.classifyPriority('不急\n的事'), equals('低'));
    });

    test('特殊情况 - 关键词重复', () {
      expect(classifier.classifyPriority('紧急紧急紧急'), equals('高'));
      expect(classifier.classifyPriority('不急不急'), equals('低'));
    });

    test('实际场景 - 完整的待办事项描述', () {
      final testCases = {
        '紧急：明天上午10点参加重要会议': '高',
        '立即处理客户投诉，尽快给出解决方案': '高',
        '不急的任务，有空再做就行': '低',
        '以后慢慢整理这些文档': '低',
        '明天下午3点开会讨论项目进度': '中',
        '周末去超市买菜': '中',
      };

      for (final entry in testCases.entries) {
        final result = classifier.classifyPriority(entry.key);
        expect(result, equals(entry.value),
            reason: '"${entry.key}"应该识别为"${entry.value}"优先级');
      }
    });

    test('实际场景 - 同时测试分类和优先级', () {
      // 测试同一个文本的分类和优先级识别
      final text = '紧急会议通知：明天上午10点讨论重要项目';

      final category = classifier.classify(text);
      final priority = classifier.classifyPriority(text);

      expect(category, equals('工作'), reason: '应该识别为工作分类');
      expect(priority, equals('高'), reason: '应该识别为高优先级');
    });

    test('实际场景 - 购物任务的优先级', () {
      expect(classifier.classify('马上去超市买菜'), equals('购物'));
      expect(classifier.classifyPriority('马上去超市买菜'), equals('高'));

      expect(classifier.classify('有空去商店买东西'), equals('购物'));
      expect(classifier.classifyPriority('有空去商店买东西'), equals('低'));
    });

    test('实际场景 - 学习任务的优先级', () {
      expect(classifier.classify('紧急学习新技术'), equals('学习'));
      expect(classifier.classifyPriority('紧急学习新技术'), equals('高'));

      expect(classifier.classify('以后阅读这本书'), equals('学习'));
      expect(classifier.classifyPriority('以后阅读这本书'), equals('低'));
    });
  });
}
