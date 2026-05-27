import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Reusable list tile for a single Todo item.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  static const _cardBg = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);
  static const _muted = Color(0xFF7B98B0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: todo.isDone
              ? _accent.withOpacity(0.08)
              : _accent.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: todo.isDone ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: todo.isDone ? _accent : _muted,
                width: 1.5,
              ),
            ),
            child: todo.isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isDone
                ? Colors.white.withOpacity(0.35)
                : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white38,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                todo.description,
                style: TextStyle(
                  color: todo.isDone
                      ? _muted.withOpacity(0.5)
                      : _muted,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(todo.createdAt),
              style: TextStyle(
                color: _muted.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: _muted),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFEF5350)),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
