/// 列表模式检测器
///
/// 识别并分割列表式待办事项（如"苹果两箱，茼蒿10把，草莓，土豆一箱"）
/// 提取共享属性（时间、分类）和数量信息
class ListModeDetector {
  /// 列表分隔符（逗号、顿号、分号）
  static const List<String> _listDelimiters = ['，', '、', '；', ',', ';'];

  /// 常见果蔬商品名称词库
  static const List<String> _productNames = [
    // 水果
    '苹果', '香蕉', '橙子', '橘子', '柚子', '柠檬', '梨', '桃子', '李子', '杏',
    '樱桃', '草莓', '蓝莓', '黑莓', '覆盆子', '葡萄', '西瓜', '哈密瓜', '甜瓜',
    '猕猴桃', '火龙果', '芒果', '木瓜', '菠萝', '榴莲', '山竹', '荔枝', '龙眼',
    '石榴', '柿子', '枣', '无花果', '椰子', '牛油果', '百香果', '杨桃', '枇杷',
    
    // 蔬菜
    '黄瓜', '番茄', '西红柿', '茄子', '辣椒', '青椒', '红椒', '彩椒', '南瓜',
    '冬瓜', '丝瓜', '苦瓜', '葫芦', '西葫芦', '豆角', '四季豆', '豇豆', '扁豆',
    '豌豆', '毛豆', '蚕豆', '土豆', '红薯', '山药', '芋头', '莲藕', '萝卜',
    '胡萝卜', '白萝卜', '青萝卜', '红萝卜', '洋葱', '大葱', '小葱', '韭菜',
    '韭黄', '蒜', '大蒜', '蒜苗', '蒜薹', '生姜', '芹菜', '香菜', '菠菜',
    '生菜', '油麦菜', '莴笋', '茼蒿', '空心菜', '油菜', '小白菜', '大白菜',
    '娃娃菜', '包菜', '卷心菜', '紫甘蓝', '西兰花', '花菜', '菜花', '芥蓝',
    '芥菜', '雪里蕻', '苋菜', '木耳菜', '茴香', '香椿', '豆芽', '黄豆芽',
    '绿豆芽', '蘑菇', '香菇', '平菇', '金针菇', '杏鲍菇', '木耳', '银耳',
    
    // 其他常见商品
    '鸡蛋', '鸭蛋', '鹌鹑蛋', '牛奶', '酸奶', '豆腐', '豆浆', '面包', '馒头',
    '包子', '饺子', '面条', '米', '大米', '面粉', '油', '盐', '糖', '醋',
    '酱油', '味精', '鸡精', '料酒', '蚝油', '豆瓣酱', '辣椒酱', '番茄酱',
  ];

  /// 时间关键词（用于识别共享时间属性）
  static const List<String> _timeKeywords = [
    '今天', '明天', '后天', '大后天',
    '上午', '下午', '晚上', '中午', '凌晨', '早上', '傍晚', '深夜',
    '周一', '周二', '周三', '周四', '周五', '周六', '周日',
    '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日',
    '天后', '周后', '月后', '星期后',
    '点', '时',
  ];

  /// 分类关键词（用于识别共享分类属性）
  static const List<String> _categoryKeywords = [
    '会议', '报告', '项目', '巡检', '进货', '任务', // 工作
    '买', '购买', '超市', '商店', '购物', // 购物
    '学习', '阅读', '课程', '练习', '复习', // 学习
    '打扫', '做饭', '洗衣', '生日', '提醒', '家务', // 生活
    '运动', '锻炼', '健身', '跑步', '瑜伽', // 健康
  ];

  /// 检测是否为列表模式
  ///
  /// 判断标准：
  /// 1. 包含列表分隔符（逗号、顿号、分号）
  /// 2. 分隔符分割后至少有2个非空项
  /// 3. 每个项都相对简短（不是长句子）
  /// 4. 不是包含连接词的长句子
  /// 5. 或者包含多个商品名称（如"黄瓜一箱苹果两箱"）
  bool isListMode(String text) {
    if (text.trim().isEmpty) return false;

    // 方式1：基于分隔符的列表检测
    bool hasDelimiter = false;
    for (final delimiter in _listDelimiters) {
      if (text.contains(delimiter)) {
        hasDelimiter = true;
        break;
      }
    }

    if (hasDelimiter) {
      // 尝试分割并检查项数
      final items = _splitItemsRaw(text);
      if (items.length < 2) return false;

      // 检查每个项是否相对简短（不超过15个字符）
      // 这样可以避免将长句子误判为列表
      int longItemCount = 0;
      for (final item in items) {
        if (item.length > 15) {
          longItemCount++;
        }
      }

      // 如果有超过一半的项都很长，可能是长句子而不是列表
      if (longItemCount > items.length / 2) {
        return false;
      }

      // 检查是否包含连接词（"并"、"请"等），这些通常出现在长句子中
      // 但要排除"并"出现在第一个分隔符之前的情况（那可能是共享属性）
      final connectWords = ['请', '以便', '因为', '所以', '如果', '那么'];
      for (final word in connectWords) {
        if (text.contains(word)) {
          return false;
        }
      }

      return true;
    }

    // 方式2：基于商品名称的列表检测
    // 检测文本中是否包含多个商品名称
    final productMatches = _findProductMatches(text);
    if (productMatches.length >= 2) {
      // 确保商品名称之间有数量信息或其他内容
      // 避免误判如"买苹果"这种单一商品的情况
      return true;
    }

    return false;
  }

