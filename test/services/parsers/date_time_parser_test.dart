import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo/services/parsers/date_time_parser.dart';

void main() {
  group('DateTimeParser Property Tests', () {
    late DateTimeParser parser;

    setUp(() {
      parser = DateTimeParser();
    });

    /// **Feature: native-voice-recognition, Property 8: 时间表达式解析正确性**
    /// **Validates: Requirements 3.2, 4.2, 4.4, 4.5, 4.6, 4.7**
    ///
    /// *对于任何*包含时间表达式的文本，Parser_Service 应正确解析并提取截止日期。
    test('Property 8: 时间表达式解析正确性 - 相对日期', () {
      final now = DateTime.now();

      // 测试"今天"
      final today = parser.parse('今天完成报告');
      expect(today, isNotNull);
      expect(today!.year, equals(now.year));
      expect(today.month, equals(now.month));
      expect(today.day, equals(now.day));

      // 测试"明天"
      final tomorrow = parser.parse('明天开会');
      expect(tomorrow, isNotNull);
      final expectedTomorrow = now.add(const Duration(days: 1));
      expect(tomorrow!.year, equals(expectedTomorrow.year));
      expect(tomorrow.month, equals(expectedTomorrow.month));
      expect(tomorrow.day, equals(expectedTomorrow.day));

      // 测试"后天"
      final dayAfterTomorrow = parser.parse('后天交作业');
      expect(dayAfterTomorrow, isNotNull);
      final expectedDayAfter = now.add(const Duration(days: 2));
      expect(dayAfterTomorrow!.year, equals(expectedDayAfter.year));
      expect(dayAfterTomorrow.month, equals(expectedDayAfter.month));
      expect(dayAfterTomorrow.day, equals(expectedDayAfter.day));
    });

    test('Property 8: 时间表达式解析正确性 - 星期表达式', () {
      final now = DateTime.now();
      final currentWeekday = now.weekday;

      // 测试"下周一"
      final nextMonday = parser.parse('下周一开会');
      expect(nextMonday, isNotNull);
      expect(nextMonday!.weekday, equals(DateTime.monday));
      // 下周一应该在未来
      expect(nextMonday.isAfter(now), isTrue);
      // 应该在7-13天之间
      final daysUntilNextMonday = nextMonday.difference(now).inDays;
      expect(daysUntilNextMonday, greaterThanOrEqualTo(1));
      expect(daysUntilNextMonday, lessThanOrEqualTo(13));

      // 测试"下周五"
      final nextFriday = parser.parse('下周五提交报告');
      expect(nextFriday, isNotNull);
      expect(nextFriday!.weekday, equals(DateTime.friday));
      expect(nextFriday.isAfter(now), isTrue);
    });

    test('Property 8: 时间表达式解析正确性 - 天数偏移', () {
      final now = DateTime.now();

      // 测试"三天后"
      final threeDaysLater = parser.parse('三天后完成');
      expect(threeDaysLater, isNotNull);
      final expected3Days = now.add(const Duration(days: 3));
      expect(threeDaysLater!.year, equals(expected3Days.year));
      expect(threeDaysLater.month, equals(expected3Days.month));
      expect(threeDaysLater.day, equals(expected3Days.day));

      // 测试"一周后"
      final oneWeekLater = parser.parse('一周后检查');
      expect(oneWeekLater, isNotNull);
      final expected1Week = now.add(const Duration(days: 7));
      expect(oneWeekLater!.year, equals(expected1Week.year));
      expect(oneWeekLater.month, equals(expected1Week.month));
      expect(oneWeekLater.day, equals(expected1Week.day));

      // 测试"5天后"（阿拉伯数字）
      final fiveDaysLater = parser.parse('5天后提交');
      expect(fiveDaysLater, isNotNull);
      final expected5Days = now.add(const Duration(days: 5));
      expect(fiveDaysLater!.year, equals(expected5Days.year));
      expect(fiveDaysLater.month, equals(expected5Days.month));
      expect(fiveDaysLater.day, equals(expected5Days.day));
    });

    test('Property 8: 时间表达式解析正确性 - 时间段', () {
      final now = DateTime.now();

      // 测试"上午"
      final morning = parser.parse('明天上午开会');
      expect(morning, isNotNull);
      expect(morning!.hour, equals(10)); // 上午默认10点

      // 测试"下午"
      final afternoon = parser.parse('今天下午提交');
      expect(afternoon, isNotNull);
      expect(afternoon!.hour, equals(15)); // 下午默认15点

      // 测试"晚上"
      final evening = parser.parse('今天晚上复习');
      expect(evening, isNotNull);
      expect(evening!.hour, equals(20)); // 晚上默认20点

      // 测试"中午"
      final noon = parser.parse('明天中午吃饭');
      expect(noon, isNotNull);
      expect(noon!.hour, equals(12)); // 中午12点
    });

    test('Property 8: 时间表达式解析正确性 - 具体时间', () {
      final now = DateTime.now();

      // 测试"10点"
      final tenOclock = parser.parse('明天10点开会');
      expect(tenOclock, isNotNull);
      expect(tenOclock!.hour, equals(10));

      // 测试"下午3点"
      final threePM = parser.parse('今天下午3点提交');
      expect(threePM, isNotNull);
      expect(threePM!.hour, equals(15)); // 下午3点 = 15点

      // 测试"晚上8点"
      final eightPM = parser.parse('今天晚上8点复习');
      expect(eightPM, isNotNull);
      expect(eightPM!.hour, equals(20)); // 晚上8点 = 20点
    });

    test('Property 8: 时间表达式解析正确性 - 组合表达式', () {
      // 测试日期+时间段组合
      final tomorrowMorning = parser.parse('明天上午完成报告');
      expect(tomorrowMorning, isNotNull);
      final now = DateTime.now();
      final expectedDate = now.add(const Duration(days: 1));
      expect(tomorrowMorning!.day, equals(expectedDate.day));
      expect(tomorrowMorning.hour, equals(10));

      // 测试星期+时间组合
      final mondayTen = parser.parse('下周一10点开会');
      expect(mondayTen, isNotNull);
      expect(mondayTen!.weekday, equals(DateTime.monday));
      expect(mondayTen.hour, equals(10));
    });

    test('Property 8: 时间表达式解析正确性 - 多样化输入', () {
      // 使用不同的时间表达式进行测试
      final testCases = [
        '今天下午3点开会',
        '明天上午10点提交报告',
        '后天中午吃饭',
        '下周一早上8点',
        '三天后晚上复习',
        '一周后下午检查',
        '下周五下午3点面试',
      ];

      for (final testCase in testCases) {
        final result = parser.parse(testCase);
        expect(result, isNotNull, reason: '应该能解析: $testCase');
        expect(result!.isAfter(DateTime.now().subtract(const Duration(days: 1))),
            isTrue,
            reason: '解析结果应该是有效的日期时间: $testCase');
      }
    });

    test('Property 8: 时间表达式解析正确性 - 边界情况', () {
      // 测试空字符串
      final empty = parser.parse('');
      expect(empty, isNull);

      // 测试没有时间表达式的文本
      final noTime = parser.parse('买苹果');
      expect(noTime, isNull);

      // 测试只有时间没有日期
      final onlyTime = parser.parse('10点开会');
      expect(onlyTime, isNotNull);
      final now = DateTime.now();
      expect(onlyTime!.day, equals(now.day)); // 应该使用今天的日期
      expect(onlyTime.hour, equals(10));
    });
  });

  group('DateTimeParser Unit Tests', () {
    late DateTimeParser parser;

    setUp(() {
      parser = DateTimeParser();
    });

    test('边界情况 - 午夜（00:00）', () {
      final midnight = parser.parse('今天午夜提交');
      expect(midnight, isNotNull);
      expect(midnight!.hour, equals(0));
    });

    test('边界情况 - 正午（12:00）', () {
      final noon = parser.parse('明天正午开会');
      expect(noon, isNotNull);
      expect(noon!.hour, equals(12));
    });

    test('边界情况 - 23点', () {
      final lateNight = parser.parse('今天23点完成');
      expect(lateNight, isNotNull);
      expect(lateNight!.hour, equals(23));
    });

    test('边界情况 - 0点', () {
      final zero = parser.parse('明天0点开始');
      expect(zero, isNotNull);
      expect(zero!.hour, equals(0));
    });

    test('无效输入 - 空字符串', () {
      final result = parser.parse('');
      expect(result, isNull);
    });

    test('无效输入 - 纯空格', () {
      final result = parser.parse('   ');
      expect(result, isNull);
    });

    test('无效输入 - 无时间表达式', () {
      final result = parser.parse('买苹果和香蕉');
      expect(result, isNull);
    });

    test('无效输入 - 无效的小时数（超过24）', () {
      final result = parser.parse('今天25点开会');
      expect(result, isNull);
    });

    test('无效输入 - 无效的小时数（负数）', () {
      final result = parser.parse('明天-5点提交');
      expect(result, isNull);
    });

    test('边界情况 - 只有日期没有时间', () {
      final result = parser.parse('明天完成报告');
      expect(result, isNotNull);
      expect(result!.hour, equals(0)); // 默认为0点
    });

    test('边界情况 - 只有时间没有日期', () {
      final now = DateTime.now();
      final result = parser.parse('10点开会');
      expect(result, isNotNull);
      expect(result!.day, equals(now.day)); // 应该使用今天
      expect(result.hour, equals(10));
    });

    test('边界情况 - 12小时制转换（下午1点 = 13点）', () {
      final result = parser.parse('今天下午1点开会');
      expect(result, isNotNull);
      expect(result!.hour, equals(13));
    });

    test('边界情况 - 12小时制转换（晚上11点 = 23点）', () {
      final result = parser.parse('今天晚上11点睡觉');
      expect(result, isNotNull);
      expect(result!.hour, equals(23));
    });

    test('边界情况 - 早上12点应该是0点', () {
      final result = parser.parse('明天早上12点开始');
      expect(result, isNotNull);
      expect(result!.hour, equals(0));
    });

    test('特殊情况 - 中文数字解析', () {
      final testCases = {
        '今天十点开会': 10,
        '明天十一点提交': 11,
        '后天二十点复习': 20,
        '下周一八点上班': 8,
      };

      for (final entry in testCases.entries) {
        final result = parser.parse(entry.key);
        expect(result, isNotNull, reason: '应该能解析: ${entry.key}');
        expect(result!.hour, equals(entry.value),
            reason: '${entry.key} 应该解析为 ${entry.value} 点');
      }
    });

    test('特殊情况 - 阿拉伯数字解析', () {
      final testCases = {
        '今天9点开会': 9,
        '明天14点提交': 14,
        '后天18点复习': 18,
        '下周一7点上班': 7,
      };

      for (final entry in testCases.entries) {
        final result = parser.parse(entry.key);
        expect(result, isNotNull, reason: '应该能解析: ${entry.key}');
        expect(result!.hour, equals(entry.value),
            reason: '${entry.key} 应该解析为 ${entry.value} 点');
      }
    });

    test('特殊情况 - 时间段优先级（具体时间优先于时间段）', () {
      // 当同时包含时间段和具体时间时，应该使用具体时间
      final result = parser.parse('明天上午9点开会');
      expect(result, isNotNull);
      expect(result!.hour, equals(9)); // 应该是9点，而不是上午的默认10点
    });

    test('特殊情况 - HH:MM 格式', () {
      final result = parser.parse('明天14:30开会');
      expect(result, isNotNull);
      expect(result!.hour, equals(14));
    });
  });
}
