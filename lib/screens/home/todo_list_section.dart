import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/todo_provider.dart';
import '../../theme/app_spacing.dart';
import '../../components/todo/todo_card.dart';
import '../../models/todo_item.dart';

/// 待办事项列表组件
class TodoListSection extends StatefulWidget {
  final bool showOnlyIncomplete;

  const TodoListSection({
    super.key,
    this.showOnlyIncomplete = false,
  });

  @override
  State<TodoListSection> createState() => _TodoListSectionState();
}

class _TodoListSectionState extends State<TodoListSection> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<TodoItem> _displayedTodos = [];
  List<String> _previousTodoIds = [];

  @override
  void initState() {
    super.initState();
    // 初始化时获取待办列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeList();
    });
  }

  void _initializeList() {
    final provider = context.read<TodoProvider>();
    final incompleteTodos = provider.incompleteTodos;
    final completedTodos = provider.completedTodos;

    _displayedTodos = widget.showOnlyIncomplete
        ? List.from(incompleteTodos)
        : [...incompleteTodos, ...completedTodos];
    
    _previousTodoIds = _displayedTodos.map((t) => t.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();

    final incompleteTodos = provider.incompleteTodos;
    final completedTodos = provider.completedTodos;
    final isLoading = provider.isLoading;
    final error = provider.error;

    // 更新显示的待办列表
    _updateDisplayedTodos(incompleteTodos, completedTodos);

    if (isLoading && _displayedTodos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '加载失败',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => provider.loadTodos(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (incompleteTodos.isEmpty && completedTodos.isEmpty) {
      return _buildEmptyState(theme, true);
    }

    if (widget.showOnlyIncomplete && incompleteTodos.isEmpty) {
      return _buildEmptyState(theme, false);
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _displayedTodos.length,
      itemBuilder: (context, index, animation) {
        if (index >= _displayedTodos.length) return const SizedBox.shrink();
        return _buildAnimatedItem(_displayedTodos[index], animation, false);
      },
    );
  }

  void _updateDisplayedTodos(
    List<TodoItem> incompleteTodos,
    List<TodoItem> completedTodos,
  ) {
    final newTodos = widget.showOnlyIncomplete
        ? incompleteTodos
        : [...incompleteTodos, ...completedTodos];

    final newTodoIds = newTodos.map((t) => t.id).toList();

    // 如果 ID 列表完全相同，只更新内容（例如完成状态变化）
    if (_listEquals(_previousTodoIds, newTodoIds)) {
      setState(() {
        for (int i = 0; i < _displayedTodos.length && i < newTodos.length; i++) {
          _displayedTodos[i] = newTodos[i];
        }
      });
      return;
    }

    // 检测被删除的项目
    for (int i = _displayedTodos.length - 1; i >= 0; i--) {
      final oldTodo = _displayedTodos[i];
      if (!newTodoIds.contains(oldTodo.id)) {
        final removedTodo = _displayedTodos.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(removedTodo, animation, true),
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    // 检测新增的项目
    for (int i = 0; i < newTodos.length; i++) {
      final newTodo = newTodos[i];
      if (i >= _displayedTodos.length) {
        // 在末尾添加新项目
        setState(() {
          _displayedTodos.add(newTodo);
        });
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 400),
        );
      } else if (_displayedTodos[i].id != newTodo.id) {
        // 在中间插入新项目
        setState(() {
          _displayedTodos.insert(i, newTodo);
        });
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 400),
        );
      } else {
        // 更新现有项目
        setState(() {
          _displayedTodos[i] = newTodo;
        });
      }
    }

    _previousTodoIds = newTodoIds;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildAnimatedItem(
      TodoItem todo, Animation<double> animation, bool isRemoving) {
    final isCompleted = !context
        .read<TodoProvider>()
        .incompleteTodos
        .any((t) => t.id == todo.id);

    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: isRemoving ? const Offset(1, 0) : const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: isCompleted && !widget.showOnlyIncomplete
              ? Opacity(
                  opacity: 0.7,
                  child: TodoCard(todo: todo),
                )
              : TodoCard(todo: todo),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isAllEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              isAllEmpty ? Icons.checklist : Icons.task_alt,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isAllEmpty ? '暂无待办事项' : '所有待办事项已完成',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isAllEmpty ? '点击麦克风按钮开始语音输入' : '点击下方按钮添加新待办',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
