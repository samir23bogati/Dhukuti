import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get isLoading => _userModel == null && _errorMessage == null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<DocumentSnapshot>? _userSub;
  bool _consolidated = false;

  UserProvider() {
    _init();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      _userSub = null;
      _consolidated = false;

      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        docRef.get().then((snap) {
          if (!snap.exists) {
            docRef.set(
              UserModel(
                uid: user.uid,
                phone: user.phoneNumber ?? '',
                createdAt: DateTime.now(),
                isAdmin: false,
              ).toMap(),
            );
          }
        });

        _userSub = docRef.snapshots().listen(
          (snap) {
            if (snap.exists) {
              _userModel = UserModel.fromMap(snap.data()!, user.uid);
              _consolidateOrphanedData(user.uid);
            }
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error listening to user: $e");
            _errorMessage = e.toString();
            notifyListeners();
          },
        );
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> _consolidateOrphanedData(String uid) async {
    if (_consolidated || _userModel == null) return;
    final user = _userModel!;

    final hasMissingFields =
        (user.email == null || user.email!.isEmpty) ||
        (user.phone.isEmpty) ||
        user.gender == null;
    if (!hasMissingFields) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: user.name)
          .get();

      DocumentReference? sourceRef;
      Map<String, dynamic>? sourceData;

      for (final doc in query.docs) {
        if (doc.id == uid) continue;
        final kycSnap = await doc.reference.collection('kyc').get();
        if (kycSnap.docs.isNotEmpty) {
          sourceRef = doc.reference;
          sourceData = doc.data();
          break;
        }
      }

      if (sourceRef == null || sourceData == null) return;

      _consolidated = true;

      final kycDocs = await sourceRef.collection('kyc').get();
      for (final kycDoc in kycDocs.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('kyc')
            .doc(kycDoc.id)
            .set(kycDoc.data());
      }

      final updates = <String, dynamic>{};
      if (user.email == null || user.email!.isEmpty) {
        updates['email'] = sourceData['email'];
      }
      if (user.phone.isEmpty) {
        updates['phone'] = sourceData['phone'];
      }
      if (user.gender == null) {
        updates['gender'] = sourceData['gender'];
      }
      updates['verificationStatus'] = 'pending';
      updates.removeWhere((_, v) => v == null);

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);
      }

      debugPrint("Consolidated KYC data from $uid into current account");
    } catch (e) {
      debugPrint("Consolidation error: $e");
    }
  }

  Future<void> submitKYC({
    required File citizenshipFront,
    required File citizenshipBack,
    required File selfie,
  }) async {
    if (_userModel == null) return;

    try {
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
      final updates = <String, dynamic>{'verificationStatus': status};
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
