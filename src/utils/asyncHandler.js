import { ApiError } from "./ApiError.js";
export const asyncHandler = (requestHandler) => {
  return (req, res, next) => {
    Promise.resolve(requestHandler(req, res, next)).catch((err) => {
      if (err instanceof ApiError) {
        res.status(err.statusCode).json({
          statusCode: err.statusCode,
          message: err.message,
          data: err.data,
          success: err.success,
          errors: err.errors,
        });
      } else {
        // Handle unexpected errors
        res.status(500).json({
          statusCode: 500,
          message: "Internal Server Error",
          success: false,
          errors: [err.message || "Unknown error occurred"],
        });
      }
      next();
    });
  };
};
