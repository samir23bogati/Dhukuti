import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import 'auth_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _resetting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Router redirect handles dashboard vs email verification.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthValidators.loginErrorMessage(e.code))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailError = AuthValidators.email(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to reset password')),
      );
      return;
    }

    setState(() => _resetting = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      // Same message whether or not the account exists (no enumeration).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link was sent.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'network-request-failed'
          ? 'Network error. Check your connection.'
          : 'If an account exists for that email, a reset link was sent.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.06,
              vertical: h * 0.03,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w > 600 ? 440 : w),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Suvhainvestments.png',
                      width: w * 0.28,
                      height: w * 0.28,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: h * 0.012),
                    Text(
                      'Suvha Investor',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                        fontSize: w * 0.06,
                      ),
                    ),
                    SizedBox(height: h * 0.03),
                    Card(
                      elevation: 0,
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.04),
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(w * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                                fontSize: w * 0.05,
                              ),
                            ),
                            SizedBox(height: h * 0.03),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: AuthValidators.email,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: w * 0.055,
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.02),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: (v) =>
                                  AuthValidators.password(v, requireStrong: false),
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: w * 0.055,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: w * 0.055,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetting ? null : _resetPassword,
                                child: _resetting
                                    ? SizedBox(
                                        width: w * 0.04,
                                        height: w * 0.04,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.primary,
                                        ),
                                      )
                                    : Text(
                                        'Forgot Password?',
                                        style: TextStyle(fontSize: w * 0.032),
                                      ),
                              ),
                            ),
                            SizedBox(height: h * 0.01),
                            SizedBox(
                              height: h * 0.06,
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                child: _loading
                                    ? SizedBox(
                                        width: w * 0.05,
                                        height: w * 0.05,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: w * 0.04),
                                      ),
                              ),
                            ),
                            SizedBox(height: h * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    fontSize: w * 0.033,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.signup),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: w * 0.033),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
