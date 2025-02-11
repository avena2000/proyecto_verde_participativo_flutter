class UserAccess {
  final String id;
  final String username;
  final bool isPersonalInformation;

  UserAccess({
    required this.id,
    required this.username,
    required this.isPersonalInformation,
  });


  factory UserAccess.fromJson(Map<String, dynamic> json) {
    return UserAccess(
      id: json['id'],
      username: json['username'],
      isPersonalInformation: json['is_personal_information'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_personal_information': isPersonalInformation,
    };
  }
}