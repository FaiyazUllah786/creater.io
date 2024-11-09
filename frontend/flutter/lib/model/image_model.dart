class ImageModel {
  String id;
  String publicId;
  String secureUrl;
  int height;
  int width;
  String author;
  DateTime createdAt;

  ImageModel(
      {required this.id,
      required this.publicId,
      required this.secureUrl,
      required this.height,
      required this.width,
      required this.author,
      required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "publicId": publicId,
      "secureUrl": secureUrl,
      "height": height,
      "width": width,
      "author": author,
      "createdAt": createdAt,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
        id: map["_id"],
        publicId: map['publicId'],
        secureUrl: map['secureUrl'],
        height: map['height'],
        width: map['width'],
        author: map['author'],
        createdAt: DateTime.parse(map['createdAt']));
  }
}
