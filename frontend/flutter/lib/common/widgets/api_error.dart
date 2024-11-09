class ApiError extends Error {
  int statusCode;
  String message;
  List<dynamic> errors;
  dynamic data;
  bool success;

  ApiError({
    required this.statusCode,
    required this.message,
    this.data = null,
    this.errors = const [],
    this.success = false,
  });

  factory ApiError.fromMap(Map<String, dynamic> map) {
    return ApiError(
        statusCode: map['statusCode'],
        message: map['message'],
        data: map['data'],
        errors: map['errors'],
        success: map['success']);
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
