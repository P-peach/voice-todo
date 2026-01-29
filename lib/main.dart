import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/voice_provider.dart';
import 'services/sqlite_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // 确保绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 捕获 Flutter Web 键盘相关错误
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // 忽略 Web 平台的 viewInsets 负值错误
      if (details.exception.toString().contains('ViewInsets cannot be negative')) {
        debugPrint('Ignored Web keyboard error: ${details.exception}');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  // 初始化数据库服务
  await SqliteService.initialize();

  runApp(const VoiceTodoApp());
}

class VoiceTodoApp extends StatelessWidget {
  const VoiceTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'VoiceTodo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            home: const App(),
          );
        },
      ),
    );
  }
}
