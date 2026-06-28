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
        statusCode: map['statusCode'] ?? 200,
        message: map['message'] ?? 'Success',
        data: map['data'],
        success: map['success'] ?? true);
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
