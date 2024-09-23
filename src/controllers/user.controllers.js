import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";

export const registerUser = asyncHandler(async (req, res) => {
  const { userName, email, password, firstName, lastName } = req.body;
  if (!userName || userName.trim() === "") {
    throw new ApiError(400, "Username is required");
  } else if (email.trim() === "") {
    throw new ApiError(400, "Email is required");
  } else if (password.trim() === "") {
    throw new ApiError(400, "Password is required");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, { message: "Everthing is working" }));
});
