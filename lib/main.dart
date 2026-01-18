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
