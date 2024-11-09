class ApiResponse extends Error {
  int statusCode;
  String message;
  bool success;
  dynamic data;

  ApiResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.success,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
        statusCode: map['statusCode'],
        message: map['message'],
        data: map['data'],
        success: map['success']);
  }

  Map<String, dynamic> toMap() {
    return {
      "statusCode": statusCode,
      "message": message,
      "data": data,
      "success": success,
    };
  }
}
