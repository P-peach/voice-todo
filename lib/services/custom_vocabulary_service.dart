import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_similarity/string_similarity.dart';
import '../models/vocabulary_entry.dart';

/// 自定义词汇服务
/// 管理语音识别中常见的错误识别词汇及其正确映射
/// 使用 SharedPreferences 进行本地持久化存储
class CustomVocabularyService {
  // 单例模式
  static final CustomVocabularyService instance =
      CustomVocabularyService._internal();

  factory CustomVocabularyService() => instance;

  CustomVocabularyService._internal();

  // SharedPreferences 实例
  SharedPreferences? _prefs;

  // 词汇表存储键
  static const String _vocabularyKey = 'custom_vocabulary';
  static const String _defaultLoadedKey = 'default_vocabulary_loaded';

  // 内存中的词汇表缓存 (incorrect -> VocabularyEntry)
  final Map<String, VocabularyEntry> _vocabulary = {};

  // 初始化状态
  bool _isInitialized = false;

  // 模糊匹配阈值
  static const double _fuzzyMatchThreshold = 0.8;

  /// 初始化服务
  /// 从 SharedPreferences 加载词汇表
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // 从存储中加载词汇表
    await _loadVocabulary();

    // 首次启动时加载默认词汇
    await _loadDefaultVocabularyIfNeeded();

