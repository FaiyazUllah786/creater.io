class UserModel {
  String userName;
  String email;
  String profilePhoto;
  String? firstName;
  String? lastName;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserModel(
      {required this.userName,
      required this.email,
      required this.profilePhoto,
      this.firstName,
      this.lastName,
      this.createdAt,
      this.updatedAt});

  Map<String, dynamic> toMap() {
    return {
      "userName": userName,
      "email": email,
      "profilePhoto": profilePhoto,
      "firstName": firstName,
      "lastName": lastName,
      "createdAt": createdAt,
      "updateAt": updatedAt
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
        updatedAt: DateTime.parse(map['updatedAt']));
  }
}
