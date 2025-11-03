import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

class TodoDetailScreen extends ConsumerWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoDetailProvider(todoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Todo Detail')),
      body: todoAsync.when(
        data: (todo) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(todo.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(todo.description),
              const SizedBox(height: 24),
              Text('Created: ${DateFormat.yMd().add_jm().format(todo.createdAt)}'),
              if (todo.completedAt != null)
                Text('Completed: ${DateFormat.yMd().add_jm().format(todo.completedAt!)}'),
              const SizedBox(height: 16),
              Text('Status: ${todo.isCompleted ? "Completed" : "Pending"}'),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
