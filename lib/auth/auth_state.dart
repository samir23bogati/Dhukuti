import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthPhase {
  initializing,
  signedOut,
  emailUnverified,
  signedIn,
}

class AuthState extends ChangeNotifier {
  AuthState({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen(_applyUser);
  }

  final FirebaseAuth _auth;
  StreamSubscription<User?>? _subscription;

  AuthPhase phase = AuthPhase.initializing;
  User? user;

  bool get isLoggedIn => user != null;
  bool get isEmailVerified => user?.emailVerified == true;

  void _applyUser(User? next) {
    user = next;
    if (next == null) {
      phase = AuthPhase.signedOut;
    } else if (!next.emailVerified) {
      phase = AuthPhase.emailUnverified;
    } else {
      phase = AuthPhase.signedIn;
    }
    notifyListeners();
  }

  Future<void> reloadUser() async {
    final current = _auth.currentUser;
    if (current == null) {
      _applyUser(null);
      return;
    }
    await current.reload();
    _applyUser(_auth.currentUser);
  }

  Future<void> sendEmailVerification() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user',
      );
    }
    await current.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
