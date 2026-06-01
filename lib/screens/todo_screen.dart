import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _PendingAction {
  final bool expectedDone;
  final bool expectedDeleted;
  final bool isPermanentDelete;

  const _PendingAction({
    required this.expectedDone,
    required this.expectedDeleted,
    this.isPermanentDelete = false,
  });
}

class _TodoScreenState extends State<TodoScreen> {
  final _todoService = TodoService();

  static const _navy = Color(0xFF0D1B2A);
  static const _surface = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);

  String _filter = 'Active'; // 'Active', 'Completed', 'Deleted'

  // Tracks pending actions on the UI to immediately remove dismissed items
  // from the list before Firestore syncs, preventing the Dismissible tree error.
  final Map<String, _PendingAction> _pendingActions = {};

  void _showAddTodoDialog([Todo? existingTodo]) {
    showDialog(
      context: context,
      builder: (context) => _TodoDialog(
        existingTodo: existingTodo,
        onSave: (title, desc, priority, dueDate, category) {
          if (existingTodo == null) {
            _todoService.addTodo(
              title: title,
              description: desc,
              priority: priority,
              dueDate: dueDate,
              category: category,
            );
          } else {
            _todoService.updateTodo(
              existingTodo.id,
              title: title,
              description: desc,
              priority: priority,
              dueDate: dueDate,
              category: category,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: StreamBuilder<List<Todo>>(
          stream: _todoService.getAllTodos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _accent));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final allTodos = snapshot.data ?? [];

            // Clean up any pending actions that have been processed/completed in Firestore
            _pendingActions.removeWhere((id, action) {
              if (action.isPermanentDelete) {
                return !allTodos.any((t) => t.id == id);
              }
              final matches = allTodos.where((t) => t.id == id);
              if (matches.isEmpty) return true;
              final todo = matches.first;
              return todo.isDone == action.expectedDone && todo.isDeleted == action.expectedDeleted;
            });

            // Map each todo in memory to match the pending action state if one exists.
            // This is crucial to immediately reflect status changes in the UI before Firestore updates.
            final mappedTodos = allTodos.map((t) {
              final pending = _pendingActions[t.id];
              if (pending != null) {
                if (pending.isPermanentDelete) return null;
                return t.copyWith(
                  isDone: pending.expectedDone,
                  isDeleted: pending.expectedDeleted,
                );
              }
              return t;
            }).whereType<Todo>().toList();

            // Progress bar is calculated based on active/completed tasks (excluding deleted tasks)
            final nonDeletedTodos = mappedTodos.where((t) => !t.isDeleted).toList();
            final completedCount = nonDeletedTodos.where((t) => t.isDone).length;
            final progress = nonDeletedTodos.isEmpty ? 0.0 : completedCount / nonDeletedTodos.length;

            // Apply active tab filter
            final todos = mappedTodos.where((t) {
              if (_filter == 'Active') return !t.isDone && !t.isDeleted;
              if (_filter == 'Completed') return t.isDone && !t.isDeleted;
              if (_filter == 'Deleted') return t.isDeleted;
              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                // ── Dashboard Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nonDeletedTodos.isEmpty 
                              ? 'You have no tasks.' 
                              : '$completedCount of ${nonDeletedTodos.length} completed today',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress Bar
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filters & Clear Trash Row ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Active', 'Completed', 'Deleted'].map((f) {
                                final isSelected = _filter == f;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(f),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      if (val) setState(() => _filter = f);
                                    },
                                    backgroundColor: _surface,
                                    selectedColor: _accent.withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: isSelected ? _accent : Colors.white.withValues(alpha: 0.6),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        if (_filter == 'Deleted')
                          TextButton.icon(
                            onPressed: () => _confirmClearTrash(context),
                            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF5350), size: 20),
                            label: const Text(
                              'Clear All',
                              style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── List ──
                if (todos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _filter == 'Deleted'
                                ? Icons.delete_outline_rounded
                                : _filter == 'Completed'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.assignment_outlined,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'Deleted'
                                ? 'Trash is empty'
                                : _filter == 'Completed'
                                    ? 'No completed tasks'
                                    : 'All caught up!',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final todo = todos[i];

                          // Custom swipe configurations based on the current tab
                          Widget? backgroundWidget;
                          Widget? secondaryBackgroundWidget;

                          if (_filter == 'Active') {
                            backgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF66BB6A),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                            );
                            secondaryBackgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                            );
                          } else if (_filter == 'Completed') {
                            backgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCA28),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              child: const Icon(Icons.undo_rounded, color: Colors.white, size: 32),
                            );
                            secondaryBackgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                            );
                          } else if (_filter == 'Deleted') {
                            backgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              child: const Icon(Icons.restore_rounded, color: Colors.white, size: 32),
                            );
                            secondaryBackgroundWidget = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 32),
                            );
                          }

                          return Dismissible(
                            key: Key(todo.id),
                            direction: DismissDirection.horizontal,
                            background: backgroundWidget!,
                            secondaryBackground: secondaryBackgroundWidget!,
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe left (secondary background action)
                                if (_filter == 'Deleted') {
                                  // Permanent delete
                                  setState(() {
                                    _pendingActions[todo.id] = const _PendingAction(
                                      expectedDone: false,
                                      expectedDeleted: false,
                                      isPermanentDelete: true,
                                    );
                                  });
                                  _todoService.permanentDelete(todo.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task permanently deleted'),
                                      backgroundColor: const Color(0xFFB71C1C),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                } else {
                                  // Soft delete
                                  setState(() {
                                    _pendingActions[todo.id] = _PendingAction(
                                      expectedDone: todo.isDone,
                                      expectedDeleted: true,
                                    );
                                  });
                                  _todoService.softDelete(todo.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task moved to Deleted Tasks'),
                                      backgroundColor: const Color(0xFFEF5350),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              } else {
                                // Swipe right (primary background action)
                                if (_filter == 'Active') {
                                  // Move to completed
                                  setState(() {
                                    _pendingActions[todo.id] = const _PendingAction(
                                      expectedDone: true,
                                      expectedDeleted: false,
                                    );
                                  });
                                  _todoService.markDone(todo.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task marked as Completed'),
                                      backgroundColor: const Color(0xFF66BB6A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                } else if (_filter == 'Completed') {
                                  // Move back to active (undo)
                                  setState(() {
                                    _pendingActions[todo.id] = const _PendingAction(
                                      expectedDone: false,
                                      expectedDeleted: false,
                                    );
                                  });
                                  _todoService.markUndone(todo.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task moved back to Active'),
                                      backgroundColor: const Color(0xFFFFCA28),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                } else if (_filter == 'Deleted') {
                                  // Restore soft-deleted task
                                  setState(() {
                                    _pendingActions[todo.id] = const _PendingAction(
                                      expectedDone: false,
                                      expectedDeleted: false,
                                    );
                                  });
                                  _todoService.restore(todo.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task restored to Active'),
                                      backgroundColor: _accent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              }
                            },
                            child: TodoTile(
                              todo: todo,
                              onEdit: _filter == 'Deleted' ? null : () => _showAddTodoDialog(todo),
                            ),
                          );
                        },
                        childCount: todos.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _filter == 'Deleted'
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTodoDialog(),
              backgroundColor: _accent,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, color: _navy, size: 32),
            ),
    );
  }

  void _confirmClearTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Empty Trash',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete all tasks in the trash? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _todoService.clearTrash();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Trash cleared'),
                  backgroundColor: const Color(0xFFEF5350),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ── Todo Form Dialog ────────────────────────────────────────────────────────
