import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suvha_investment/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get isLoading =>
      FirebaseAuth.instance.currentUser != null &&
      _userModel == null &&
      _errorMessage == null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  UserProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    _userSub?.cancel();
    _userSub = null;

    if (user == null) {
      _userModel = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    _userSub = docRef.snapshots().listen(
      (snap) {
        if (!snap.exists || snap.data() == null) {
          _userModel = null;
          _errorMessage = 'User profile not found. Contact support.';
          notifyListeners();
          return;
        }
        _userModel = UserModel.fromMap(snap.data()!, user.uid);
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error listening to user: $e');
        _userModel = null;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> submitKYC({
    required File citizenshipFront,
    required File citizenshipBack,
    required File selfie,
  }) async {
    if (_userModel == null) {
      throw StateError('No user profile loaded');
    }

    final uid = _userModel!.uid;
    final uidRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final frontBase64 = base64Encode(await citizenshipFront.readAsBytes());
    final backBase64 = base64Encode(await citizenshipBack.readAsBytes());
    final selfieBase64 = base64Encode(await selfie.readAsBytes());

    await uidRef.update({'verificationStatus': 'pending'});

    await uidRef.collection('kyc').doc('front').set({
      'data': frontBase64,
      'mimeType': 'image/jpeg',
    });

    await uidRef.collection('kyc').doc('back').set({
      'data': backBase64,
      'mimeType': 'image/jpeg',
    });

    await uidRef.collection('kyc').doc('selfie').set({
      'data': selfieBase64,
      'mimeType': 'image/jpeg',
    });

    _userModel = _userModel!.copyWith(verificationStatus: 'pending');
    notifyListeners();
  }

  Future<void> updateKYCStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) async {
    if (!isAdmin) {
      throw StateError('Only admins can update KYC status');
    }

    final updates = <String, dynamic>{'verificationStatus': status};
    if (rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);

    if (_userModel?.uid == uid) {
      _userModel = _userModel!.copyWith(
        verificationStatus: status,
        rejectionReason: rejectionReason,
      );
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? address,
    String? email,
  }) async {
    if (_userModel == null) {
      throw StateError('No user profile loaded');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (email != null) updates['email'] = email;

    if (updates.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userModel!.uid)
        .update(updates);

    _userModel = _userModel!.copyWith(
      name: name,
      address: address,
      email: email,
    );
    notifyListeners();
  }
}
