import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get isLoading => _userModel == null && _errorMessage == null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserDetails(user);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserDetails(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!, user.uid);
      } else {
        final newUser = UserModel(
          uid: user.uid,
          phone: user.phoneNumber ?? '',
          createdAt: DateTime.now(),
          isAdmin: false,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());

        _userModel = newUser;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitKYC({
    required File citizenshipFront,
    required File citizenshipBack,
    required File selfie,
  }) async {
    if (_userModel == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final uid = _userModel!.uid;

      final frontRef = storageRef.child('kyc/$uid/citizenship_front.jpg');
      final backRef = storageRef.child('kyc/$uid/citizenship_back.jpg');
      final selfieRef = storageRef.child('kyc/$uid/selfie.jpg');

      await frontRef.putFile(citizenshipFront);
      await backRef.putFile(citizenshipBack);
      await selfieRef.putFile(selfie);

      final frontUrl = await frontRef.getDownloadURL();
      final backUrl = await backRef.getDownloadURL();
      final selfieUrl = await selfieRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'verificationStatus': 'pending',
        'citizenshipFrontUrl': frontUrl,
        'citizenshipBackUrl': backUrl,
        'selfieUrl': selfieUrl,
      });

      _userModel = _userModel!.copyWith(
        verificationStatus: 'pending',
        citizenshipFrontUrl: frontUrl,
        citizenshipBackUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting KYC: $e");
      rethrow;
    }
  }

  Future<void> updateKYCStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'verificationStatus': status,
      };
      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updates);

      if (_userModel?.uid == uid) {
        _userModel = _userModel!.copyWith(
          verificationStatus: status,
          rejectionReason: rejectionReason,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating KYC status: $e");
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? address,
    String? email,
  }) async {
    if (_userModel == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (email != null) updates['email'] = email;

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
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }
}