// (Kept exactly as before, as it is already modern)

class _TodoDialog extends StatefulWidget {
  const _TodoDialog({
    this.existingTodo,
    required this.onSave,
  });

  final Todo? existingTodo;
  final void Function(
    String title,
    String description,
    String priority,
    DateTime? dueDate,
    String category,
  ) onSave;

  @override
  State<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<_TodoDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  
  String _priority = 'low';
  String _category = 'personal';
  DateTime? _dueDate;

  static const _surface = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);
  static const _muted = Color(0xFF7B98B0);

  final _categories = ['personal', 'school', 'work', 'project', 'other'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingTodo?.title);
    _descCtrl = TextEditingController(text: widget.existingTodo?.description);
    
    if (widget.existingTodo != null) {
      _priority = widget.existingTodo!.priority;
      _category = widget.existingTodo!.category;
      _dueDate = widget.existingTodo!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              onPrimary: Color(0xFF0D1B2A),
              surface: _surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                widget.existingTodo == null ? 'Create Task' : 'Edit Task',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title Field
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: const TextStyle(color: _muted),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description Field
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: const TextStyle(color: _muted),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority & Category Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _priority,
                          dropdownColor: _surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'high', child: Text('High')),
                          ],
                          onChanged: (val) => setState(() => _priority = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _category,
                          dropdownColor: _surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c[0].toUpperCase() + c.substring(1)),
                          )).toList(),
                          onChanged: (val) => setState(() => _category = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Due Date Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Due Date', style: TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: _dueDate == null ? _muted : _accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dueDate == null ? 'Set a deadline...' : DateFormat('EEE, MMM d, yyyy').format(_dueDate!),
                              style: TextStyle(
                                color: _dueDate == null ? _muted : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_dueDate != null)
                            InkWell(
                              onTap: () => setState(() => _dueDate = null),
                              child: const Icon(Icons.close_rounded, size: 18, color: _muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: _muted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_titleCtrl.text.trim().isEmpty) return;
                      widget.onSave(
                        _titleCtrl.text,
                        _descCtrl.text,
                        _priority,
                        _dueDate,
                        _category,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF0D1B2A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