    _isInitialized = true;
  }

  /// 从 SharedPreferences 加载词汇表
  Future<void> _loadVocabulary() async {
    if (_prefs == null) return;

    final String? vocabularyJson = _prefs!.getString(_vocabularyKey);

    if (vocabularyJson != null && vocabularyJson.isNotEmpty) {
      try {
        final List<dynamic> vocabularyList = jsonDecode(vocabularyJson);

        _vocabulary.clear();

        for (final item in vocabularyList) {
          if (item is Map<String, dynamic>) {
            try {
              final entry = VocabularyEntry.fromMap(item);
              _vocabulary[entry.incorrect] = entry;
            } catch (e) {
              // 跳过无效的条目，继续加载其他条目
              print('Warning: Skipping invalid vocabulary entry: $e');
            }
          }
        }
      } catch (e) {
        // 如果 JSON 解析失败，清空词汇表
        print('Error loading vocabulary: $e');
        _vocabulary.clear();
      }
    }
  }

  /// 保存词汇表到 SharedPreferences
  Future<void> _saveVocabulary() async {
    if (_prefs == null) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    final vocabularyList =
        _vocabulary.values.map((entry) => entry.toMap()).toList();

    final vocabularyJson = jsonEncode(vocabularyList);

    await _prefs!.setString(_vocabularyKey, vocabularyJson);
  }

  /// 添加词汇条目
  /// 
  /// [incorrect] 错误识别的词汇
  /// [correct] 正确的词汇
  /// 
  /// 如果已存在相同的 incorrect 词汇，将更新为新的 correct 值
  Future<void> addEntry(String incorrect, String correct) async {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    // 验证输入
    if (incorrect.trim().isEmpty || correct.trim().isEmpty) {
      throw ArgumentError('Incorrect and correct terms cannot be empty');
    }

    final entry = VocabularyEntry(
      incorrect: incorrect.trim(),
      correct: correct.trim(),
      usageCount: 0,
      createdAt: DateTime.now(),
    );

    _vocabulary[entry.incorrect] = entry;

    // 立即持久化到存储
    await _saveVocabulary();
  }

  /// 移除词汇条目
  /// 
  /// [incorrect] 要移除的错误识别词汇
  /// 
  /// 返回是否成功移除（如果词汇不存在则返回 false）
  Future<bool> removeEntry(String incorrect) async {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    final removed = _vocabulary.remove(incorrect) != null;

    if (removed) {
      // 立即持久化到存储
      await _saveVocabulary();
    }

    return removed;
  }

  /// 获取所有词汇条目
  /// 
  /// 返回 Map<String, String>，键为错误词汇，值为正确词汇
  Map<String, String> getAllEntries() {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    return Map.fromEntries(
      _vocabulary.entries.map(
        (entry) => MapEntry(entry.key, entry.value.correct),
      ),
    );
  }

  /// 获取所有词汇条目的详细信息
  /// 
  /// 返回 List<VocabularyEntry>
  List<VocabularyEntry> getAllEntriesDetailed() {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    return _vocabulary.values.toList();
  }

  /// 获取单个词汇条目
  /// 
  /// [incorrect] 错误识别的词汇
  /// 
  /// 返回对应的 VocabularyEntry，如果不存在则返回 null
  VocabularyEntry? getEntry(String incorrect) {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    return _vocabulary[incorrect];
  }

  /// 增加词汇条目的使用次数
  /// 
  /// [incorrect] 错误识别的词汇
  /// 
  /// 内部方法，用于跟踪纠正的使用频率
  Future<void> _incrementUsage(String incorrect) async {
    final entry = _vocabulary[incorrect];
    if (entry != null) {
      _vocabulary[incorrect] = entry.incrementUsage();
      // 异步保存，不阻塞主流程
      _saveVocabulary();
    }
  }

  /// 清空所有词汇条目
  Future<void> clearAll() async {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    _vocabulary.clear();
    await _saveVocabulary();
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取词汇表大小
  int get vocabularySize => _vocabulary.length;

  /// 重新初始化服务（仅用于测试）
  /// 强制重新加载词汇表，即使已经初始化
  Future<void> reinitialize() async {
    _isInitialized = false;
    _vocabulary.clear();
    await initialize();
  }

  /// 加载默认词汇（首次启动时）
  Future<void> _loadDefaultVocabularyIfNeeded() async {
    if (_prefs == null) return;

    // 检查是否已加载过默认词汇
    final bool defaultLoaded = _prefs!.getBool(_defaultLoadedKey) ?? false;

    if (!defaultLoaded) {
      await loadDefaultGroceryVocabulary();
      await _prefs!.setBool(_defaultLoadedKey, true);
    }
  }

  /// 加载默认购物词汇（50+ 项）
  /// 包含中文蔬菜、水果和单位的常见识别错误
  Future<void> loadDefaultGroceryVocabulary() async {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    final defaultVocabulary = <String, String>{
      // 蔬菜类
      '白菜': '大白菜',
      '小白菜': '小白菜',
      '青菜': '青菜',
      '菠菜': '菠菜',
      '生菜': '生菜',
      '油菜': '油菜',
      '芹菜': '芹菜',
      '韭菜': '韭菜',
      '香菜': '香菜',
      '茼蒿': '茼蒿',
      '空心菜': '空心菜',
      '西兰花': '西兰花',
      '花菜': '花菜',
      '包菜': '包菜',
      '卷心菜': '卷心菜',
      '土豆': '土豆',
      '红薯': '红薯',
      '山药': '山药',
      '萝卜': '萝卜',
      '胡萝卜': '胡萝卜',
      '白萝卜': '白萝卜',
      '茄子': '茄子',
      '番茄': '番茄',
      '西红柿': '西红柿',
      '黄瓜': '黄瓜',
      '冬瓜': '冬瓜',
      '南瓜': '南瓜',
      '丝瓜': '丝瓜',
      '苦瓜': '苦瓜',
      '青椒': '青椒',
      '辣椒': '辣椒',
      '洋葱': '洋葱',
      '大蒜': '大蒜',
      '生姜': '生姜',
      '葱': '葱',
      '豆角': '豆角',
      '豌豆': '豌豆',
      '毛豆': '毛豆',
      '玉米': '玉米',
      '莲藕': '莲藕',
      '竹笋': '竹笋',
      '蘑菇': '蘑菇',
      '香菇': '香菇',
      '金针菇': '金针菇',
      '木耳': '木耳',

      // 水果类
      '苹果': '苹果',
      '香蕉': '香蕉',
      '橙子': '橙子',
      '橘子': '橘子',
      '柚子': '柚子',
      '柠檬': '柠檬',
      '梨': '梨',
      '桃子': '桃子',
      '葡萄': '葡萄',
      '西瓜': '西瓜',
      '哈密瓜': '哈密瓜',
      '草莓': '草莓',
      '蓝莓': '蓝莓',
      '樱桃': '樱桃',
      '芒果': '芒果',
      '猕猴桃': '猕猴桃',
      '火龙果': '火龙果',
      '榴莲': '榴莲',
      '菠萝': '菠萝',
      '荔枝': '荔枝',
      '龙眼': '龙眼',
      '山竹': '山竹',

      // 单位类
      '斤': '斤',
      '两': '两',
      '公斤': '公斤',
      '千克': '千克',
      '克': '克',
      '个': '个',
      '只': '只',
      '袋': '袋',
      '包': '包',
      '盒': '盒',
      '瓶': '瓶',
      '罐': '罐',
      '箱': '箱',
      '把': '把',
      '根': '根',
      '条': '条',
      '块': '块',
      '片': '片',
      '颗': '颗',
      '粒': '粒',
    };

    // 批量添加默认词汇
    for (final entry in defaultVocabulary.entries) {
      // 只添加不存在的词汇，避免覆盖用户自定义的
      if (!_vocabulary.containsKey(entry.key)) {
        _vocabulary[entry.key] = VocabularyEntry(
          incorrect: entry.key,
          correct: entry.value,
          usageCount: 0,
          createdAt: DateTime.now(),
        );
      }
    }

    // 保存到存储
    await _saveVocabulary();
  }

  /// 应用词汇纠正到文本
  /// 
  /// [text] 需要纠正的文本
  /// [threshold] 模糊匹配阈值（默认 0.8）
  /// 
  /// 返回纠正后的文本
  /// 
  /// 算法：
  /// 1. 将文本分词
  /// 2. 对每个词进行精确匹配或模糊匹配
  /// 3. 如果找到匹配（相似度 >= threshold），替换为正确词汇
  /// 4. 返回纠正后的文本
  String applyCorrections(String text, {double? threshold}) {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    if (text.trim().isEmpty || _vocabulary.isEmpty) {
      return text;
    }

    final matchThreshold = threshold ?? _fuzzyMatchThreshold;
    String correctedText = text;

    // 对每个词汇条目进行匹配和替换
    for (final entry in _vocabulary.values) {
      final incorrect = entry.incorrect;
      final correct = entry.correct;

      // 1. 精确匹配（区分大小写）
      if (correctedText.contains(incorrect)) {
        correctedText = correctedText.replaceAll(incorrect, correct);
        _incrementUsage(incorrect);
        continue;
      }

      // 2. 精确匹配（不区分大小写）
      final lowerText = correctedText.toLowerCase();
      final lowerIncorrect = incorrect.toLowerCase();
      if (lowerText.contains(lowerIncorrect)) {
        // 使用正则表达式进行不区分大小写的替换
        final regex = RegExp(RegExp.escape(incorrect), caseSensitive: false);
        correctedText = correctedText.replaceAll(regex, correct);
        _incrementUsage(incorrect);
        continue;
      }

      // 3. 模糊匹配
      // 将文本分词，对每个词进行相似度计算
      final words = correctedText.split(RegExp(r'\s+'));
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        if (word.isEmpty) continue;

        // 计算相似度
        final similarity = word.similarityTo(incorrect);
        if (similarity >= matchThreshold) {
          // 找到相似词，替换
          words[i] = correct;
          _incrementUsage(incorrect);
        }
      }
      correctedText = words.join(' ');
    }

    return correctedText;
  }

  /// 查找最佳匹配的词汇条目
  /// 
  /// [word] 需要匹配的词
  /// [threshold] 相似度阈值（默认 0.8）
  /// 
  /// 返回最佳匹配的 VocabularyEntry，如果没有找到则返回 null
  VocabularyEntry? findBestMatch(String word, {double? threshold}) {
    if (!_isInitialized) {
      throw StateError(
          'CustomVocabularyService not initialized. Call initialize() first.');
    }

    if (word.trim().isEmpty || _vocabulary.isEmpty) {
      return null;
    }

    final matchThreshold = threshold ?? _fuzzyMatchThreshold;
    VocabularyEntry? bestMatch;
    double bestSimilarity = 0.0;

    // 遍历所有词汇条目，找到相似度最高的
    for (final entry in _vocabulary.values) {
      final similarity = word.similarityTo(entry.incorrect);
      if (similarity >= matchThreshold && similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = entry;
      }
    }

    return bestMatch;
  }
}
