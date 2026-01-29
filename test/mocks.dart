import 'package:mockito/annotations.dart';
import 'package:voice_todo/providers/todo_provider.dart';
import 'package:voice_todo/providers/voice_provider.dart';
import 'package:voice_todo/services/sqlite_service.dart';
import 'package:voice_todo/services/custom_vocabulary_service.dart';
import 'package:voice_todo/services/notification_service.dart';

@GenerateMocks([
  TodoProvider,
  VoiceProvider,
  SqliteService,
  CustomVocabularyService,
  NotificationService,
])
void main() {}
