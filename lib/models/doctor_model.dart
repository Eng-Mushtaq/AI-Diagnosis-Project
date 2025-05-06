// Doctor model for storing doctor information
class DoctorModel {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String city;
  final String profileImage;
  final double rating; // 0.0 to 5.0
  final int experience; // in years
  final String? about;
  final List<String>? languages;
  final List<String>? qualifications;
  final List<String>? availableDays;
  final Map<String, List<String>>? availableTimeSlots;
  final double consultationFee;
  final bool isAvailableForVideo;
  final bool isAvailableForChat;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.city,
    required this.profileImage,
    required this.rating,
    required this.experience,
    this.about,
    this.languages,
    this.qualifications,
    this.availableDays,
    this.availableTimeSlots,
    required this.consultationFee,
    required this.isAvailableForVideo,
    required this.isAvailableForChat,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'hospital': hospital,
      'city': city,
      'profileImage': profileImage,
      'rating': rating,
      'experience': experience,
      'about': about,
      'languages': languages,
      'qualifications': qualifications,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots,
      'consultationFee': consultationFee,
      'isAvailableForVideo': isAvailableForVideo,
      'isAvailableForChat': isAvailableForChat,
    };
  }

  // Create model from JSON
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      hospital: json['hospital'],
      city: json['city'],
      profileImage: json['profileImage'],
      rating: json['rating'].toDouble(),
      experience: json['experience'],
      about: json['about'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      qualifications: json['qualifications'] != null
          ? List<String>.from(json['qualifications'])
          : null,
      availableDays: json['availableDays'] != null
          ? List<String>.from(json['availableDays'])
          : null,
      availableTimeSlots: json['availableTimeSlots'] != null
          ? Map<String, List<String>>.from(
              json['availableTimeSlots'].map(
                (key, value) => MapEntry(
                  key,
                  List<String>.from(value),
                ),
              ),
            )
          : null,
      consultationFee: json['consultationFee'].toDouble(),
      isAvailableForVideo: json['isAvailableForVideo'],
      isAvailableForChat: json['isAvailableForChat'],
    );
  }

  // Get formatted consultation fee
  String get formattedConsultationFee {
    return 'SAR ${consultationFee.toStringAsFixed(2)}';
  }

  // Get formatted rating
  String get formattedRating {
    return rating.toStringAsFixed(1);
  }

  // Create a copy of the model with updated fields
  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialization,
    String? hospital,
    String? city,
    String? profileImage,
    double? rating,
    int? experience,
    String? about,
    List<String>? languages,
    List<String>? qualifications,
    List<String>? availableDays,
    Map<String, List<String>>? availableTimeSlots,
    double? consultationFee,
    bool? isAvailableForVideo,
    bool? isAvailableForChat,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      city: city ?? this.city,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      about: about ?? this.about,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      availableDays: availableDays ?? this.availableDays,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      consultationFee: consultationFee ?? this.consultationFee,
      isAvailableForVideo: isAvailableForVideo ?? this.isAvailableForVideo,
      isAvailableForChat: isAvailableForChat ?? this.isAvailableForChat,
    );
  }
}
