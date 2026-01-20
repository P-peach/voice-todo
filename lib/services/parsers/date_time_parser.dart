import 'package:intl/intl.dart';

/// 日期时间解析器
///
/// 将自然语言的时间表达式转换为 DateTime 对象
/// 支持：相对日期、星期表达式、天数偏移、时间段、具体时间
class DateTimeParser {
  /// 中文数字映射
  static const Map<String, int> _chineseNumbers = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
    '两': 2, '俩': 2,
  };

  /// 星期映射
  static const Map<String, int> _weekdayMap = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
  };

  /// 时间段映射（小时）
  static const Map<String, int> _timePeriodMap = {
    '午夜': 0,
    '凌晨': 2,
    '早上': 8,
    '上午': 10,
    '正午': 12,
    '中午': 12,
    '下午': 15,
    '傍晚': 18,
    '晚上': 20,
    '深夜': 23,
  };

  /// 解析日期时间表达式
  ///
  /// 返回解析后的 DateTime，如果无法解析则返回 null
  DateTime? parse(String text) {
    if (text.trim().isEmpty) return null;

    final now = DateTime.now();
    DateTime? result;

    // 检查是否包含明确的时间表达式（点/时）
    final hasExplicitTime = text.contains(RegExp(r'[点时]'));

    // 1. 尝试解析相对日期
    result = _parseRelativeDate(text, now);
    if (result != null) {
      // 尝试添加时间信息
      final timeOfDay = _parseTimeOfDay(text);
      if (timeOfDay != null) {
        result = DateTime(
          result.year,
          result.month,
          result.day,
          timeOfDay,
        );
      } else if (hasExplicitTime) {
        // 如果文本中有明确的时间表达式但解析失败，返回null
        return null;
      }
      return result;
    }

    // 2. 尝试解析星期表达式
    result = _parseWeekday(text, now);
    if (result != null) {
      final timeOfDay = _parseTimeOfDay(text);
      if (timeOfDay != null) {
        result = DateTime(
          result.year,
          result.month,
          result.day,
          timeOfDay,
        );
      } else if (hasExplicitTime) {
        // 如果文本中有明确的时间表达式但解析失败，返回null
        return null;
      }
      return result;
    }

    // 3. 尝试解析天数偏移
    result = _parseDayOffset(text, now);
    if (result != null) {
      final timeOfDay = _parseTimeOfDay(text);
      if (timeOfDay != null) {
        result = DateTime(
          result.year,
          result.month,
          result.day,
          timeOfDay,
        );
      } else if (hasExplicitTime) {
        // 如果文本中有明确的时间表达式但解析失败，返回null
        return null;
      }
      return result;
    }

    // 4. 如果只有时间信息，使用今天的日期
    final timeOfDay = _parseTimeOfDay(text);
    if (timeOfDay != null) {
      return DateTime(now.year, now.month, now.day, timeOfDay);
    }

    return null;
  }

  /// 解析相对日期（今天、明天、后天）
  DateTime? _parseRelativeDate(String text, DateTime now) {
    if (text.contains('今天') || text.contains('今日')) {
      return DateTime(now.year, now.month, now.day);
    }

    if (text.contains('明天') || text.contains('明日')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }

    if (text.contains('后天')) {
      final dayAfterTomorrow = now.add(const Duration(days: 2));
      return DateTime(
        dayAfterTomorrow.year,
        dayAfterTomorrow.month,
        dayAfterTomorrow.day,
      );
    }

    if (text.contains('大后天')) {
      final threeDaysLater = now.add(const Duration(days: 3));
      return DateTime(
        threeDaysLater.year,
        threeDaysLater.month,
        threeDaysLater.day,
      );
    }

    return null;
  }

  /// 解析星期表达式（下周一、下周五、本周三）
  DateTime? _parseWeekday(String text, DateTime now) {
    // 检查是否包含星期关键词
    String? targetWeekdayKey;
    for (final key in _weekdayMap.keys) {
      if (text.contains('周$key') || text.contains('星期$key')) {
        targetWeekdayKey = key;
        break;
      }
    }

    if (targetWeekdayKey == null) return null;

    final targetWeekday = _weekdayMap[targetWeekdayKey]!;
    final currentWeekday = now.weekday;

    // 判断是本周还是下周
    bool isNextWeek = text.contains('下周') || text.contains('下星期');
    bool isThisWeek = text.contains('本周') || text.contains('这周') || text.contains('这星期');

    int daysToAdd;

    if (isNextWeek) {
      // 下周：计算到下周目标星期的天数
      daysToAdd = (7 - currentWeekday) + targetWeekday;
    } else if (isThisWeek) {
      // 本周：如果目标日期已过，返回null；否则计算天数
      if (targetWeekday < currentWeekday) {
        return null; // 本周的这一天已经过去了
      }
      daysToAdd = targetWeekday - currentWeekday;
    } else {
      // 没有明确说明，默认为下一个该星期
      if (targetWeekday <= currentWeekday) {
        // 如果目标星期小于等于当前星期，指向下周
        daysToAdd = (7 - currentWeekday) + targetWeekday;
      } else {
        // 否则指向本周
        daysToAdd = targetWeekday - currentWeekday;
      }
    }

    final targetDate = now.add(Duration(days: daysToAdd));
    return DateTime(targetDate.year, targetDate.month, targetDate.day);
  }

  /// 解析天数偏移（三天后、一周后、两个月后）
  DateTime? _parseDayOffset(String text, DateTime now) {
    // 匹配 "X天后"、"X周后"、"X个月后"
    final patterns = [
      RegExp(r'([一二三四五六七八九十两俩\d]+)天后'),
      RegExp(r'([一二三四五六七八九十两俩\d]+)周后'),
      RegExp(r'([一二三四五六七八九十两俩\d]+)星期后'),
      RegExp(r'([一二三四五六七八九十两俩\d]+)个?月后'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final numberStr = match.group(1)!;
        final number = _parseChineseNumber(numberStr);

        if (number == null) continue;

        DateTime targetDate;
        if (text.contains('天后')) {
          targetDate = now.add(Duration(days: number));
        } else if (text.contains('周后') || text.contains('星期后')) {
          targetDate = now.add(Duration(days: number * 7));
        } else if (text.contains('月后')) {
          targetDate = DateTime(now.year, now.month + number, now.day);
        } else {
          continue;
        }

        return DateTime(targetDate.year, targetDate.month, targetDate.day);
      }
    }

    return null;
  }

  /// 解析时间段和具体时间，返回小时数
  int? _parseTimeOfDay(String text) {
    // 1. 优先尝试解析具体时间（10点、下午3点、15:30）
    // 匹配 "X点" 或 "X时"，但要避免匹配到"周一"中的"一"
    // 使用负向后顾断言，确保数字/中文数字前面不是"周"或"星期"
    final hourPattern = RegExp(r'(?<!周)(?<!期)([一二三四五六七八九十两俩]?[一二三四五六七八九十\d]+)[点时]');
    final match = hourPattern.firstMatch(text);
    if (match != null) {
      final hourStr = match.group(1)!;
      
      // 检查匹配位置前是否有"-"符号
      final matchStart = match.start;
      if (matchStart > 0 && text[matchStart - 1] == '-') {
        // 如果前面是"-"，说明是负数，返回null
        return null;
      }
      
      var hour = _parseChineseNumber(hourStr);

      if (hour == null) return null;

      // 处理12小时制
      if (text.contains('下午') || text.contains('晚上')) {
        if (hour < 12) hour += 12;
      } else if (text.contains('凌晨') || text.contains('早上')) {
        if (hour == 12) hour = 0;
      }

      // 验证小时范围
      if (hour >= 0 && hour < 24) {
        return hour;
      }
      // 如果小时数无效，返回null而不是继续尝试时间段
      return null;
    }

    // 2. 匹配 HH:MM 格式
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    final timeMatch = timePattern.firstMatch(text);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1)!);
      if (hour != null && hour >= 0 && hour < 24) {
        return hour;
      }
      return null;
    }

    // 3. 最后尝试解析时间段（上午、下午、晚上等）
    for (final entry in _timePeriodMap.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// 解析中文数字
  int? _parseChineseNumber(String text) {
    // 如果是阿拉伯数字，直接解析
    final arabicNumber = int.tryParse(text);
    if (arabicNumber != null) return arabicNumber;

    // 处理中文数字
    if (_chineseNumbers.containsKey(text)) {
      return _chineseNumbers[text];
    }

    // 处理 "十X" 的情况（如"十一"、"十二"）
    if (text.startsWith('十')) {
      if (text.length == 1) return 10;
      final remainder = text.substring(1);
      final remainderValue = _chineseNumbers[remainder];
      if (remainderValue != null) {
        return 10 + remainderValue;
      }
    }

    // 处理 "X十" 的情况（如"二十"、"三十"）
    if (text.endsWith('十')) {
      if (text.length == 1) return 10;
      final prefix = text.substring(0, text.length - 1);
      final prefixValue = _chineseNumbers[prefix];
      if (prefixValue != null) {
        return prefixValue * 10;
      }
    }

    // 处理 "X十Y" 的情况（如"二十三"、"三十五"）
    final tenIndex = text.indexOf('十');
    if (tenIndex > 0 && tenIndex < text.length - 1) {
      final prefix = text.substring(0, tenIndex);
      final suffix = text.substring(tenIndex + 1);
      final prefixValue = _chineseNumbers[prefix];
      final suffixValue = _chineseNumbers[suffix];
      if (prefixValue != null && suffixValue != null) {
        return prefixValue * 10 + suffixValue;
      }
    }

    return null;
  }
}
