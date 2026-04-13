class UserModel {
  String userName;
  String email;
  String? profilePhoto;
  String? firstName;
  String? lastName;
  DateTime createdAt;
  DateTime updatedAt;
  String authProvider;
  String? githubId;
  String? googleId;

  UserModel(
      {required this.userName,
      required this.email,
      this.profilePhoto,
      this.firstName,
      this.lastName,
      required this.createdAt,
      required this.updatedAt,
      required this.authProvider,
      this.githubId,
      this.googleId});

  Map<String, dynamic> toMap() {
    return {
      "userName": userName,
      "email": email,
      "profilePhoto": profilePhoto,
      "firstName": firstName,
      "lastName": lastName,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "authProvider": authProvider,
      "githubId": githubId,
      "googleId": googleId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userName: map['userName'],
      email: map['email'],
      profilePhoto: map['profilePhoto'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      authProvider: map['authProvider'],
      githubId: map['githubId'],
      googleId: map['googleId'],
    );
  }
}
