import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable card to display a single grade record.
class GradeCard extends StatelessWidget {
  const GradeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    this.score,
    this.total,
    this.points,
    this.badgeText,
    this.badgeColor,
    this.statusText,
    this.statusColor,
  });

  final String title;
  final String subtitle;
  final DateTime date;

  // For scored items (quizzes, exams, activities, projects)
  final int? score;
  final int? total;

  // For oral recitations
  final int? points;

  // Optional badge (e.g. "Short", "Prelim")
  final String? badgeText;
  final Color? badgeColor;

  // Optional status text (e.g. "Present", "Absent")
  final String? statusText;
  final Color? statusColor;

  static const _cardBg = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);
  static const _textMuted = Color(0xFF7B98B0);

  double? get _percentage {
    if (score != null && total != null && total! > 0) {
      return (score! / total!) * 100;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Left: title + subtitle + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      _Badge(text: badgeText!, color: badgeColor ?? _accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Right: score / status
          if (statusText != null)
            _StatusChip(text: statusText!, color: statusColor ?? _accent)
          else if (_percentage != null)
            _ScoreDisplay(
              score: score!,
              total: total!,
              percentage: _percentage!,
            )
          else if (points != null)
            Text(
              '$points pts',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.score,
    required this.total,
    required this.percentage,
  });
  final int score;
  final int total;
  final double percentage;

  Color get _color {
    if (percentage >= 75) return const Color(0xFF66BB6A);
    if (percentage >= 50) return const Color(0xFFFFCA28);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$score/$total',
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(color: _color.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }
}
