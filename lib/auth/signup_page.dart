import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'auth_validators.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'Male';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _genders = const ['Male', 'Female', 'Others'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final onlyDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullPhone = '+977$onlyDigits';

    setState(() => _loading = true);

    UserCredential? cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'phone': fullPhone,
        'email': email,
        'gender': _gender,
        'isAdmin': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'verificationStatus': 'unverified',
      });

      await cred.user!.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Verify your email to continue.'),
        ),
      );
      // Router sends unverified users to verify-email.
    } on FirebaseAuthException catch (e) {
      if (cred?.user != null) {
        await cred!.user!.delete();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthValidators.signupErrorMessage(e.code))),
      );
    } on FirebaseException catch (e) {
      if (cred?.user != null) {
        await cred!.user!.delete();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not create profile')),
      );
    } catch (_) {
      if (cred?.user != null) {
        await cred!.user!.delete();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
              vertical: h * 0.025,
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
                      width: w * 0.22,
                      height: w * 0.22,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: h * 0.01),
                    Text(
                      'Create Account',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                        fontSize: w * 0.05,
                      ),
                    ),
                    SizedBox(height: h * 0.025),
                    Card(
                      elevation: 0,
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.04),
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(w * 0.05),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: AuthValidators.name,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(Icons.person_outline, size: w * 0.055),
                              ),
                            ),
                            SizedBox(height: h * 0.018),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: AuthValidators.phoneNepal,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixText: '+977 ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(Icons.phone_outlined, size: w * 0.055),
                              ),
                            ),
                            SizedBox(height: h * 0.018),
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
                                prefixIcon: Icon(Icons.email_outlined, size: w * 0.055),
                              ),
                            ),
                            SizedBox(height: h * 0.018),
                            DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(Icons.people_outline, size: w * 0.055),
                              ),
                              items: _genders
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _gender = v);
                              },
                            ),
                            SizedBox(height: h * 0.018),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: AuthValidators.password,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                helperText: '8+ chars, upper, lower, number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(Icons.lock_outline, size: w * 0.055),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: w * 0.055,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.018),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (v) => AuthValidators.confirmPassword(
                                v,
                                _passwordController.text,
                              ),
                              onFieldSubmitted: (_) => _signup(),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(w * 0.03),
                                ),
                                prefixIcon: Icon(Icons.lock_outline, size: w * 0.055),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: w * 0.055,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.025),
                            SizedBox(
                              width: double.infinity,
                              height: h * 0.06,
                              child: FilledButton(
                                onPressed: _loading ? null : _signup,
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
                                        'Sign Up',
                                        style: TextStyle(fontSize: w * 0.04),
                                      ),
                              ),
                            ),
                            SizedBox(height: h * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    fontSize: w * 0.033,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: Text(
                                    'Sign In',
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
