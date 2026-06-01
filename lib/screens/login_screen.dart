import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'screens.dart';

/// Modern black/gray/white login & sign-up screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  final _authService = AuthService();
  final _profileService = ProfileService();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isSignUp = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Palette (black / gray / white) ────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Colors.white;
  static const _textMuted = Color(0xFF737373);
  static const _inputBg = Color(0xFF0F0F0F);
  static const _inputBorder = Color(0xFF2A2A2A);
  static const _inputFocus = Color(0xFFE0E0E0);
  static const _danger = Color(0xFFFF4D4D);
  static const _btnBg = Colors.white;
  static const _btnText = Colors.black;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
        await _profileService.createProfile(
          name: _nameCtrl.text,
          idNumber: _idCtrl.text,
          section: _sectionCtrl.text,
        );
      } else {
        await _authService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.friendlyError(e));
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email above first.');
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent!'),
          backgroundColor: Color(0xFF333333),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.friendlyError(e));
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
    _slideCtrl.forward(from: 0);
    _fadeCtrl.forward(from: 0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                _buildWordmark(),
                const SizedBox(height: 52),
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildForm(),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wordmark ───────────────────────────────────────────────────────────────
  Widget _buildWordmark() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'BOIS',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'ER',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isSignUp
              ? 'Create your student account'
              : 'Sign in to your account',
          style: const TextStyle(
            color: _textMuted,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sign-up only fields ──────────────────────────────────────────
          if (_isSignUp) ...[
            _Field(
              ctrl: _nameCtrl,
              label: 'Full Name',
              hint: 'Juan Dela Cruz',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full name is required.' : null,
            ),
            const SizedBox(height: 14),
            _Field(
              ctrl: _idCtrl,
              label: 'Student ID',
              hint: '2024-00123',
              icon: Icons.badge_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Student ID is required.' : null,
            ),
            const SizedBox(height: 14),
            _Field(
              ctrl: _sectionCtrl,
              label: 'Section',
              hint: 'BSIT 3A',
              icon: Icons.groups_2_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Section is required.' : null,
            ),
            const SizedBox(height: 14),
          ],

          // ── Common fields ────────────────────────────────────────────────
          _Field(
            ctrl: _emailCtrl,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _Field(
            ctrl: _passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            onToggleObscure: () =>
                setState(() => _obscurePass = !_obscurePass),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              if (v.length < 6) return 'At least 6 characters.';
              return null;
            },
          ),

          if (_isSignUp) ...[
            const SizedBox(height: 14),
            _Field(
              ctrl: _confirmCtrl,
              label: 'Confirm Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password.';
                if (v != _passwordCtrl.text) return 'Passwords do not match.';
                return null;
              },
            ),
          ],

          // ── Forgot password ──────────────────────────────────────────────
          if (!_isSignUp)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: _textMuted,
                  padding: const EdgeInsets.only(top: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot password?',
                    style: TextStyle(fontSize: 12)),
              ),
            ),

          // ── Error banner ─────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: 28),

          // ── Submit ───────────────────────────────────────────────────────
          _SubmitButton(
            label: _isSignUp ? 'Create Account' : 'Sign In',
            isLoading: _isLoading,
            onTap: _isLoading ? null : _submit,
          ),

          const SizedBox(height: 28),

          // ── Divider ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.08))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 11,
                      letterSpacing: 1.5),
                ),
              ),
              Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.08))),
            ],
          ),

          const SizedBox(height: 28),

          // ── Toggle ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? 'Already have an account? '
                    : "Don't have an account? ",
                style: const TextStyle(color: _textMuted, fontSize: 13),
              ),
              GestureDetector(
                onTap: _toggleMode,
                child: Text(
                  _isSignUp ? 'Sign In' : 'Sign Up',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  static const _bg = Color(0xFF0F0F0F);
  static const _border = Color(0xFF2A2A2A);
  static const _focus = Color(0xFFE0E0E0);
  static const _muted = Color(0xFF737373);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14),
            prefixIcon: Icon(icon, color: _muted, size: 18),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _muted,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: _bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _focus, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
            ),
            errorStyle: const TextStyle(
                color: Color(0xFFFF6B6B), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFFF4D4D).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF4D4D), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFFF6B6B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
