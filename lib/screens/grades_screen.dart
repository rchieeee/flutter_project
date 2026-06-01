import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _firestoreService = FirestoreService();
  final _profileService = ProfileService();

  Student? _student;
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  // Expansion state for each section
  final Map<String, bool> _expanded = {
    'attendance': true,
    'quizzes': false,
    'exams': false,
    'activities': false,
    'oral': false,
    'projects': false,
  };

  // What-If simulator: simulated extra scores keyed by section
  // Each entry: { 'score': int, 'total': int, 'label': String }
  final Map<String, List<Map<String, dynamic>>> _simulated = {
    'quizzes': [],
    'exams': [],
    'activities': [],
    'oral': [],
    'projects': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final email = authService.currentUser?.email;
    if (email == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _firestoreService.getStudentByEmail(email),
        _profileService.getProfile().first,
      ]);

      setState(() {
        _student = results[0] as Student?;
        _profile = results[1] as UserProfile?;
        _isLoading = false;
        if (_student == null) {
          _error = 'No student record found for $email in the instructor database.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load student data: $e';
        _isLoading = false;
      });
    }
  }

  // ── Color helpers ──────────────────────────────────────────────────────────

  Color _scoreColor(double pct) {
    if (pct >= 0.75) return const Color(0xFF66BB6A);
    if (pct >= 0.50) return const Color(0xFFFFCA28);
    return const Color(0xFFEF5350);
  }

  // ── What-If simulator dialog ───────────────────────────────────────────────

  void _showSimulateDialog(
    BuildContext context,
    String section,
    String label, {
    bool isPoints = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);
    const accent = Color(0xFF4FC3F7);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_rounded, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What-If Simulator',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Add a simulated $label score',
                            style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: isPoints ? 'Points earned' : 'Your score',
                  labelStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (!isPoints) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Total items / points',
                    labelStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final score = int.tryParse(scoreCtrl.text.trim());
                      if (score == null || score < 0) return;
                      if (!isPoints) {
                        final total = int.tryParse(totalCtrl.text.trim());
                        if (total == null || total <= 0) return;
                        setState(() {
                          _simulated[section]!.add({
                            'score': score,
                            'total': total,
                            'label': label,
                          });
                        });
                      } else {
                        setState(() {
                          _simulated[section]!.add({
                            'score': score,
                            'total': 0,
                            'label': label,
                          });
                        });
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: const Color(0xFF0D1B2A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Add Simulation',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section accordion builder ──────────────────────────────────────────────

  Widget _buildSection({
    required BuildContext context,
    required String sectionKey,
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
    bool showSimulator = false,
    bool isPoints = false,
    String simulatorLabel = '',
    VoidCallback? onClearSim,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);
    final isOpen = _expanded[sectionKey] ?? false;
    final hasSim = (_simulated[sectionKey]?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () =>
                setState(() => _expanded[sectionKey] = !isOpen),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (hasSim)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SIM',
                        style: TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (hasSim) const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                child,
                // Simulator controls
                if (showSimulator)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSimulateDialog(
                              context,
                              sectionKey,
                              simulatorLabel,
                              isPoints: isPoints,
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 18),
                            label: const Text('Simulate Score'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4FC3F7),
                              side: BorderSide(
                                  color: const Color(0xFF4FC3F7)
                                      .withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (hasSim) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear simulated scores',
                            onPressed: () => setState(
                                () => _simulated[sectionKey]!.clear()),
                            icon: const Icon(Icons.delete_sweep_rounded,
                                color: Color(0xFFEF5350), size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEF5350)
                                  .withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Record tile ─────────────────────────────────────────────────────────────

  Widget _recordTile(
    BuildContext context, {
    required DateTime date,
    required String title,
    required String subtitle,
    Color? leftColor,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (leftColor ?? const Color(0xFF4FC3F7))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    color: leftColor ?? const Color(0xFF4FC3F7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Score chip ─────────────────────────────────────────────────────────────

  Widget _scoreChip(int score, int total) {
    final pct = total > 0 ? score / total : 0.0;
    final color = _scoreColor(pct);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$score/$total',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Summary bar ────────────────────────────────────────────────────────────

  Widget _summaryBar(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    String? note,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (note != null)
                Text(note,
                    style: TextStyle(color: textMuted, fontSize: 11)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Simulated score tiles ──────────────────────────────────────────────────

  Widget _simulatedTiles(BuildContext context, String section,
      {bool isPoints = false}) {
    final sims = _simulated[section] ?? [];
    if (sims.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.science_rounded,
                  color: Color(0xFF4FC3F7), size: 14),
              const SizedBox(width: 6),
              Text('Simulated Scores',
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ...sims.asMap().entries.map((entry) {
          final i = entry.key;
          final sim = entry.value;
          return Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF4FC3F7), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPoints
                        ? 'Simulated: +${sim['score']} pts'
                        : 'Simulated: ${sim['score']}/${sim['total']}',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _simulated[section]!.removeAt(i);
                  }),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF4FC3F7)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF0F4F8);
    const accent = Color(0xFF4FC3F7);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
            child: CircularProgressIndicator(color: accent)),
      );
    }

    if (_error != null) {
      final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text('My Grades',
              style: TextStyle(
                  color: textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.withValues(alpha: 0.2),
                    foregroundColor: accent,
                    elevation: 0,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Display the logged-in profile name, fall back to student record
    final displayName = _profile != null && _profile!.name.isNotEmpty
        ? _profile!.name
        : _student!.name;
    final displaySection = _profile != null && _profile!.section.isNotEmpty
        ? _profile!.section
        : _student!.section;

    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted =
        isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);
    final surfaceColor =
        isDark ? const Color(0xFF152535) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF152535),
                            const Color(0xFF1A3045),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFE8F4FD),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.2 : 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Section $displaySection',
                            style:
                                TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'My Grades',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Simulator hint banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_rounded,
                          color: Color(0xFF4FC3F7), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Expand a section and tap "Simulate Score" to see how a hypothetical score would change your average.',
                          style: TextStyle(
                              color: textMuted,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Attendance Section ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Attendance>>(
                stream: FirestoreService().getAttendance(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final present =
                      records.where((r) => r.isPresent).length;
                  final total = records.length;
                  final rate = total == 0
                      ? '—'
                      : '${(present / total * 100).toStringAsFixed(0)}%';

                  return _buildSection(
                    context: context,
                    sectionKey: 'attendance',
                    title: 'Attendance',
                    icon: Icons.how_to_reg_rounded,
                    accentColor: const Color(0xFF66BB6A),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty)
                          _emptySection(context, 'No attendance records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'ATTENDANCE RATE',
                            value: rate,
                            color: const Color(0xFF66BB6A),
                            note: '$present of $total days present',
                          ),
                          ...records.map((att) {
                            Color statusColor;
                            if (att.isPresent) {
                              statusColor = const Color(0xFF66BB6A);
                            } else if (att.isLate) {
                              statusColor = const Color(0xFFFFCA28);
                            } else {
                              statusColor = const Color(0xFFEF5350);
                            }
                            return _recordTile(
                              context,
                              date: att.date,
                              title: 'Attendance',
                              subtitle:
                                  'Status: ${att.status.toUpperCase()}',
                              leftColor: statusColor,
                              trailing: _statusBadge(
                                  att.status.toUpperCase(), statusColor),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Quizzes Section ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Quiz>>(
                stream: FirestoreService().getQuizzes(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final sims = _simulated['quizzes'] ?? [];

                  double sum =
                      records.fold(0, (s, q) => s + q.percentage);
                  int simTotalScore = 0, simTotalItems = 0;
                  for (var s in sims) {
                    simTotalScore += (s['score'] as int);
                    simTotalItems += (s['total'] as int);
                  }

                  final allCount = records.length + sims.length;
                  double simExtra = simTotalItems > 0
                      ? (simTotalScore / simTotalItems * 100)
                      : 0;
                  final avg = allCount == 0
                      ? '—'
                      : '${((sum + simExtra * sims.length) / allCount).toStringAsFixed(1)}%';

                  return _buildSection(
                    context: context,
                    sectionKey: 'quizzes',
                    title: 'Quizzes',
                    icon: Icons.quiz_rounded,
                    accentColor: const Color(0xFF4FC3F7),
                    showSimulator: true,
                    simulatorLabel: 'Quiz',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty && sims.isEmpty)
                          _emptySection(context, 'No quiz records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'AVERAGE SCORE',
                            value: avg,
                            color: const Color(0xFF4FC3F7),
                            note:
                                'Across $allCount quiz${allCount == 1 ? '' : 'zes'}${sims.isNotEmpty ? ' (incl. simulated)' : ''}',
                          ),
                          ...records.map((q) => _recordTile(
                                context,
                                date: q.date,
                                title: 'Quiz — ${q.type[0].toUpperCase()}${q.type.substring(1)}',
                                subtitle:
                                    'Score: ${q.score}/${q.totalItems}',
                                trailing: _scoreChip(q.score, q.totalItems),
                              )),
                          _simulatedTiles(context, 'quizzes'),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Exams Section ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Exam>>(
                stream: FirestoreService().getExams(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final sims = _simulated['exams'] ?? [];

                  double sum =
                      records.fold(0, (s, e) => s + e.percentage);
                  int simTotalScore = 0, simTotalItems = 0;
                  for (var s in sims) {
                    simTotalScore += (s['score'] as int);
                    simTotalItems += (s['total'] as int);
                  }

                  final allCount = records.length + sims.length;
                  double simExtra = simTotalItems > 0
                      ? (simTotalScore / simTotalItems * 100)
                      : 0;
                  final avg = allCount == 0
                      ? '—'
                      : '${((sum + simExtra * sims.length) / allCount).toStringAsFixed(1)}%';

                  return _buildSection(
                    context: context,
                    sectionKey: 'exams',
                    title: 'Exams',
                    icon: Icons.assignment_rounded,
                    accentColor: const Color(0xFFAB47BC),
                    showSimulator: true,
                    simulatorLabel: 'Exam',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty && sims.isEmpty)
                          _emptySection(context, 'No exam records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'EXAM AVERAGE',
                            value: avg,
                            color: const Color(0xFFAB47BC),
                            note:
                                'Across $allCount exam${allCount == 1 ? '' : 's'}${sims.isNotEmpty ? ' (incl. simulated)' : ''}',
                          ),
                          ...records.map((e) => _recordTile(
                                context,
                                date: e.date,
                                title: 'Exam — ${e.type[0].toUpperCase()}${e.type.substring(1)}',
                                subtitle:
                                    'Score: ${e.score}/${e.totalItems}',
                                leftColor: const Color(0xFFAB47BC),
                                trailing: _scoreChip(e.score, e.totalItems),
                              )),
                          _simulatedTiles(context, 'exams'),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Activities Section ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Activity>>(
                stream: FirestoreService().getActivities(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final sims = _simulated['activities'] ?? [];

                  double sum =
                      records.fold(0, (s, a) => s + a.percentage);
                  int simTotalScore = 0, simTotalItems = 0;
                  for (var s in sims) {
                    simTotalScore += (s['score'] as int);
                    simTotalItems += (s['total'] as int);
                  }

                  final allCount = records.length + sims.length;
                  double simExtra = simTotalItems > 0
                      ? (simTotalScore / simTotalItems * 100)
                      : 0;
                  final avg = allCount == 0
                      ? '—'
                      : '${((sum + simExtra * sims.length) / allCount).toStringAsFixed(1)}%';

                  return _buildSection(
                    context: context,
                    sectionKey: 'activities',
                    title: 'Activities',
                    icon: Icons.edit_note_rounded,
                    accentColor: const Color(0xFF26C6DA),
                    showSimulator: true,
                    simulatorLabel: 'Activity',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty && sims.isEmpty)
                          _emptySection(context, 'No activity records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'ACTIVITY AVERAGE',
                            value: avg,
                            color: const Color(0xFF26C6DA),
                            note:
                                'Across $allCount activit${allCount == 1 ? 'y' : 'ies'}${sims.isNotEmpty ? ' (incl. simulated)' : ''}',
                          ),
                          ...records.map((a) => _recordTile(
                                context,
                                date: a.date,
                                title: 'Activity',
                                subtitle:
                                    'Score: ${a.score}/${a.totalPoints}',
                                leftColor: const Color(0xFF26C6DA),
                                trailing: _scoreChip(a.score, a.totalPoints),
                              )),
                          _simulatedTiles(context, 'activities'),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Oral Recitation Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<OralRecitation>>(
                stream: FirestoreService().getOralRecitations(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final sims = _simulated['oral'] ?? [];

                  int total = records.fold(0, (s, o) => s + o.points);
                  int simPoints =
                      sims.fold(0, (s, sim) => s + (sim['score'] as int));
                  final grandTotal = total + simPoints;

                  return _buildSection(
                    context: context,
                    sectionKey: 'oral',
                    title: 'Oral Recitation',
                    icon: Icons.record_voice_over_rounded,
                    accentColor: const Color(0xFFFFCA28),
                    showSimulator: true,
                    simulatorLabel: 'Oral',
                    isPoints: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty && sims.isEmpty)
                          _emptySection(
                              context, 'No oral recitation records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'TOTAL POINTS',
                            value: grandTotal.toString(),
                            color: const Color(0xFFFFCA28),
                            note:
                                '${records.length + sims.length} recitation${records.length + sims.length == 1 ? '' : 's'}${sims.isNotEmpty ? ' (incl. simulated)' : ''}',
                          ),
                          ...records.map((o) => _recordTile(
                                context,
                                date: o.date,
                                title: 'Oral Recitation',
                                subtitle: 'Earned ${o.points} points',
                                leftColor: const Color(0xFFFFCA28),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA28)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '+${o.points}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFCA28),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )),
                          _simulatedTiles(context, 'oral', isPoints: true),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Projects Section ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Project>>(
                stream: FirestoreService().getProjects(_student!.id),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final sims = _simulated['projects'] ?? [];

                  double sum =
                      records.fold(0, (s, p) => s + p.percentage);
                  int simTotalScore = 0, simTotalItems = 0;
                  for (var s in sims) {
                    simTotalScore += (s['score'] as int);
                    simTotalItems += (s['total'] as int);
                  }

                  final allCount = records.length + sims.length;
                  double simExtra = simTotalItems > 0
                      ? (simTotalScore / simTotalItems * 100)
                      : 0;
                  final avg = allCount == 0
                      ? '—'
                      : '${((sum + simExtra * sims.length) / allCount).toStringAsFixed(1)}%';

                  return _buildSection(
                    context: context,
                    sectionKey: 'projects',
                    title: 'Projects',
                    icon: Icons.folder_special_rounded,
                    accentColor: const Color(0xFFFF7043),
                    showSimulator: true,
                    simulatorLabel: 'Project',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (records.isEmpty && sims.isEmpty)
                          _emptySection(context, 'No project records')
                        else ...[
                          _summaryBar(
                            context,
                            label: 'PROJECT AVERAGE',
                            value: avg,
                            color: const Color(0xFFFF7043),
                            note:
                                'Across $allCount project${allCount == 1 ? '' : 's'}${sims.isNotEmpty ? ' (incl. simulated)' : ''}',
                          ),
                          ...records.map((p) => _recordTile(
                                context,
                                date: p.date,
                                title: 'Project',
                                subtitle:
                                    'Score: ${p.score}/${p.totalPoints}',
                                leftColor: const Color(0xFFFF7043),
                                trailing: _scoreChip(p.score, p.totalPoints),
                              )),
                          _simulatedTiles(context, 'projects'),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _emptySection(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
