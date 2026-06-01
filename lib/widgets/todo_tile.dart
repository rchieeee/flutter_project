import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Modern, sleek list tile for a single Todo item.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    this.onEdit,
  });

  final Todo todo;
  final VoidCallback? onEdit;

  static const _cardBg = Color(0xFF1E2A38); // Slightly lighter than navy for elevation
  static const _accent = Color(0xFF4FC3F7);
  static const _muted = Color(0xFF8B9EB0);

  Color get _priorityColor {
    switch (todo.priority) {
      case 'high':
        return const Color(0xFFEF5350);
      case 'medium':
        return const Color(0xFFFFCA28);
      case 'low':
      default:
        return const Color(0xFF66BB6A);
    }
  }

  bool get _isOverdue {
    if (todo.dueDate == null || todo.isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
    return due.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: todo.isDone ? _cardBg.withValues(alpha: 0.5) : _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: todo.isDone 
          ? [] 
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Priority Indicator
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: todo.isDone ? _muted.withValues(alpha: 0.3) : _priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: todo.isDone ? [] : [
                      BoxShadow(
                        color: _priorityColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(2, 0),
                      )
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Texts & Badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: todo.isDone ? _muted : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                  decorationColor: _muted,
                                ),
                                child: Text(todo.title),
                              ),
                              
                              // Description
                              if (todo.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  todo.description,
                                  style: TextStyle(
                                    color: todo.isDone ? _muted.withValues(alpha: 0.5) : _muted.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              
                              // Bottom Row: Category & Due Date
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Soft Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      todo.category.toUpperCase(),
                                      style: const TextStyle(
                                        color: _accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  
                                  // Due Date
                                  if (todo.dueDate != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: _isOverdue ? const Color(0xFFEF5350) : _muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd').format(todo.dueDate!),
                                          style: TextStyle(
                                            color: _isOverdue ? const Color(0xFFEF5350) : _muted,
                                            fontSize: 12,
                                            fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
