import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_todo/components/todo/todo_edit_dialog.dart';
import 'package:voice_todo/models/todo_item.dart';
import 'package:voice_todo/providers/todo_provider.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: MaterialApp(
        title: 'Test TodoEditDialog',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test TodoEditDialog'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final testTodo = TodoItem(
              id: 'test-1',
              title: '测试待办',
              description: '这是一个测试待办事项',
              category: '工作',
              priority: '中',
              createdAt: DateTime.now(),
            );

            showDialog(
              context: context,
              builder: (context) => TodoEditDialog(todo: testTodo),
            );
          },
          child: const Text('打开编辑对话框'),
        ),
      ),
    );
  }
}
