class UserModel {
  final String uid;
  final String phone;
  final String? name;
  final String? address;
  final String? email;
  final String? photoUrl;
  final bool isAdmin;
  final DateTime createdAt;

  // KYC Fields
  final String verificationStatus; // unverified, pending, verified, rejected
  final String? citizenshipFrontUrl;
  final String? citizenshipBackUrl;
  final String? selfieUrl;
  final String? rejectionReason;

  UserModel({
    required this.uid,
    required this.phone,
    this.name,
    this.address,
    this.email,
    this.photoUrl,
    this.isAdmin = false,
    required this.createdAt,
    this.verificationStatus = 'unverified',
    this.citizenshipFrontUrl,
    this.citizenshipBackUrl,
    this.selfieUrl,
    this.rejectionReason,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      phone: map['phone'] ?? '',
      name: map['name'],
      address: map['address'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      verificationStatus: map['verificationStatus'] ?? 'unverified',
      citizenshipFrontUrl: map['citizenshipFrontUrl'],
      citizenshipBackUrl: map['citizenshipBackUrl'],
      selfieUrl: map['selfieUrl'],
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'address': address,
      'email': email,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'verificationStatus': verificationStatus,
      'citizenshipFrontUrl': citizenshipFrontUrl,
      'citizenshipBackUrl': citizenshipBackUrl,
      'selfieUrl': selfieUrl,
      'rejectionReason': rejectionReason,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phone,
    String? name,
    String? address,
    String? email,
    String? photoUrl,
    bool? isAdmin,
    DateTime? createdAt,
    String? verificationStatus,
    String? citizenshipFrontUrl,
    String? citizenshipBackUrl,
    String? selfieUrl,
    String? rejectionReason,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      citizenshipFrontUrl: citizenshipFrontUrl ?? this.citizenshipFrontUrl,
      citizenshipBackUrl: citizenshipBackUrl ?? this.citizenshipBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
