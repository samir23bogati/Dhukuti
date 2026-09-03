import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _checking = false;
  bool _resending = false;
  String? _message;

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    final auth = context.read<AuthState>();
    try {
      await auth.reloadUser();
      if (!mounted) return;
      if (!auth.isEmailVerified) {
        setState(() => _message = 'Email not verified yet. Check your inbox.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _message = e.message ?? 'Could not refresh status');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      await context.read<AuthState>().sendEmailVerification();
      if (mounted) {
        setState(() => _message = 'Verification email sent.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _message = e.message ?? 'Could not send email');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthState>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final email = context.watch<AuthState>().user?.email ?? '';

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.03,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width > 600 ? 420 : size.width),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: size.width * 0.18,
                    color: colors.primary,
                  ),
                  SizedBox(height: size.height * 0.02),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: size.width * 0.055,
                    ),
                  ),
                  SizedBox(height: size.height * 0.012),
                  Text(
                    'We sent a verification link to',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: size.width * 0.035,
                    ),
                  ),
                  SizedBox(height: size.height * 0.006),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                      fontSize: size.width * 0.04,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.secondary,
                        fontSize: size.width * 0.033,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.06,
                    child: FilledButton(
                      onPressed: _checking ? null : _checkVerified,
                      child: _checking
                          ? SizedBox(
                              width: size.width * 0.05,
                              height: size.width * 0.05,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(
                              'I verified my email',
                              style: TextStyle(fontSize: size.width * 0.038),
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.06,
                    child: OutlinedButton(
                      onPressed: _resending ? null : _resend,
                      child: _resending
                          ? SizedBox(
                              width: size.width * 0.05,
                              height: size.width * 0.05,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            )
                          : Text(
                              'Resend verification email',
                              style: TextStyle(fontSize: size.width * 0.038),
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Use a different account',
                      style: TextStyle(fontSize: size.width * 0.035),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
