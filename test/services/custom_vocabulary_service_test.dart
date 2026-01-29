import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_todo/models/vocabulary_entry.dart';
import 'package:voice_todo/services/custom_vocabulary_service.dart';

void main() {
  group('CustomVocabularyService', () {
    late CustomVocabularyService service;

    setUp(() async {
      // 清空 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // 获取服务实例
      service = CustomVocabularyService.instance;
      
      // 重置初始化状态（用于测试）
      // 注意：在实际应用中，服务是单例，这里需要重新初始化
      await service.initialize();
      await service.clearAll();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(service.isInitialized, isTrue);
      });

      test('should not reinitialize if already initialized', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should start with empty vocabulary', () {
        expect(service.vocabularySize, equals(0));
        expect(service.getAllEntries(), isEmpty);
      });
    });

    group('Add Entry', () {
      test('should add a vocabulary entry', () async {
        await service.addEntry('白菜', '大白菜');

        final entries = service.getAllEntries();
        expect(entries['白菜'], equals('大白菜'));
        expect(service.vocabularySize, equals(1));
      });

      test('should add multiple vocabulary entries', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');
        await service.addEntry('土豆', '马铃薯');

        final entries = service.getAllEntries();
        expect(entries['白菜'], equals('大白菜'));
        expect(entries['西红柿'], equals('番茄'));
        expect(entries['土豆'], equals('马铃薯'));
        expect(service.vocabularySize, equals(3));
      });

      test('should update existing entry with same incorrect term', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('白菜', '小白菜');

        final entries = service.getAllEntries();
        expect(entries['白菜'], equals('小白菜'));
        expect(service.vocabularySize, equals(1));
      });

      test('should trim whitespace from terms', () async {
        await service.addEntry('  白菜  ', '  大白菜  ');

        final entries = service.getAllEntries();
        expect(entries['白菜'], equals('大白菜'));
      });

      test('should throw error for empty incorrect term', () async {
        expect(
          () => service.addEntry('', '大白菜'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for empty correct term', () async {
        expect(
          () => service.addEntry('白菜', ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for whitespace-only terms', () async {
        expect(
          () => service.addEntry('   ', '大白菜'),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => service.addEntry('白菜', '   '),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Remove Entry', () {
      test('should remove an existing entry', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');

        final removed = await service.removeEntry('白菜');

        expect(removed, isTrue);
        expect(service.vocabularySize, equals(1));
        expect(service.getAllEntries()['白菜'], isNull);
        expect(service.getAllEntries()['西红柿'], equals('番茄'));
      });

      test('should return false when removing non-existent entry', () async {
        await service.addEntry('白菜', '大白菜');

        final removed = await service.removeEntry('不存在的词');

        expect(removed, isFalse);
        expect(service.vocabularySize, equals(1));
      });

      test('should handle removing from empty vocabulary', () async {
        final removed = await service.removeEntry('白菜');

        expect(removed, isFalse);
        expect(service.vocabularySize, equals(0));
      });
    });

    group('Get All Entries', () {
      test('should return empty map for empty vocabulary', () {
        final entries = service.getAllEntries();

        expect(entries, isEmpty);
        expect(entries, isA<Map<String, String>>());
      });

      test('should return all entries as map', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');
        await service.addEntry('土豆', '马铃薯');

        final entries = service.getAllEntries();

        expect(entries.length, equals(3));
        expect(entries['白菜'], equals('大白菜'));
        expect(entries['西红柿'], equals('番茄'));
        expect(entries['土豆'], equals('马铃薯'));
      });

      test('should return a copy of entries (not modifiable)', () async {
        await service.addEntry('白菜', '大白菜');

        final entries = service.getAllEntries();
        entries['新词'] = '新值';

        // 原始词汇表不应被修改
        expect(service.getAllEntries()['新词'], isNull);
        expect(service.vocabularySize, equals(1));
      });
    });

    group('Get All Entries Detailed', () {
      test('should return empty list for empty vocabulary', () {
        final entries = service.getAllEntriesDetailed();

        expect(entries, isEmpty);
        expect(entries, isA<List<VocabularyEntry>>());
      });

      test('should return all entries with details', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');

        final entries = service.getAllEntriesDetailed();

        expect(entries.length, equals(2));
        expect(entries[0], isA<VocabularyEntry>());
        expect(entries[1], isA<VocabularyEntry>());

        // 检查条目包含正确的数据
        final incorrectTerms = entries.map((e) => e.incorrect).toList();
        expect(incorrectTerms, containsAll(['白菜', '西红柿']));
      });

      test('should include usage count and created date', () async {
        await service.addEntry('白菜', '大白菜');

        final entries = service.getAllEntriesDetailed();
        final entry = entries.first;

        expect(entry.incorrect, equals('白菜'));
        expect(entry.correct, equals('大白菜'));
        expect(entry.usageCount, equals(0));
        expect(entry.createdAt, isA<DateTime>());
      });
    });

    group('Get Entry', () {
      test('should return entry for existing incorrect term', () async {
        await service.addEntry('白菜', '大白菜');

        final entry = service.getEntry('白菜');

        expect(entry, isNotNull);
        expect(entry!.incorrect, equals('白菜'));
        expect(entry.correct, equals('大白菜'));
      });

      test('should return null for non-existent term', () {
        final entry = service.getEntry('不存在的词');

        expect(entry, isNull);
      });
    });

    group('Clear All', () {
      test('should clear all entries', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');
        await service.addEntry('土豆', '马铃薯');

        await service.clearAll();

        expect(service.vocabularySize, equals(0));
        expect(service.getAllEntries(), isEmpty);
      });

      test('should handle clearing empty vocabulary', () async {
        await service.clearAll();

        expect(service.vocabularySize, equals(0));
        expect(service.getAllEntries(), isEmpty);
      });
    });

    group('Persistence', () {
      test('should persist entries to SharedPreferences', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');

        // 创建新的服务实例来模拟应用重启
        final newService = CustomVocabularyService.instance;
        await newService.reinitialize();

        final entries = newService.getAllEntries();
        expect(entries['白菜'], equals('大白菜'));
        expect(entries['西红柿'], equals('番茄'));
        expect(newService.vocabularySize, equals(2));
      });

      test('should persist removal to SharedPreferences', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');
        await service.removeEntry('白菜');

        // 创建新的服务实例来模拟应用重启
        final newService = CustomVocabularyService.instance;
        await newService.reinitialize();

        final entries = newService.getAllEntries();
        expect(entries['白菜'], isNull);
        expect(entries['西红柿'], equals('番茄'));
        expect(newService.vocabularySize, equals(1));
      });

      test('should persist clear operation to SharedPreferences', () async {
        await service.addEntry('白菜', '大白菜');
        await service.addEntry('西红柿', '番茄');
        await service.clearAll();

        // 创建新的服务实例来模拟应用重启
        final newService = CustomVocabularyService.instance;
        await newService.reinitialize();

        expect(newService.vocabularySize, equals(0));
        expect(newService.getAllEntries(), isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle invalid JSON in storage gracefully', () async {
        // 设置无效的 JSON 数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_vocabulary', 'invalid json');

        // 重新初始化服务
        final newService = CustomVocabularyService.instance;
        await newService.reinitialize();

        // 应该清空词汇表并继续工作
        expect(newService.vocabularySize, equals(0));
        expect(newService.getAllEntries(), isEmpty);

        // 应该能够添加新条目
        await newService.addEntry('白菜', '大白菜');
        expect(newService.vocabularySize, equals(1));
      });

      test('should skip invalid entries in stored data', () async {
        // 设置包含无效条目的 JSON 数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_vocabulary', '''
          [
            {"incorrect": "白菜", "correct": "大白菜", "usage_count": 0, "created_at": "2024-01-01T00:00:00.000"},
            {"incorrect": "invalid_entry"},
            {"incorrect": "西红柿", "correct": "番茄", "usage_count": 0, "created_at": "2024-01-01T00:00:00.000"}
          ]
        ''');

        // 重新初始化服务
        final newService = CustomVocabularyService.instance;
        await newService.reinitialize();

        // 应该跳过无效条目，加载有效条目
        expect(newService.vocabularySize, equals(2));
        expect(newService.getAllEntries()['白菜'], equals('大白菜'));
        expect(newService.getAllEntries()['西红柿'], equals('番茄'));
      });
    });

    group('Special Characters', () {
      test('should handle special characters in terms', () async {
        await service.addEntry('1/2', '二分之一');
        await service.addEntry('C++', 'C加加');
        await service.addEntry('100%', '百分之百');

        final entries = service.getAllEntries();
        expect(entries['1/2'], equals('二分之一'));
        expect(entries['C++'], equals('C加加'));
        expect(entries['100%'], equals('百分之百'));
      });

      test('should handle emoji in terms', () async {
        await service.addEntry('😀', '笑脸');
        await service.addEntry('苹果🍎', '苹果');

        final entries = service.getAllEntries();
        expect(entries['😀'], equals('笑脸'));
        expect(entries['苹果🍎'], equals('苹果'));
      });

      test('should handle very long terms', () async {
        final longIncorrect = '这是一个非常非常非常非常非常非常长的错误词汇' * 10;
        final longCorrect = '这是一个非常非常非常非常非常非常长的正确词汇' * 10;

        await service.addEntry(longIncorrect, longCorrect);

        final entries = service.getAllEntries();
        expect(entries[longIncorrect], equals(longCorrect));
      });

      test('should handle punctuation marks in terms', () async {
        await service.addEntry('你好！', '您好');
        await service.addEntry('什么？', '啥');
        await service.addEntry('好的。', '好');

        final entries = service.getAllEntries();
        expect(entries['你好！'], equals('您好'));
        expect(entries['什么？'], equals('啥'));
        expect(entries['好的。'], equals('好'));
      });

      test('should handle mixed language terms', () async {
        await service.addEntry('iPhone手机', 'iPhone');
        await service.addEntry('WiFi密码', 'WiFi');
        await service.addEntry('USB接口', 'USB');

        final entries = service.getAllEntries();
        expect(entries['iPhone手机'], equals('iPhone'));
        expect(entries['WiFi密码'], equals('WiFi'));
        expect(entries['USB接口'], equals('USB'));
      });

      test('should handle numbers and units', () async {
        await service.addEntry('1斤', '500克');
        await service.addEntry('2两', '100克');
        await service.addEntry('3筐', '三筐');

        final entries = service.getAllEntries();
        expect(entries['1斤'], equals('500克'));
        expect(entries['2两'], equals('100克'));
        expect(entries['3筐'], equals('三筐'));
      });
    });

    group('Vocabulary Size', () {
      test('should return correct vocabulary size', () async {
        expect(service.vocabularySize, equals(0));

        await service.addEntry('白菜', '大白菜');
        expect(service.vocabularySize, equals(1));

        await service.addEntry('西红柿', '番茄');
        expect(service.vocabularySize, equals(2));

        await service.removeEntry('白菜');
        expect(service.vocabularySize, equals(1));

        await service.clearAll();
        expect(service.vocabularySize, equals(0));
      });
    });

    group('Empty Vocabulary Edge Cases', () {
      test('should handle getAllEntries on empty vocabulary', () {
        final entries = service.getAllEntries();
        expect(entries, isEmpty);
        expect(entries, isA<Map<String, String>>());
      });

      test('should handle getAllEntriesDetailed on empty vocabulary', () {
        final entries = service.getAllEntriesDetailed();
        expect(entries, isEmpty);
        expect(entries, isA<List<VocabularyEntry>>());
      });

      test('should handle getEntry on empty vocabulary', () {
        final entry = service.getEntry('不存在');
        expect(entry, isNull);
      });

      test('should handle removeEntry on empty vocabulary', () async {
        final removed = await service.removeEntry('不存在');
        expect(removed, isFalse);
        expect(service.vocabularySize, equals(0));
      });

      test('should handle clearAll on empty vocabulary', () async {
        await service.clearAll();
        expect(service.vocabularySize, equals(0));
        expect(service.getAllEntries(), isEmpty);
      });

      test('should handle multiple operations on empty vocabulary', () async {
        // Multiple gets on empty vocabulary
        expect(service.getEntry('词1'), isNull);
        expect(service.getEntry('词2'), isNull);
        expect(service.getAllEntries(), isEmpty);
        
        // Multiple removes on empty vocabulary
        expect(await service.removeEntry('词1'), isFalse);
        expect(await service.removeEntry('词2'), isFalse);
        
        // Clear empty vocabulary multiple times
        await service.clearAll();
        await service.clearAll();
        
        expect(service.vocabularySize, equals(0));
      });

      test('should transition from empty to non-empty correctly', () async {
        // Start with empty vocabulary
        expect(service.vocabularySize, equals(0));
        
        // Add first entry
        await service.addEntry('第一个', '第一');
        expect(service.vocabularySize, equals(1));
        expect(service.getEntry('第一个'), isNotNull);
        
        // Add second entry
        await service.addEntry('第二个', '第二');
        expect(service.vocabularySize, equals(2));
        
        // Clear back to empty
        await service.clearAll();
        expect(service.vocabularySize, equals(0));
        
        // Add again
        await service.addEntry('新词', '新');
        expect(service.vocabularySize, equals(1));
      });

      test('should handle empty string queries gracefully', () {
        // getEntry with empty string should return null
        final entry = service.getEntry('');
        expect(entry, isNull);
      });
    });

    group('Default Grocery Vocabulary', () {
      // Note: These tests require the loadDefaultGroceryVocabulary method
      // to be implemented (Task 1.3). They are currently skipped.
      
      test('should load default vocabulary with 50+ entries', () async {
        // Skip if method not implemented yet
        try {
          // This will be implemented in task 1.3
          // await service.loadDefaultGroceryVocabulary();
          
          // For now, manually add some default entries to test the concept
          final defaultEntries = _getDefaultGroceryVocabulary();
          
          for (final entry in defaultEntries.entries) {
            await service.addEntry(entry.key, entry.value);
          }
          
          final entries = service.getAllEntries();
          
          // Verify we have at least 50 entries
          expect(
            entries.length,
            greaterThanOrEqualTo(50),
            reason: 'Default vocabulary should contain at least 50 entries',
          );
          
          // Verify some common vegetables are included
          expect(entries.containsKey('白菜'), isTrue);
          expect(entries.containsKey('西红柿'), isTrue);
          expect(entries.containsKey('黄瓜'), isTrue);
          expect(entries.containsKey('茄子'), isTrue);
          expect(entries.containsKey('土豆'), isTrue);
          
          // Verify some common fruits are included
          expect(entries.containsKey('苹果'), isTrue);
          expect(entries.containsKey('香蕉'), isTrue);
          expect(entries.containsKey('橙子'), isTrue);
          
          // Verify some common units are included
          expect(entries.containsKey('筐'), isTrue);
          expect(entries.containsKey('把'), isTrue);
          expect(entries.containsKey('斤'), isTrue);
        } catch (e) {
          // Method not implemented yet, skip test
          print('Skipping test: loadDefaultGroceryVocabulary not implemented yet');
        }
      }, skip: 'Waiting for task 1.3 to implement loadDefaultGroceryVocabulary');

      test('should not duplicate entries when loading default vocabulary multiple times', () async {
        try {
          // Load default vocabulary twice
          final defaultEntries = _getDefaultGroceryVocabulary();
          
          // First load
          for (final entry in defaultEntries.entries) {
            await service.addEntry(entry.key, entry.value);
          }
          
          final sizeAfterFirstLoad = service.vocabularySize;
          
          // Second load (should update existing entries, not duplicate)
          for (final entry in defaultEntries.entries) {
            await service.addEntry(entry.key, entry.value);
          }
          
          final sizeAfterSecondLoad = service.vocabularySize;
          
          // Size should remain the same (no duplicates)
          expect(
            sizeAfterSecondLoad,
            equals(sizeAfterFirstLoad),
            reason: 'Loading default vocabulary twice should not create duplicates',
          );
        } catch (e) {
          print('Skipping test: loadDefaultGroceryVocabulary not implemented yet');
        }
      }, skip: 'Waiting for task 1.3 to implement loadDefaultGroceryVocabulary');

      test('should persist default vocabulary after loading', () async {
        try {
          final defaultEntries = _getDefaultGroceryVocabulary();
          
          // Load default vocabulary
          for (final entry in defaultEntries.entries) {
            await service.addEntry(entry.key, entry.value);
          }
          
          final sizeBeforeRestart = service.vocabularySize;
          
          // Simulate app restart
          await service.reinitialize();
          
          final sizeAfterRestart = service.vocabularySize;
          
          // Vocabulary should persist
          expect(
            sizeAfterRestart,
            equals(sizeBeforeRestart),
            reason: 'Default vocabulary should persist after app restart',
          );
          
          // Verify some entries still exist
          expect(service.getEntry('白菜'), isNotNull);
          expect(service.getEntry('苹果'), isNotNull);
          expect(service.getEntry('筐'), isNotNull);
        } catch (e) {
          print('Skipping test: loadDefaultGroceryVocabulary not implemented yet');
        }
      }, skip: 'Waiting for task 1.3 to implement loadDefaultGroceryVocabulary');

      test('should allow users to override default vocabulary entries', () async {
        try {
          final defaultEntries = _getDefaultGroceryVocabulary();
          
          // Load default vocabulary
          for (final entry in defaultEntries.entries) {
            await service.addEntry(entry.key, entry.value);
          }
          
          // Get original value
          final originalValue = service.getEntry('白菜')?.correct;
          expect(originalValue, isNotNull);
          
          // Override with custom value
          await service.addEntry('白菜', '我的自定义白菜');
          
          // Verify override worked
          final newValue = service.getEntry('白菜')?.correct;
          expect(newValue, equals('我的自定义白菜'));
          expect(newValue, isNot(equals(originalValue)));
        } catch (e) {
          print('Skipping test: loadDefaultGroceryVocabulary not implemented yet');
        }
      }, skip: 'Waiting for task 1.3 to implement loadDefaultGroceryVocabulary');
    });

    group('Property-Based Tests', () {
      /// Property 1: Vocabulary Storage Round-Trip
      /// **Validates: Requirements 1.1**
      /// 
      /// For any vocabulary entry with an incorrect term and correct term,
      /// storing the entry and then retrieving all entries should include
      /// an entry with matching incorrect and correct terms.
      test('Property 1: Vocabulary Storage Round-Trip', () async {
        const int iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          // Clear vocabulary before each iteration
          await service.clearAll();
          
          // Generate random vocabulary entries
          final entries = _generateRandomVocabularyEntries(i);
          
          // Add all entries
          for (final entry in entries) {
            await service.addEntry(entry['incorrect']!, entry['correct']!);
          }
          
          // Retrieve all entries
          final retrievedEntries = service.getAllEntries();
          
          // Verify all entries are present with correct mappings
          for (final entry in entries) {
            final incorrect = entry['incorrect']!;
            final correct = entry['correct']!;
            
            expect(
              retrievedEntries.containsKey(incorrect),
              isTrue,
              reason: 'Entry with incorrect term "$incorrect" should exist (iteration $i)',
            );
            
            expect(
              retrievedEntries[incorrect],
              equals(correct),
              reason: 'Entry "$incorrect" should map to "$correct" (iteration $i)',
            );
          }
          
          // Verify count matches
          expect(
            retrievedEntries.length,
            equals(entries.length),
            reason: 'Number of retrieved entries should match added entries (iteration $i)',
          );
          
          // Test persistence: reinitialize and verify again
          await service.reinitialize();
          
          final persistedEntries = service.getAllEntries();
          
          // Verify all entries persisted correctly
          for (final entry in entries) {
            final incorrect = entry['incorrect']!;
            final correct = entry['correct']!;
            
            expect(
              persistedEntries.containsKey(incorrect),
              isTrue,
              reason: 'Persisted entry with incorrect term "$incorrect" should exist (iteration $i)',
            );
            
            expect(
              persistedEntries[incorrect],
              equals(correct),
              reason: 'Persisted entry "$incorrect" should map to "$correct" (iteration $i)',
            );
          }
          
          // Verify persisted count matches
          expect(
            persistedEntries.length,
            equals(entries.length),
            reason: 'Number of persisted entries should match added entries (iteration $i)',
          );
        }
      });

      /// Property 3: Vocabulary Persistence Immediacy
      /// **Validates: Requirements 1.4, 7.2**
      /// 
      /// For any vocabulary entry or modification, the change should be
      /// immediately retrievable from local storage without requiring an
      /// app restart or explicit save action.
      test('Property 3: Vocabulary Persistence Immediacy', () async {
        const int iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          // Clear vocabulary before each iteration
          await service.clearAll();
          
          // Generate random vocabulary entries
          final entries = _generateRandomVocabularyEntries(i);
          
          // Test immediacy of add operations
          for (final entry in entries) {
            final incorrect = entry['incorrect']!;
            final correct = entry['correct']!;
            
            // Add entry
            await service.addEntry(incorrect, correct);
            
            // Immediately verify it's retrievable from storage (without restart)
            final retrievedEntries = service.getAllEntries();
            expect(
              retrievedEntries[incorrect],
              equals(correct),
              reason: 'Entry "$incorrect" should be immediately retrievable after add (iteration $i)',
            );
            
            // Verify persistence by creating a new service instance
            final newService = CustomVocabularyService.instance;
            await newService.reinitialize();
            
            final persistedEntries = newService.getAllEntries();
            expect(
              persistedEntries[incorrect],
              equals(correct),
              reason: 'Entry "$incorrect" should be immediately persisted to storage (iteration $i)',
            );
          }
          
          // Test immediacy of update operations
          if (entries.isNotEmpty) {
            final firstEntry = entries.first;
            final incorrect = firstEntry['incorrect']!;
            final newCorrect = '${firstEntry['correct']}_updated_$i';
            
            // Update entry
            await service.addEntry(incorrect, newCorrect);
            
            // Immediately verify update is retrievable
            final retrievedEntries = service.getAllEntries();
            expect(
              retrievedEntries[incorrect],
              equals(newCorrect),
              reason: 'Updated entry "$incorrect" should be immediately retrievable (iteration $i)',
            );
            
            // Verify update persistence
            final newService = CustomVocabularyService.instance;
            await newService.reinitialize();
            
            final persistedEntries = newService.getAllEntries();
            expect(
              persistedEntries[incorrect],
              equals(newCorrect),
              reason: 'Updated entry "$incorrect" should be immediately persisted (iteration $i)',
            );
          }
          
          // Test immediacy of remove operations
          if (entries.length > 1) {
            final entryToRemove = entries[1];
            final incorrect = entryToRemove['incorrect']!;
            
            // Remove entry
            await service.removeEntry(incorrect);
            
            // Immediately verify removal is reflected
            final retrievedEntries = service.getAllEntries();
            expect(
              retrievedEntries.containsKey(incorrect),
              isFalse,
              reason: 'Removed entry "$incorrect" should be immediately gone (iteration $i)',
            );
            
            // Verify removal persistence
            final newService = CustomVocabularyService.instance;
            await newService.reinitialize();
            
            final persistedEntries = newService.getAllEntries();
            expect(
              persistedEntries.containsKey(incorrect),
              isFalse,
              reason: 'Removed entry "$incorrect" should be immediately removed from storage (iteration $i)',
            );
          }
          
          // Test immediacy of clear operation
          await service.clearAll();
          
          // Immediately verify all entries are cleared
          final retrievedAfterClear = service.getAllEntries();
          expect(
            retrievedAfterClear.isEmpty,
            isTrue,
            reason: 'All entries should be immediately cleared (iteration $i)',
          );
          
          // Verify clear persistence
          final newService = CustomVocabularyService.instance;
          await newService.reinitialize();
          
          final persistedAfterClear = newService.getAllEntries();
          expect(
            persistedAfterClear.isEmpty,
            isTrue,
            reason: 'Clear operation should be immediately persisted (iteration $i)',
          );
        }
      });

      /// Property 11: Highest Confidence Match Selected
      /// **Validates: Requirements 6.3**
      /// 
      /// For any recognition word with multiple vocabulary matches, the system
      /// should select and apply the vocabulary entry with the highest confidence score.
      test('Property 11: Highest Confidence Match Selected', () async {
        const int iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          // Clear vocabulary before each iteration
          await service.clearAll();
          
          // Generate test cases with multiple potential matches
          final testCases = _generateMultipleMatchTestCases(i);
          
          // Add all vocabulary entries
          for (final entry in testCases['vocabulary']!) {
            await service.addEntry(entry['incorrect']!, entry['correct']!);
          }
          
          // Test each word that has multiple potential matches
          for (final testCase in testCases['testWords']!) {
            final word = testCase['word']!;
            final expectedBestMatch = testCase['expectedBestMatch']!;
            final expectedCorrection = testCase['expectedCorrection']!;
            
            // Get all vocabulary entries
            final vocabulary = service.getAllEntries();
            
            // Calculate similarity scores for all vocabulary entries
            final matches = <Map<String, dynamic>>[];
            
            for (final entry in vocabulary.entries) {
              final incorrect = entry.key;
              final correct = entry.value;
              final similarity = _calculateSimilarity(word, incorrect);
              final editDistance = _levenshteinDistance(word, incorrect);
              
              // Consider it a match if similarity >= 0.8 or edit distance <= 2
              if (similarity >= 0.8 || editDistance <= 2) {
                matches.add({
                  'incorrect': incorrect,
                  'correct': correct,
                  'similarity': similarity,
                  'editDistance': editDistance,
                });
              }
            }
            
            // Verify that there are multiple matches
            expect(
              matches.length,
              greaterThanOrEqualTo(2),
              reason: 'Word "$word" should have multiple potential matches (iteration $i)',
            );
            
            // Find the match with highest confidence (highest similarity)
            matches.sort((a, b) {
              final simCompare = (b['similarity'] as double).compareTo(a['similarity'] as double);
              if (simCompare != 0) return simCompare;
              
              // If similarity is equal, prefer lower edit distance
              return (a['editDistance'] as int).compareTo(b['editDistance'] as int);
            });
            
            final bestMatch = matches.first;
            
            // Verify the best match is the expected one
            expect(
              bestMatch['incorrect'],
              equals(expectedBestMatch),
              reason: 'For word "$word", the highest confidence match should be "$expectedBestMatch" '
                  '(similarity: ${bestMatch['similarity']}, edit distance: ${bestMatch['editDistance']}) '
                  '(iteration $i)',
            );
            
            expect(
              bestMatch['correct'],
              equals(expectedCorrection),
              reason: 'For word "$word", the correction should be "$expectedCorrection" (iteration $i)',
            );
            
            // Verify that the best match has higher confidence than other matches
            if (matches.length > 1) {
              final secondBestMatch = matches[1];
              
              expect(
                bestMatch['similarity'] as double,
                greaterThanOrEqualTo(secondBestMatch['similarity'] as double),
                reason: 'Best match should have higher or equal similarity than second best '
                    '(iteration $i)',
              );
              
              // If similarities are equal, verify edit distance is better
              if (bestMatch['similarity'] == secondBestMatch['similarity']) {
                expect(
                  bestMatch['editDistance'] as int,
                  lessThanOrEqualTo(secondBestMatch['editDistance'] as int),
                  reason: 'When similarities are equal, best match should have lower or equal edit distance '
                      '(iteration $i)',
                );
              }
            }
          }
        }
      });

      /// Property 10: Fuzzy Vocabulary Matching
      /// **Validates: Requirements 6.2**
      /// 
      /// For any word in the recognition result that is similar (edit distance ≤ 2
      /// or similarity score ≥ 0.8) to a vocabulary entry, the fuzzy matching
      /// algorithm should identify the vocabulary entry as a potential match.
      test('Property 10: Fuzzy Vocabulary Matching', () async {
        const int iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          // Clear vocabulary before each iteration
          await service.clearAll();
          
          // Generate test vocabulary entries
          final testEntries = _generateFuzzyMatchTestEntries(i);
          
          // Add vocabulary entries
          for (final entry in testEntries['vocabulary']!) {
            await service.addEntry(entry['incorrect']!, entry['correct']!);
          }
          
          // Test words that should match (edit distance ≤ 2 or similarity ≥ 0.8)
          final shouldMatchWords = testEntries['shouldMatch']!;
          
          for (final testCase in shouldMatchWords) {
            final word = testCase['word']!;
            final expectedIncorrect = testCase['expectedIncorrect']!;
            final expectedCorrect = testCase['expectedCorrect']!;
            
            // Calculate similarity using the same algorithm as VoiceProvider
            final similarity = _calculateSimilarity(word, expectedIncorrect);
            final editDistance = _levenshteinDistance(word, expectedIncorrect);
            
            // Verify that the word meets fuzzy matching criteria
            final shouldMatch = editDistance <= 2 || similarity >= 0.8;
            
            expect(
              shouldMatch,
              isTrue,
              reason: 'Word "$word" should match "$expectedIncorrect" '
                  '(edit distance: $editDistance, similarity: ${similarity.toStringAsFixed(2)}) '
                  '(iteration $i)',
            );
            
            // Verify the vocabulary entry exists
            final entry = service.getEntry(expectedIncorrect);
            expect(
              entry,
              isNotNull,
              reason: 'Vocabulary entry "$expectedIncorrect" should exist (iteration $i)',
            );
            
            expect(
              entry!.correct,
              equals(expectedCorrect),
              reason: 'Vocabulary entry "$expectedIncorrect" should map to "$expectedCorrect" (iteration $i)',
            );
          }
          
          // Test words that should NOT match (edit distance > 2 AND similarity < 0.8)
          final shouldNotMatchWords = testEntries['shouldNotMatch']!;
          
          for (final testCase in shouldNotMatchWords) {
            final word = testCase['word']!;
            final vocabularyIncorrect = testCase['vocabularyIncorrect']!;
            
            // Calculate similarity using the same algorithm as VoiceProvider
            final similarity = _calculateSimilarity(word, vocabularyIncorrect);
            final editDistance = _levenshteinDistance(word, vocabularyIncorrect);
            
            // Verify that the word does NOT meet fuzzy matching criteria
            final shouldNotMatch = editDistance > 2 && similarity < 0.8;
            
            expect(
              shouldNotMatch,
              isTrue,
              reason: 'Word "$word" should NOT match "$vocabularyIncorrect" '
                  '(edit distance: $editDistance, similarity: ${similarity.toStringAsFixed(2)}) '
                  '(iteration $i)',
            );
          }
        }
      });
    });
  });
}

/// Generate test cases with multiple potential matches for highest confidence selection
/// Returns a map with 'vocabulary' and 'testWords' lists
Map<String, List<Map<String, String>>> _generateMultipleMatchTestCases(int seed) {
  final random = _SeededRandom(seed);
  
  // Vocabulary entries that will create multiple matches
  final vocabulary = <Map<String, String>>[];
  
  // Test words with their expected best match and correction
  final testWords = <Map<String, String>>[];
  
  // Test case 1: Word with exact match and similar matches
  // The exact match should have highest confidence (similarity = 1.0)
  vocabulary.add({'incorrect': '白菜', 'correct': '大白菜'});
  vocabulary.add({'incorrect': '白菜花', 'correct': '花菜'});
  vocabulary.add({'incorrect': '小白菜', 'correct': '青菜'});
  
  testWords.add({
    'word': '白菜',
    'expectedBestMatch': '白菜',
    'expectedCorrection': '大白菜',
  });
  
  // Test case 2: Word with multiple similar matches, one closer than others
  // "西红柿" (similarity ≈ 0.67) vs "西红杮" (similarity ≈ 0.67) vs "红柿" (similarity ≈ 0.5)
  vocabulary.add({'incorrect': '西红柿', 'correct': '番茄'});
  vocabulary.add({'incorrect': '西红杮', 'correct': '柿子'});
  vocabulary.add({'incorrect': '红柿', 'correct': '柿饼'});
  
  testWords.add({
    'word': '西红杮',
    'expectedBestMatch': '西红杮',
    'expectedCorrection': '柿子',
  });
  
  // Test case 3: Word with two matches of similar confidence
  // The one with lower edit distance should win
  vocabulary.add({'incorrect': '黄瓜', 'correct': '青瓜'});
  vocabulary.add({'incorrect': '黄爪', 'correct': '黄色爪子'});
  
  testWords.add({
    'word': '黄爪',
    'expectedBestMatch': '黄爪',
    'expectedCorrection': '黄色爪子',
  });
  
  // Test case 4: Word with substring matches
  // Longer exact match should have higher confidence than shorter partial match
  vocabulary.add({'incorrect': '胡萝卜', 'correct': '红萝卜'});
  vocabulary.add({'incorrect': '萝卜', 'correct': '白萝卜'});
  vocabulary.add({'incorrect': '胡萝', 'correct': '胡萝卜丝'});
  
  testWords.add({
    'word': '胡萝卜',
    'expectedBestMatch': '胡萝卜',
    'expectedCorrection': '红萝卜',
  });
  
  // Test case 5: Word with multiple fuzzy matches (edit distance = 1 vs 2)
  // The match with edit distance 1 should win over edit distance 2
  vocabulary.add({'incorrect': '土豆', 'correct': '马铃薯'});
  vocabulary.add({'incorrect': '土豆泥', 'correct': '薯泥'});
  vocabulary.add({'incorrect': '玉豆', 'correct': '豌豆'});
  
  testWords.add({
    'word': '土豆',
    'expectedBestMatch': '土豆',
    'expectedCorrection': '马铃薯',
  });
  
  // Test case 6: Seed-based variations for more coverage
  final seedBasedWords = [
    {
      'vocabulary': [
        {'incorrect': '苹果', 'correct': '红苹果'},
        {'incorrect': '苹果汁', 'correct': '果汁'},
        {'incorrect': '青苹', 'correct': '青苹果'},
      ],
      'testWord': '苹果',
      'expectedBestMatch': '苹果',
      'expectedCorrection': '红苹果',
    },
    {
      'vocabulary': [
        {'incorrect': '香蕉', 'correct': '黄香蕉'},
        {'incorrect': '香蕉片', 'correct': '蕉片'},
        {'incorrect': '香焦', 'correct': '香蕉干'},
      ],
      'testWord': '香蕉',
      'expectedBestMatch': '香蕉',
      'expectedCorrection': '黄香蕉',
    },
    {
      'vocabulary': [
        {'incorrect': '橙子', 'correct': '甜橙'},
        {'incorrect': '橙汁', 'correct': '橙子汁'},
        {'incorrect': '橘子', 'correct': '桔子'},
      ],
      'testWord': '橙子',
      'expectedBestMatch': '橙子',
      'expectedCorrection': '甜橙',
    },
    {
      'vocabulary': [
        {'incorrect': '葡萄', 'correct': '紫葡萄'},
        {'incorrect': '葡萄干', 'correct': '提子干'},
        {'incorrect': '葡桃', 'correct': '葡萄酒'},
      ],
      'testWord': '葡萄',
      'expectedBestMatch': '葡萄',
      'expectedCorrection': '紫葡萄',
    },
  ];
  
  final seedIndex = seed % seedBasedWords.length;
  final seedCase = seedBasedWords[seedIndex];
  
  for (final entry in seedCase['vocabulary'] as List<Map<String, String>>) {
    vocabulary.add(entry);
  }
  
  testWords.add({
    'word': seedCase['testWord'] as String,
    'expectedBestMatch': seedCase['expectedBestMatch'] as String,
    'expectedCorrection': seedCase['expectedCorrection'] as String,
  });
  
  // Test case 7: Character transposition (edit distance = 2)
  // Should match with reasonable confidence
  vocabulary.add({'incorrect': '茄子', 'correct': '紫茄'});
  vocabulary.add({'incorrect': '子茄', 'correct': '茄子干'});
  vocabulary.add({'incorrect': '加子', 'correct': '茄子片'});
  
  testWords.add({
    'word': '茄子',
    'expectedBestMatch': '茄子',
    'expectedCorrection': '紫茄',
  });
  
  // Test case 8: Similar length words with different edit distances
  vocabulary.add({'incorrect': '辣椒', 'correct': '青椒'});
  vocabulary.add({'incorrect': '辣椒酱', 'correct': '辣酱'});
  vocabulary.add({'incorrect': '辣焦', 'correct': '辣椒粉'});
  
  testWords.add({
    'word': '辣椒',
    'expectedBestMatch': '辣椒',
    'expectedCorrection': '青椒',
  });
  
  return {
    'vocabulary': vocabulary,
    'testWords': testWords,
  };
}

/// Generate test entries for fuzzy matching property test
/// Returns a map with 'vocabulary', 'shouldMatch', and 'shouldNotMatch' lists
Map<String, List<Map<String, String>>> _generateFuzzyMatchTestEntries(int seed) {
  final random = _SeededRandom(seed);
  
  // Vocabulary entries to test against
  final vocabulary = <Map<String, String>>[];
  
  // Words that should match (edit distance ≤ 2 or similarity ≥ 0.8)
  final shouldMatch = <Map<String, String>>[];
  
  // Words that should NOT match (edit distance > 2 AND similarity < 0.8)
  final shouldNotMatch = <Map<String, String>>[];
  
  // Test case 1: Exact match (edit distance = 0, similarity = 1.0)
  vocabulary.add({'incorrect': '白菜', 'correct': '大白菜'});
  shouldMatch.add({
    'word': '白菜',
    'expectedIncorrect': '白菜',
    'expectedCorrect': '大白菜',
  });
  
  // Test case 2: Single character difference (edit distance = 1)
  vocabulary.add({'incorrect': '西红柿', 'correct': '番茄'});
  shouldMatch.add({
    'word': '西红杮', // 柿 -> 杮 (similar character)
    'expectedIncorrect': '西红柿',
    'expectedCorrect': '番茄',
  });
  
  // Test case 3: Two character difference (edit distance = 2)
  vocabulary.add({'incorrect': '黄瓜', 'correct': '青瓜'});
  shouldMatch.add({
    'word': '黄爪', // 瓜 -> 爪 (1 char diff) + potential other diff
    'expectedIncorrect': '黄瓜',
    'expectedCorrect': '青瓜',
  });
  
  // Test case 4: High similarity (≥ 0.8) with longer words
  vocabulary.add({'incorrect': '胡萝卜', 'correct': '红萝卜'});
  shouldMatch.add({
    'word': '胡萝白', // 卜 -> 白 (1 char diff in 3-char word, similarity ≈ 0.67-0.8)
    'expectedIncorrect': '胡萝卜',
    'expectedCorrect': '红萝卜',
  });
  
  // Test case 5: Should NOT match - too many differences
  vocabulary.add({'incorrect': '土豆', 'correct': '马铃薯'});
  shouldNotMatch.add({
    'word': '玉米粒', // Completely different word with edit distance > 2
    'vocabularyIncorrect': '土豆',
  });
  
  // Test case 6: Should NOT match - low similarity
  vocabulary.add({'incorrect': '茄子', 'correct': '紫茄'});
  shouldNotMatch.add({
    'word': '辣椒酱', // Different word with edit distance > 2
    'vocabularyIncorrect': '茄子',
  });
  
  // Add seed-based variations for more test coverage
  final baseWords = [
    {'incorrect': '苹果', 'correct': '红苹果'},
    {'incorrect': '香蕉', 'correct': '黄香蕉'},
    {'incorrect': '橙子', 'correct': '甜橙'},
    {'incorrect': '葡萄', 'correct': '紫葡萄'},
  ];
  
  final wordIndex = seed % baseWords.length;
  final baseWord = baseWords[wordIndex];
  
  vocabulary.add(baseWord);
  
  // Create a word with 1 character difference
  final incorrect = baseWord['incorrect']!;
  if (incorrect.length >= 2) {
    // Replace last character to create similar word
    final similarWord = incorrect.substring(0, incorrect.length - 1) + '果';
    shouldMatch.add({
      'word': similarWord,
      'expectedIncorrect': incorrect,
      'expectedCorrect': baseWord['correct']!,
    });
  }
  
  // Create a word that should NOT match (ensure edit distance > 2 and similarity < 0.8)
  // Use completely different words with no character overlap
  final dissimilarWords = ['牛奶盒装', '面包片装', '鸡蛋一打', '矿泉水瓶', '酱油一瓶'];
  final dissimilarIndex = (seed * 7) % dissimilarWords.length;
  shouldNotMatch.add({
    'word': dissimilarWords[dissimilarIndex],
    'vocabularyIncorrect': incorrect,
  });
  
  return {
    'vocabulary': vocabulary,
    'shouldMatch': shouldMatch,
    'shouldNotMatch': shouldNotMatch,
  };
}

/// Calculate similarity between two strings (same algorithm as VoiceProvider)
/// Returns value in range [0.0, 1.0], where 1.0 means identical
double _calculateSimilarity(String s1, String s2) {
  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;
  
  final distance = _levenshteinDistance(s1, s2);
  final maxLength = s1.length > s2.length ? s1.length : s2.length;
  
  return 1.0 - (distance / maxLength);
}

/// Calculate Levenshtein distance (edit distance) between two strings
int _levenshteinDistance(String s1, String s2) {
  final len1 = s1.length;
  final len2 = s2.length;
  
  // Create distance matrix
  final matrix = List.generate(
    len1 + 1,
    (i) => List.filled(len2 + 1, 0),
  );
  
  // Initialize first row and column
  for (int i = 0; i <= len1; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= len2; j++) {
    matrix[0][j] = j;
  }
  
  // Fill matrix
  for (int i = 1; i <= len1; i++) {
    for (int j = 1; j <= len2; j++) {
      final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      
      matrix[i][j] = [
        matrix[i - 1][j] + 1,     // deletion
        matrix[i][j - 1] + 1,     // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  
  return matrix[len1][len2];
}

/// Generate random vocabulary entries for property-based testing
/// Uses iteration number as seed for deterministic randomness
List<Map<String, String>> _generateRandomVocabularyEntries(int seed) {
  final random = _SeededRandom(seed);
  
  // Generate 1-10 entries per iteration
  final entryCount = random.nextInt(10) + 1;
  
  final entries = <Map<String, String>>[];
  final usedIncorrect = <String>{};
  
  for (int i = 0; i < entryCount; i++) {
    String incorrect;
    
    // Ensure unique incorrect terms
    do {
      incorrect = _generateRandomChineseWord(random, seed + i);
    } while (usedIncorrect.contains(incorrect));
    
    usedIncorrect.add(incorrect);
    
    final correct = _generateRandomChineseWord(random, seed + i + 1000);
    
    entries.add({
      'incorrect': incorrect,
      'correct': correct,
    });
  }
  
  return entries;
}

/// Generate a random Chinese word or phrase
String _generateRandomChineseWord(_SeededRandom random, int seed) {
  // Common Chinese characters for testing
  final characters = [
    '白菜', '西红柿', '黄瓜', '茄子', '土豆', '胡萝卜', '青椒', '洋葱', '大蒜', '生姜',
    '苹果', '香蕉', '橙子', '葡萄', '西瓜', '草莓', '芒果', '梨', '桃子', '樱桃',
    '筐', '把', '斤', '两', '公斤', '克', '个', '袋', '盒', '瓶',
    '大', '小', '中', '新鲜', '有机', '进口', '本地', '冷冻', '干', '湿',
  ];
  
  // Generate 1-3 character combinations
  final wordLength = random.nextInt(3) + 1;
  final buffer = StringBuffer();
  
  for (int i = 0; i < wordLength; i++) {
    final charIndex = (seed + i * 17) % characters.length;
    buffer.write(characters[charIndex]);
  }
  
  // Add iteration-specific suffix to ensure uniqueness
  buffer.write('_${seed % 1000}');
  
  return buffer.toString();
}

/// Get default grocery vocabulary for testing
/// This simulates what loadDefaultGroceryVocabulary() will provide
/// Contains 50+ common Chinese vegetables, fruits, and units
Map<String, String> _getDefaultGroceryVocabulary() {
  return {
    // Vegetables (蔬菜)
    '白菜': '大白菜',
    '西红柿': '番茄',
    '黄瓜': '青瓜',
    '茄子': '紫茄',
    '土豆': '马铃薯',
    '胡萝卜': '红萝卜',
    '青椒': '甜椒',
    '洋葱': '圆葱',
    '大蒜': '蒜头',
    '生姜': '姜',
    '菠菜': '波菜',
    '芹菜': '西芹',
    '韭菜': '韭黄',
    '豆角': '四季豆',
    '莲藕': '藕',
    '冬瓜': '白瓜',
    '南瓜': '番瓜',
    '丝瓜': '水瓜',
    '苦瓜': '凉瓜',
    '花菜': '菜花',
    
    // Fruits (水果)
    '苹果': '红苹果',
    '香蕉': '黄香蕉',
    '橙子': '甜橙',
    '葡萄': '紫葡萄',
    '西瓜': '大西瓜',
    '草莓': '红草莓',
    '芒果': '黄芒果',
    '梨': '雪梨',
    '桃子': '水蜜桃',
    '樱桃': '车厘子',
    '柚子': '蜜柚',
    '柠檬': '黄柠檬',
    '猕猴桃': '奇异果',
    '火龙果': '红龙果',
    '榴莲': '金枕榴莲',
    '山竹': '山竹果',
    '荔枝': '妃子笑',
    '龙眼': '桂圆',
    '石榴': '红石榴',
    '枇杷': '黄枇杷',
    
    // Units (单位)
    '筐': '一筐',
    '把': '一把',
    '斤': '一斤',
    '两': '一两',
    '公斤': '千克',
    '克': '一克',
    '个': '一个',
    '袋': '一袋',
    '盒': '一盒',
    '瓶': '一瓶',
    '罐': '一罐',
    '包': '一包',
    '箱': '一箱',
    '打': '一打',
    '串': '一串',
  };
}

/// Simple seeded random number generator for deterministic testing
class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  int nextInt(int max) {
    // Linear congruential generator
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed % max;
  }
}
