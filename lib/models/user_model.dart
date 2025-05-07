// Enum for user types
enum UserType { patient, doctor, admin }

// Base user model for all user types
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final UserType userType;

  // Patient-specific fields
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final List<String>? medications;

  // Doctor-specific fields
  final String? specialization;
  final String? hospital;
  final String? licenseNumber;
  final int? experience; // in years
  final List<String>? qualifications;
  final bool? isAvailableForChat;
  final bool? isAvailableForVideo;
  final String? verificationStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime? verificationDate;
  final String? verifiedBy;

  // Admin-specific fields
  final String? adminRole; // e.g., "super_admin", "content_admin", etc.
  final List<String>? permissions;

  // Doctor-patient relationship fields
  final String? relationshipType; // 'primary', 'specialist', 'consultant'
  final String? relationshipNotes;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.userType,
    // Patient fields
    this.age,
    this.gender,
    this.bloodGroup,
    this.height,
    this.weight,
    this.allergies,
    this.chronicConditions,
    this.medications,
    // Doctor fields
    this.specialization,
    this.hospital,
    this.licenseNumber,
    this.experience,
    this.qualifications,
    this.isAvailableForChat,
    this.isAvailableForVideo,
    this.verificationStatus,
    this.rejectionReason,
    this.verificationDate,
    this.verifiedBy,
    // Admin fields
    this.adminRole,
    this.permissions,
    // Relationship fields
    this.relationshipType,
    this.relationshipNotes,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType.toString().split('.').last, // Convert enum to string
    };

    // Add patient fields if present
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (bloodGroup != null) data['bloodGroup'] = bloodGroup;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (allergies != null) data['allergies'] = allergies;
    if (chronicConditions != null) {
      data['chronicConditions'] = chronicConditions;
    }
    if (medications != null) data['medications'] = medications;

    // Add doctor fields if present
    if (specialization != null) data['specialization'] = specialization;
    if (hospital != null) data['hospital'] = hospital;
    if (licenseNumber != null) data['licenseNumber'] = licenseNumber;
    if (experience != null) data['experience'] = experience;
    if (qualifications != null) data['qualifications'] = qualifications;
    if (isAvailableForChat != null) {
      data['isAvailableForChat'] = isAvailableForChat;
    }
    if (isAvailableForVideo != null) {
      data['isAvailableForVideo'] = isAvailableForVideo;
    }
    if (verificationStatus != null) {
      data['verificationStatus'] = verificationStatus;
    }
    if (rejectionReason != null) {
      data['rejectionReason'] = rejectionReason;
    }
    if (verificationDate != null) {
      data['verificationDate'] = verificationDate!.toIso8601String();
    }
    if (verifiedBy != null) {
      data['verifiedBy'] = verifiedBy;
    }

    // Add admin fields if present
    if (adminRole != null) data['adminRole'] = adminRole;
    if (permissions != null) data['permissions'] = permissions;

    // Add relationship fields if present
    if (relationshipType != null) data['relationshipType'] = relationshipType;
    if (relationshipNotes != null) {
      data['relationshipNotes'] = relationshipNotes;
    }

    return data;
  }

  // Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse user type from string
    UserType userType = UserType.values.firstWhere(
      (e) => e.toString().split('.').last == json['userType'],
      orElse: () => UserType.patient, // Default to patient if not found
    );

    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      userType: userType,
      // Patient fields
      age: json['age'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      allergies:
          json['allergies'] != null
              ? List<String>.from(json['allergies'])
              : null,
      chronicConditions:
          json['chronicConditions'] != null
              ? List<String>.from(json['chronicConditions'])
              : null,
      medications:
          json['medications'] != null
              ? List<String>.from(json['medications'])
              : null,
      // Doctor fields
      specialization: json['specialization'],
      hospital: json['hospital'],
      licenseNumber: json['licenseNumber'],
      experience: json['experience'],
      qualifications:
          json['qualifications'] != null
              ? List<String>.from(json['qualifications'])
              : null,
      isAvailableForChat: json['isAvailableForChat'],
      isAvailableForVideo: json['isAvailableForVideo'],
      verificationStatus: json['verificationStatus'],
      rejectionReason: json['rejectionReason'],
      verificationDate:
          json['verificationDate'] != null
              ? DateTime.parse(json['verificationDate'])
              : null,
      verifiedBy: json['verifiedBy'],
      // Admin fields
      adminRole: json['adminRole'],
      permissions:
          json['permissions'] != null
              ? List<String>.from(json['permissions'])
              : null,
      // Relationship fields
      relationshipType: json['relationshipType'],
      relationshipNotes: json['relationshipNotes'],
    );
  }

  // Create a copy of the model with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    UserType? userType,
    // Patient fields
    int? age,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? medications,
    // Doctor fields
    String? specialization,
    String? hospital,
    String? licenseNumber,
    int? experience,
    List<String>? qualifications,
    bool? isAvailableForChat,
    bool? isAvailableForVideo,
    String? verificationStatus,
    String? rejectionReason,
    DateTime? verificationDate,
    String? verifiedBy,
    // Admin fields
    String? adminRole,
    List<String>? permissions,
    // Relationship fields
    String? relationshipType,
    String? relationshipNotes,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      // Patient fields
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      medications: medications ?? this.medications,
      // Doctor fields
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      isAvailableForChat: isAvailableForChat ?? this.isAvailableForChat,
      isAvailableForVideo: isAvailableForVideo ?? this.isAvailableForVideo,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verificationDate: verificationDate ?? this.verificationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      // Admin fields
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      // Relationship fields
      relationshipType:
          relationshipType ??
          (additionalData != null
              ? additionalData['relationshipType']
              : this.relationshipType),
      relationshipNotes:
          relationshipNotes ??
          (additionalData != null
              ? additionalData['relationshipNotes']
              : this.relationshipNotes),
    );
  }
}