  /// 原始分割（不移除共享部分）
  List<String> _splitItemsRaw(String text) {
    if (text.trim().isEmpty) return [];

    // 使用正则表达式分割（支持多种分隔符）
    final delimiterPattern = RegExp('[${_listDelimiters.join()}]');
    final items = text.split(delimiterPattern);

    // 清理并过滤空项
    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// 分割列表项
  ///
  /// 按照分隔符或商品名称分割文本，返回清理后的项列表
  /// 会移除空项和前后空格
  /// 只有当共享部分明确是时间或分类前缀时才移除
  List<String> splitItems(String text) {
    if (text.trim().isEmpty) return [];

    // 检查是否有明确的共享前缀（如"明天买"、"下周五购买"）
    // 只有当第一个词是时间或分类关键词时才移除
    String itemsText = text;
    final sharedPrefix = _extractSharedPrefix(text);
    if (sharedPrefix.isNotEmpty) {
      // 移除共享前缀，只保留列表项
      itemsText = text.substring(sharedPrefix.length).trim();
    }

    // 方式1：基于分隔符的分割
    bool hasDelimiter = false;
    for (final delimiter in _listDelimiters) {
      if (itemsText.contains(delimiter)) {
        hasDelimiter = true;
        break;
      }
    }

    if (hasDelimiter) {
      // 使用正则表达式分割（支持多种分隔符）
      final delimiterPattern = RegExp('[${_listDelimiters.join()}]');
      final items = itemsText.split(delimiterPattern);

      // 清理并过滤空项
      return items
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    // 方式2：基于商品名称的分割
    final productMatches = _findProductMatches(itemsText);
    if (productMatches.length >= 2) {
      return _splitByProducts(itemsText, productMatches);
    }

    // 如果既没有分隔符也没有多个商品，返回整个文本作为单项
    return [itemsText];
  }

  /// 查找文本中的所有商品名称匹配
  /// 返回匹配信息列表：[{name: 商品名, start: 起始位置, end: 结束位置}]
  List<Map<String, dynamic>> _findProductMatches(String text) {
    final matches = <Map<String, dynamic>>[];

    // 按商品名称长度降序排序，优先匹配长的商品名（避免"西红柿"被"红"匹配）
    final sortedProducts = List<String>.from(_productNames)
      ..sort((a, b) => b.length.compareTo(a.length));

    // 记录已匹配的位置，避免重复匹配
    final matchedPositions = <int>{};

    for (final product in sortedProducts) {
      int index = 0;
      while (index < text.length) {
        final foundIndex = text.indexOf(product, index);
        if (foundIndex < 0) break;

        // 检查这个位置是否已被匹配
        bool isOverlap = false;
        for (int i = foundIndex; i < foundIndex + product.length; i++) {
          if (matchedPositions.contains(i)) {
            isOverlap = true;
            break;
          }
        }

        if (!isOverlap) {
          matches.add({
            'name': product,
            'start': foundIndex,
            'end': foundIndex + product.length,
          });

          // 标记已匹配的位置
          for (int i = foundIndex; i < foundIndex + product.length; i++) {
            matchedPositions.add(i);
          }
        }

        index = foundIndex + 1;
      }
    }

    // 按起始位置排序
    matches.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

    return matches;
  }

  /// 根据商品名称分割文本
  /// 例如："黄瓜一箱苹果两箱" -> ["黄瓜一箱", "苹果两箱"]
  List<String> _splitByProducts(String text, List<Map<String, dynamic>> productMatches) {
    final items = <String>[];

    for (int i = 0; i < productMatches.length; i++) {
      final match = productMatches[i];
      final start = match['start'] as int;

      // 确定这个商品项的结束位置
      int end;
      if (i < productMatches.length - 1) {
        // 不是最后一个商品，结束位置是下一个商品的开始位置
        end = productMatches[i + 1]['start'] as int;
      } else {
        // 最后一个商品，结束位置是文本末尾
        end = text.length;
      }

      // 提取商品项（包括商品名和后面的数量信息）
      final item = text.substring(start, end).trim();
      if (item.isNotEmpty) {
        items.add(item);
      }
    }

    return items;
  }

  /// 提取共享前缀（只提取明确的时间+动词组合）
  /// 例如："明天买" -> "明天买"
  /// 但不提取："明天买苹果"（"苹果"是第一个列表项）
  String _extractSharedPrefix(String text) {
    // 找到第一个分隔符的位置
    int firstDelimiterIndex = -1;
    for (final delimiter in _listDelimiters) {
      final index = text.indexOf(delimiter);
      if (index >= 0 && (firstDelimiterIndex < 0 || index < firstDelimiterIndex)) {
        firstDelimiterIndex = index;
      }
    }

    // 如果没有分隔符，返回空
    if (firstDelimiterIndex < 0) return '';

    // 只在第一个分隔符之前查找
    final beforeDelimiter = text.substring(0, firstDelimiterIndex);

    // 查找时间关键词的位置
    int timeKeywordEnd = -1;
    for (final keyword in _timeKeywords) {
      final index = beforeDelimiter.indexOf(keyword);
      if (index >= 0) {
        final keywordEnd = index + keyword.length;
        if (keywordEnd > timeKeywordEnd) {
          timeKeywordEnd = keywordEnd;
        }
      }
    }

    // 如果没有时间关键词，返回空
    if (timeKeywordEnd < 0) return '';

    // 查找时间关键词后面的分类关键词（动作词）
    final afterTime = beforeDelimiter.substring(timeKeywordEnd);
    for (final keyword in _categoryKeywords) {
      final index = afterTime.indexOf(keyword);
      if (index >= 0) {
        // 只提取到分类关键词结束的位置
        final categoryEnd = timeKeywordEnd + index + keyword.length;
        return beforeDelimiter.substring(0, categoryEnd);
      }
    }

    return '';
  }

  /// 提取共享属性（时间、分类）
  ///
  /// 返回包含共享属性的 Map：
  /// - 'timeExpression': 时间表达式（如"明天上午"）
  /// - 'categoryHint': 分类提示（如"买"、"购物"）
  Map<String, String> extractSharedAttributes(String text) {
    final result = <String, String>{};

    // 提取时间表达式
    final timeExpression = _extractTimeExpression(text);
    if (timeExpression != null) {
      result['timeExpression'] = timeExpression;
    }

    // 提取分类提示
    final categoryHint = _extractCategoryHint(text);
    if (categoryHint != null) {
      result['categoryHint'] = categoryHint;
    }

    return result;
  }

  /// 提取数量信息
  ///
  /// 从单个项中提取数量信息（如"苹果两箱" -> "两箱"）
  /// 如果没有数量信息，返回 null
  String? extractQuantity(String item) {
    if (item.trim().isEmpty) return null;

    // 匹配数量模式：数字+量词 或 中文数字+量词
    // 支持更多量词，包括"串"和多字符量词如"公斤"
    final patterns = [
      // 小数+多字符量词（如"公斤"、"毫升"）
      RegExp(r'(\d+\.\d+(?:公斤|毫升|升))'),
      // 小数+单字符量词
      RegExp(r'(\d+\.\d+[个只件箱包袋斤克吨瓶罐盒条根支张片块份串])'),
      // 整数+多字符量词
      RegExp(r'(\d+(?:公斤|毫升|升))'),
      // 整数+单字符量词
      RegExp(r'(\d+[个只件箱包袋斤克吨瓶罐盒条根支张片块份串])'),
      // 中文数字+多字符量词
      RegExp(r'([一二三四五六七八九十两俩百千万]+(?:公斤|毫升|升))'),
      // 中文数字+单字符量词
      RegExp(r'([一二三四五六七八九十两俩百千万]+[个只件箱包袋斤克吨瓶罐盒条根支张片块份串])'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(item);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// 提取时间表达式
  String? _extractTimeExpression(String text) {
    for (final keyword in _timeKeywords) {
      if (text.contains(keyword)) {
        // 找到关键词的位置
        final index = text.indexOf(keyword);

        // 检查这个关键词是否在列表项之前
        bool isBeforeList = false;
        for (final delimiter in _listDelimiters) {
          final delimiterIndex = text.indexOf(delimiter);
          if (delimiterIndex > 0 && index < delimiterIndex) {
            isBeforeList = true;
            break;
          }
        }

        if (isBeforeList) {
          // 提取包含时间关键词的短语
          // 从关键词开始，向前找到空格或开头，向后找到分隔符或结尾
          int start = index;
          while (start > 0 && text[start - 1] != ' ' && !_listDelimiters.contains(text[start - 1])) {
            start--;
          }

          int end = index + keyword.length;
          while (end < text.length && !_listDelimiters.contains(text[end])) {
            end++;
          }

          return text.substring(start, end).trim();
        }
      }
    }

    return null;
  }

  /// 提取分类提示
  String? _extractCategoryHint(String text) {
    for (final keyword in _categoryKeywords) {
      if (text.contains(keyword)) {
        final index = text.indexOf(keyword);

        // 检查这个关键词是否在列表项之前
        bool isBeforeList = false;
        for (final delimiter in _listDelimiters) {
          final delimiterIndex = text.indexOf(delimiter);
          if (delimiterIndex > 0 && index < delimiterIndex) {
            isBeforeList = true;
            break;
          }
        }

        if (isBeforeList) {
          return keyword;
        }
      }
    }

    return null;
  }
}
