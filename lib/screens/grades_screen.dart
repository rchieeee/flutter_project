import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  
  Student? _student;
  bool _isLoading = true;
  String? _error;

  static const _navy = Color(0xFF0D1B2A);
  static const _surface = Color(0xFF152535);
  static const _accent = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final email = _authService.currentUser?.email;
    if (email == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final student = await _firestoreService.getStudentByEmail(email);
      setState(() {
        _student = student;
        _isLoading = false;
        if (student == null) {
          _error = 'No student record found for $email in instructor database.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load student data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _navy,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_error != null || _student == null) {
      return Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(backgroundColor: _surface, title: const Text('My Grades')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Student record not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.withOpacity(0.2),
                    foregroundColor: _accent,
                  ),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          backgroundColor: _surface,
          title: Text(_student!.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: _accent,
            labelColor: _accent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'Quizzes'),
              Tab(text: 'Exams'),
              Tab(text: 'Activities'),
              Tab(text: 'Oral'),
              Tab(text: 'Projects'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AttendanceTab(studentId: _student!.id),
            _QuizzesTab(studentId: _student!.id),
            _ExamsTab(studentId: _student!.id),
            _ActivitiesTab(studentId: _student!.id),
            _OralTab(studentId: _student!.id),
            _ProjectsTab(studentId: _student!.id),
          ],
        ),
      ),
    );
  }
}

// ── Tab Views ───────────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attendance>>(
      stream: FirestoreService().getAttendance(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No attendance records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final att = records[i];
            Color statusColor;
            if (att.isPresent) statusColor = const Color(0xFF66BB6A);
            else if (att.isLate) statusColor = const Color(0xFFFFCA28);
            else statusColor = const Color(0xFFEF5350);

            return GradeCard(
              title: 'Attendance',
              subtitle: 'Status: ${att.status.toUpperCase()}',
              date: att.date,
              statusText: att.status.toUpperCase(),
              statusColor: statusColor,
            );
          },
        );
      },
    );
  }
}

class _QuizzesTab extends StatelessWidget {
  const _QuizzesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quiz>>(
      stream: FirestoreService().getQuizzes(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No quiz records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final q = records[i];
            return GradeCard(
              title: 'Quiz',
              subtitle: 'Score: ${q.score}/${q.totalItems}',
              date: q.date,
              score: q.score,
              total: q.totalItems,
              badgeText: q.type.toUpperCase(),
            );
          },
        );
      },
    );
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Exam>>(
      stream: FirestoreService().getExams(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No exam records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final e = records[i];
            return GradeCard(
              title: 'Exam',
              subtitle: 'Score: ${e.score}/${e.totalItems}',
              date: e.date,
              score: e.score,
              total: e.totalItems,
              badgeText: e.type.toUpperCase(),
              badgeColor: const Color(0xFFAB47BC), // purple for exams
            );
          },
        );
      },
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: FirestoreService().getActivities(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No activity records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final a = records[i];
            return GradeCard(
              title: 'Activity',
              subtitle: 'Score: ${a.score}/${a.totalPoints}',
              date: a.date,
              score: a.score,
              total: a.totalPoints,
            );
          },
        );
      },
    );
  }
}

class _OralTab extends StatelessWidget {
  const _OralTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OralRecitation>>(
      stream: FirestoreService().getOralRecitations(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No oral recitation records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final o = records[i];
            return GradeCard(
              title: 'Oral Recitation',
              subtitle: 'Points: ${o.points}',
              date: o.date,
              points: o.points,
            );
          },
        );
      },
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Project>>(
      stream: FirestoreService().getProjects(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const _EmptyState('No project records');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final p = records[i];
            return GradeCard(
              title: 'Project',
              subtitle: 'Score: ${p.score}/${p.totalPoints}',
              date: p.date,
              score: p.score,
              total: p.totalPoints,
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }
}
