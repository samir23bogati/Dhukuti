class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? phoneNepal(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    if (!digits.startsWith('9')) return 'Enter a valid Nepal mobile number';
    return null;
  }

  static String? password(String? value, {bool requireStrong = true}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (!requireStrong) {
      if (v.length < 6) return 'Password must be at least 6 characters';
      return null;
    }
    if (!_passwordRegex.hasMatch(v)) {
      return 'Use 8+ chars with upper, lower, and a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// Single message for login failures — avoids account enumeration.
  static String loginErrorMessage(String code) {
    switch (code) {
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Invalid email or password';
    }
  }

  static String signupErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      default:
        return 'Registration failed. Please try again.';
    }
  }
}
