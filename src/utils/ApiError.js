class ApiError extends Error {
  constructor(
    statusCode,
    message = "Something went wrong",
    errors = [],
    errorStackTrace = "",
  ) {
    super(message);
    this.message = message;
    this.statusCode = statusCode;
    this.data = null;
    this.errors = errors;
    this.success = false;

    if (errorStackTrace) {
      this.stack = errorStackTrace;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

export { ApiError };
