import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../core/connectivity_service.dart';

/// Home dashboard — first tab in the main navigation.
class HomePage extends StatefulWidget {
  /// Called when the user taps "See All Tasks" to jump to the TODOs tab.
  final VoidCallback? onGoToTodos;

  /// Called when the user taps the grades teaser to jump to the Grades tab.
  final VoidCallback? onGoToGrades;

  const HomePage({super.key, this.onGoToTodos, this.onGoToGrades});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _todoService = TodoService();
  final _profileService = ProfileService();

  bool _isOnline = true;

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const _accent = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    ConnectivityService.onStatusChange.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await ConnectivityService.isOnline;
    if (mounted) setState(() => _isOnline = online);
  }

  // ── Greeting ─────────────────────────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _todayDate =>
      DateFormat('EEEE, MMMM d').format(DateTime.now());

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.getProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return StreamBuilder<List<Todo>>(
            stream: _todoService.getAllTodos(),
            builder: (context, todoSnap) {
              final todos = todoSnap.data ?? [];
              return _buildBody(context, profile, todos, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile,
      List<Todo> todos, bool isDark) {
    final active = todos.where((t) => !t.isDone && !t.isDeleted).toList();
    final done = todos
        .where((t) =>
            t.isDone &&
            !t.isDeleted &&
            _isToday(t.createdAt))
        .toList();
    final overdue = todos.where((t) {
      if (t.isDone || t.isDeleted || t.dueDate == null) return false;
      final today = DateTime.now();
      final due = t.dueDate!;
      return due.isBefore(DateTime(today.year, today.month, today.day));
    }).toList();

    final total = active.length + done.length;
    final completionRatio = total == 0 ? 0.0 : done.length / total;

    final firstName = (profile?.name.isNotEmpty == true)
        ? profile!.name.split(' ').first
        : 'Student';

    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return CustomScrollView(
      slivers: [
        // ── Offline Banner ─────────────────────────────────────────────────
        if (!_isOnline)
          SliverToBoxAdapter(
            child: _OfflineBanner(isDark: isDark),
          ),

        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildHeader(firstName, textPrimary, textMuted, isDark),
        ),

        // ── Stats Row ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildStatsRow(
              active.length, done.length, overdue.length, isDark),
        ),

        // ── Progress Card ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildProgressCard(
              completionRatio, done.length, total, isDark),
        ),

        // ── Recent Tasks ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            context,
            title: 'Recent Tasks',
            icon: Icons.task_alt_rounded,
            onSeeAll: widget.onGoToTodos,
            isDark: isDark,
          ),
        ),

        if (active.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyPlaceholder(
              icon: Icons.checklist_rounded,
              message: 'All caught up! No active tasks.',
              isDark: isDark,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _RecentTaskTile(
                todo: active[i],
                isDark: isDark,
                onComplete: () async {
                  await _todoService.markDone(active[i].id);
                },
              ),
              childCount: active.take(3).length,
            ),
          ),

        // ── Grades Teaser ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildGradeTeaser(isDark),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(String name, Color textPrimary, Color textMuted,
      bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF152535), const Color(0xFF1A3045)]
              : [Colors.white, const Color(0xFFE8F4FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: TextStyle(
                    color:
                        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayDate,
                  style: TextStyle(
                    color:
                        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: _accent, size: 26),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ───────────────────────────────────────────────────────────────
  Widget _buildStatsRow(int active, int done, int overdue, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Active',
              value: '$active',
              icon: Icons.pending_actions_rounded,
              color: _accent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Done Today',
              value: '$done',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF66BB6A),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Overdue',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF5350),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Card ───────────────────────────────────────────────────────────
  Widget _buildProgressCard(
      double ratio, int done, int total, bool isDark) {
    final pct = (ratio * 100).toStringAsFixed(0);
    final surfaceColor =
        isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  backgroundColor: _accent.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(_accent),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done of $total tasks completed',
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: _accent.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(_accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Grades Teaser ───────────────────────────────────────────────────────────
  Widget _buildGradeTeaser(bool isDark) {
    return GestureDetector(
      onTap: widget.onGoToGrades,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A2F45), const Color(0xFF152535)]
                : [const Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: _accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Your Grades',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D1B2A),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to see attendance, quizzes, exams & more',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF8B9EB0)
                          : const Color(0xFF5A6E7F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _accent, size: 22),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecentTaskTile extends StatelessWidget {
  const _RecentTaskTile({
    required this.todo,
    required this.isDark,
    required this.onComplete,
  });
  final Todo todo;
  final bool isDark;
  final VoidCallback onComplete;

  Color get _priorityColor {
    switch (todo.priority) {
      case 'high':
        return const Color(0xFFEF5350);
      case 'medium':
        return const Color(0xFFFFCA28);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Priority strip
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: _priorityColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (todo.dueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Due: ${DateFormat('MMM d').format(todo.dueDate!)}',
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Complete button
          GestureDetector(
            onTap: onComplete,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 16, color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({
    required this.icon,
    required this.message,
    required this.isDark,
  });
  final IconData icon;
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon,
                size: 40,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCA28).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCA28).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFFCA28), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline. Tasks will sync when you\'re back online.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF0D1B2A),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
