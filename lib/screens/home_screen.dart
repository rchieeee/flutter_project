import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/provider.dart';
import 'screens.dart';
import '../services/services.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _accent = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navyColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF0F4F8);
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.black.withValues(alpha: 0.38);

    final pages = [
      // 0 — Home Dashboard
      HomePage(
        onGoToTodos: () => setState(() => _currentIndex = 2),
        onGoToGrades: () => setState(() => _currentIndex = 1),
      ),
      // 1 — Grades
      const GradesScreen(),
      // 2 — TODOs
      const TodoScreen(),
      // 3 — Profile
      _ProfileScreen(onLogout: _handleLogout),
    ];

    return Scaffold(
      backgroundColor: navyColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: surfaceColor,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: _accent,
            unselectedItemColor: unselectedColor,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics_rounded),
                label: 'Grades',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_box_outlined),
                activeIcon: Icon(Icons.check_box_rounded),
                label: 'TODOs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.onLogout});
  final VoidCallback onLogout;

  static const _accent = Color(0xFF4FC3F7);

  // 15 built-in avatars using Material Icons
  static const _avatars = [
    ('avatar_01', Icons.face_rounded),
    ('avatar_02', Icons.face_2_rounded),
    ('avatar_03', Icons.face_3_rounded),
    ('avatar_04', Icons.face_4_rounded),
    ('avatar_05', Icons.face_5_rounded),
    ('avatar_06', Icons.face_6_rounded),
    ('avatar_07', Icons.catching_pokemon_rounded),
    ('avatar_08', Icons.smart_toy_rounded),
    ('avatar_09', Icons.sentiment_very_satisfied_rounded),
    ('avatar_10', Icons.pets_rounded),
    ('avatar_11', Icons.emoji_nature_rounded),
    ('avatar_12', Icons.local_fire_department_rounded),
    ('avatar_13', Icons.star_rounded),
    ('avatar_14', Icons.bolt_rounded),
    ('avatar_15', Icons.rocket_launch_rounded),
  ];

  static IconData _iconForAvatar(String avatarId) {
    for (final a in _avatars) {
      if (a.$1 == avatarId) return a.$2;
    }
    return Icons.face_rounded;
  }

  void _showAvatarPicker(BuildContext context, String currentAvatarId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Avatar',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              itemCount: _avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (ctx, i) {
                final avatar = _avatars[i];
                final isSelected = avatar.$1 == currentAvatarId;
                return GestureDetector(
                  onTap: () {
                    ProfileService().updateAvatar(avatar.$1);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accent.withValues(alpha: 0.25)
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      avatar.$2,
                      color: isSelected ? _accent : textMuted,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navyColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF0F4F8);
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return StreamBuilder<UserProfile?>(
      stream: ProfileService().getProfile(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;

        return StreamBuilder<List<Todo>>(
          stream: TodoService().getAllTodos(),
          builder: (context, todoSnap) {
            final todos = todoSnap.data ?? [];
            final completedAll = todos.where((t) => t.isDone && !t.isDeleted).length;

            final avatarId = profile?.avatarId ?? 'avatar_01';

            return Scaffold(
              backgroundColor: navyColor,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // ── Hero Section ──
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: () => _showAvatarPicker(context, avatarId),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _accent, width: 2.5),
                                    ),
                                    child: Icon(
                                      _iconForAvatar(avatarId),
                                      color: _accent,
                                      size: 52,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: surfaceColor, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: Color(0xFF0D1B2A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              profile?.name ?? 'Loading...',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AuthService().currentUser?.email ?? '',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Info Cards ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _InfoCard(
                              icon: Icons.numbers_rounded,
                              label: 'Student ID',
                              value: profile?.idNumber ?? '—',
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.groups_outlined,
                              label: 'Section',
                              value: profile?.section ?? '—',
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: AuthService().currentUser?.email ?? '—',
                            ),
                            const SizedBox(height: 12),
                            
                            // Theme Switch Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                          color: _accent,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Theme Mode',
                                            style: TextStyle(color: textMuted, fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isDark ? 'Dark Mode' : 'Light Mode',
                                            style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: isDark,
                                    activeColor: _accent,
                                    inactiveThumbColor: const Color(0xFF8B9EB0),
                                    onChanged: (val) {
                                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Stats ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Tasks Done\n(All-Time)',
                                value: completedAll.toString(),
                                color: const Color(0xFF66BB6A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'Tasks Still\nActive',
                                value: todos.where((t) => !t.isDone && !t.isDeleted).length.toString(),
                                color: _accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // ── Edit Profile & Logout Buttons ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditProfileDialog(context, profile),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit Info'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent.withValues(alpha: 0.15),
                                  foregroundColor: _accent,
                                  side: const BorderSide(color: _accent, width: 1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onLogout,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF5350).withValues(alpha: 0.15),
                                  foregroundColor: const Color(0xFFEF5350),
                                  side: const BorderSide(color: Color(0xFFEF5350), width: 1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _EditProfileDialog(
        profile: profile,
        onSave: (name, idNumber, section) {
          ProfileService().updateProfile(
            name: name,
            idNumber: idNumber,
            section: section,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: _accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// ── Reusable Info Card ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.face_rounded, color: Color(0xFF4FC3F7), size: 22),
          ),
          if (icon != Icons.face_rounded) ...[
            // Overwrite default icon if passed
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4FC3F7), size: 22),
            ),
          ],
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable Stat Card ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Dialog ──────────────────────────────────────────────────────

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.onSave});
  final UserProfile profile;
  final void Function(String name, String idNumber, String section) onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _idCtrl;
  late TextEditingController _sectionCtrl;

  static const _accent = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _idCtrl = TextEditingController(text: widget.profile.idNumber);
    _sectionCtrl = TextEditingController(text: widget.profile.section);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textMuted = isDark ? const Color(0xFF8B9EB0) : const Color(0xFF5A6E7F);

    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: textMuted),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Profile Info',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Name Field
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              
              // Student ID Field
              TextField(
                controller: _idCtrl,
                style: TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Student ID Number'),
              ),
              const SizedBox(height: 16),

              // Section Field
              TextField(
                controller: _sectionCtrl,
                style: TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Section'),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      widget.onSave(
                        _nameCtrl.text,
                        _idCtrl.text,
                        _sectionCtrl.text,
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
                    child: const Text('Save Info', style: TextStyle(fontWeight: FontWeight.bold)),
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
