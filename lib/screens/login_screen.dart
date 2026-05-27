import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'screens.dart';

/// Full-page login / sign-up form backed by Firebase Authentication.
///
/// On successful sign-in the auth-state stream handled in [main.dart]
/// will automatically redirect to the home screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── controllers ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _authService = AuthService();

  // ── state ──────────────────────────────────────────────────────────────────
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── palette ────────────────────────────────────────────────────────────────
  static const _navy = Color(0xFF0D1B2A);
  static const _indigo = Color(0xFF1A3C5E);
  static const _accent = Color(0xFF4FC3F7);
  static const _accentDark = Color(0xFF0288D1);
  static const _surface = Color(0xFF152535);
  static const _errorRed = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── actions ────────────────────────────────────────────────────────────────
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
        SnackBar(
          content: Text('Reset link sent to $email'),
          backgroundColor: _accentDark,
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
    _fadeCtrl.forward(from: 0);
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          // ── animated gradient background ──────────────────────────────────
          _GradientBackground(navy: _navy, indigo: _indigo),

          // ── centered card ─────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // logo + title
            _buildHeader(),
            const SizedBox(height: 32),

            // email
            _buildLabel('Email'),
            const SizedBox(height: 6),
            _buildEmailField(),
            const SizedBox(height: 18),

            // password
            _buildLabel('Password'),
            const SizedBox(height: 6),
            _buildPasswordField(),

            // confirm password (sign-up only)
            if (_isSignUp) ...[
              const SizedBox(height: 18),
              _buildLabel('Confirm Password'),
              const SizedBox(height: 6),
              _buildConfirmField(),
            ],

            // forgot password (sign-in only)
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: _accent,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),

            // error banner
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorBanner(),
            ],

            const SizedBox(height: 28),

            // submit button
            _buildSubmitButton(),

            const SizedBox(height: 20),

            // divider
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.white.withOpacity(0.12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withOpacity(0.12)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // toggle mode
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  // ── sub-widgets ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_accent, _accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSignUp
              ? 'Sign up to get started'
              : 'Sign in to your account',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB0BEC5),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildEmailField() {
    return _StyledField(
      controller: _emailCtrl,
      hint: 'you@example.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required.';
        final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!re.hasMatch(v.trim())) return 'Enter a valid email.';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _StyledField(
      controller: _passwordCtrl,
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      obscure: _obscurePassword,
      toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required.';
        if (v.length < 6) return 'At least 6 characters required.';
        return null;
      },
    );
  }

  Widget _buildConfirmField() {
    return _StyledField(
      controller: _confirmCtrl,
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      obscure: _obscureConfirm,
      toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password.';
        if (v != _passwordCtrl.text) return 'Passwords do not match.';
        return null;
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _errorRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorRed.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: _errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: _errorRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, _accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isSignUp ? 'Create Account' : 'Sign In',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── shared styled text-field ──────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.toggleObscure,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? toggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  static const _border = Color(0xFF263C52);
  static const _focused = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0F2132),
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
          borderSide: const BorderSide(color: _focused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEF5350), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
      ),
    );
  }
}

// ── animated gradient background ─────────────────────────────────────────────
class _GradientBackground extends StatefulWidget {
  const _GradientBackground({required this.navy, required this.indigo});
  final Color navy;
  final Color indigo;

  @override
  State<_GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<_GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Alignment> _begin, _end;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _begin = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.topLeft, end: Alignment.topRight),
          weight: 1),
    ]).animate(_ctrl);

    _end = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.bottomRight, end: Alignment.bottomLeft),
          weight: 1),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.navy, widget.indigo, const Color(0xFF0D2137)],
            begin: _begin.value,
            end: _end.value,
          ),
        ),
      ),
    );
  }
}
