class ApiError implements Exception {
  int statusCode;
  String message;
  List<dynamic> errors;
  dynamic data;
  bool success;

  ApiError({
    required this.statusCode,
    required this.message,
    this.data,
    this.errors = const [],
    this.success = false,
  });

  factory ApiError.fromMap(Map<String, dynamic> map) {
    return ApiError(
        statusCode: map['statusCode'] ?? 500,
        message: map['message'] ?? 'Unknown Error',
        data: map['data'],
        errors: map['errors'] ?? [],
        success: map['success'] ?? false);
  }
  Map<String, dynamic> toMap() {
    return {
      "statusCode": statusCode,
      "message": message,
      "data": data,
      "errors": errors,
      "success": success,
    };
  }
}
