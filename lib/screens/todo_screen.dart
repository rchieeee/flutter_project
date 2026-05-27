import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _todoService = TodoService();

  static const _navy = Color(0xFF0D1B2A);
  static const _surface = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);

  void _showAddTodoDialog([Todo? existingTodo]) {
    final titleCtrl = TextEditingController(text: existingTodo?.title);
    final descCtrl = TextEditingController(text: existingTodo?.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          existingTodo == null ? 'New TODO' : 'Edit TODO',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _accent),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _accent),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              
              if (existingTodo == null) {
                _todoService.addTodo(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                );
              } else {
                _todoService.updateTodo(
                  existingTodo.id,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _navy,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('My TODOs'),
      ),
      body: StreamBuilder<List<Todo>>(
        stream: _todoService.getTodos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _accent));
          }
          
          if (snapshot.hasError) {
             return Center(
               child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
             );
          }

          final todos = snapshot.data ?? [];
          
          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'No TODOs yet.\nTap + to add one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, i) {
              final todo = todos[i];
              return TodoTile(
                todo: todo,
                onToggle: () => _todoService.toggleDone(todo.id, todo.isDone),
                onDelete: () => _todoService.deleteTodo(todo.id),
                onEdit: () => _showAddTodoDialog(todo),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(),
        backgroundColor: _accent,
        child: const Icon(Icons.add_rounded, color: _navy),
      ),
    );
  }
}
