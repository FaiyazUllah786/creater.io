class ApiError extends Error {
  constructor(
    statusCode,
    message = "Something Went Wrong",
    errors = [],
    errorStackTrace = "",
  ) {
    super(message);
    this.message = message;
    this.statusCode = statusCode;
    this.data = null;
    this.success = false;
    this.errors = errors;

    if (errorStackTrace) {
      this.stack = errorStackTrace;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

export { ApiError };
