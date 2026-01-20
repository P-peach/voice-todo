/// 分类识别器
/// 
/// 根据关键词识别待办事项的分类和优先级
class CategoryClassifier {
  // 分类关键词映射表
  static const Map<String, List<String>> categoryKeywords = {
    '工作': ['会议', '报告', '项目', '巡检', '进货', '任务'],
    '购物': ['买', '购买', '超市', '商店', '购物'],
    '学习': ['学习', '阅读', '课程', '练习', '复习'],
    '生活': ['打扫', '做饭', '洗衣', '生日', '提醒', '家务'],
    '健康': ['运动', '锻炼', '健身', '跑步', '瑜伽'],
  };

  // 优先级关键词映射表
  static const Map<String, List<String>> priorityKeywords = {
    '高': ['紧急', '重要', '马上', '立即', '尽快'],
    '低': ['不急', '有空', '以后', '慢慢'],
  };

  /// 识别分类
  /// 
  /// 根据文本中的关键词识别待办事项的分类
  /// 如果没有匹配的关键词，返回默认值 '其他'
  String classify(String text) {
    if (text.isEmpty) {
      return '其他';
    }

    // 遍历所有分类，查找匹配的关键词
    for (final entry in categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;

      // 检查文本中是否包含该分类的任何关键词
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          return category;
        }
      }
    }

    // 没有匹配的关键词，返回默认值
    return '其他';
  }

  /// 识别优先级
  /// 
  /// 根据文本中的关键词识别待办事项的优先级
  /// 如果没有匹配的关键词，返回默认值 '中'
  String classifyPriority(String text) {
    if (text.isEmpty) {
      return '中';
    }

    // 遍历所有优先级，查找匹配的关键词
    for (final entry in priorityKeywords.entries) {
      final priority = entry.key;
      final keywords = entry.value;

      // 检查文本中是否包含该优先级的任何关键词
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          return priority;
        }
      }
    }

    // 没有匹配的关键词，返回默认值
    return '中';
  }
}
