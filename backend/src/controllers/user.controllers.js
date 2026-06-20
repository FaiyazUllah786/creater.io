import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { User } from "../models/user.model.js";
import { uploadOnCloudinary } from "../services/cloudinary/cloudinary.js";
import { generateAccessRefreshToken } from "../middlewares/auth.middleware.js";

export const registerUser = asyncHandler(async (req, res) => {
  const { userName, email, password, firstName, lastName } = req.body;

  if (!userName || userName.trim() === "") {
    throw new ApiError(422, "Username is required");
  }
  if (!email || email.trim() === "") {
    throw new ApiError(422, "Email is required");
  }

  // Basic email format validation and block reserved OAuth synthetic domains
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new ApiError(422, "Invalid email format");
  }
  const reservedDomains = ["github.user", "google.user"];
  const emailDomain = email.split("@")[1]?.toLowerCase();
  if (reservedDomains.includes(emailDomain)) {
    throw new ApiError(422, "This email domain is not allowed for registration");
  }

  if (!password || password.trim() === "") {
    throw new ApiError(422, "Password is required");
  }

  const existedUsername = await User.findOne({ userName });
  if (existedUsername) {
    throw new ApiError(409, "Username is already taken");
  }

  const existedEmail = await User.findOne({ email });
  if (existedEmail) {
    throw new ApiError(409, "An account with this email already exists");
  }

  const profilePhotoLocalPath = req.file?.path;
  let profilePhoto = "";

  if (profilePhotoLocalPath) {
    const imageUploadResponse = await uploadOnCloudinary(profilePhotoLocalPath);
    if (!imageUploadResponse) {
      throw new ApiError(502, "Failed to upload profile photo");
    }
    profilePhoto = imageUploadResponse.url;
  }

  const newUser = await User.create({
    userName,
    email,
    password,
    profilePhoto,
    firstName,
    lastName,
  });

  const userWithoutPass = await User.findById(newUser._id).select("-password");

  return res
    .status(201)
    .json(new ApiResponse(201, userWithoutPass, "Account created successfully"));
});

export const loginUser = asyncHandler(async (req, res) => {
  const { userName, email, password } = req.body;

  if ((!userName || userName.trim() === "") && (!email || email.trim() === "")) {
    throw new ApiError(422, "Username or email is required");
  }
  if (!password || password.trim() === "") {
    throw new ApiError(422, "Password is required");
  }

  const existedUser = await User.findOne({ $or: [{ userName }, { email }] });
  if (!existedUser) {
    throw new ApiError(404, "No account found with the provided credentials");
  }

  const checkPassword = await existedUser.isPasswordCorrect(password);
  if (!checkPassword) {
    throw new ApiError(400, "Incorrect password");
  }

  const { accessToken, refreshToken } = await generateAccessRefreshToken(existedUser._id);

  const loggedInUser = await User.findById(existedUser._id).select("-password -refreshToken");

  const opts = {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
  };

  return res
    .status(200)
    .cookie("accessToken", accessToken, opts)
    .cookie("refreshToken", refreshToken, opts)
    .json(new ApiResponse(200, { user: loggedInUser, accessToken, refreshToken }, "Logged in successfully"));
});

export const logoutUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  user.refreshToken = null;
  await user.save({ validateBeforeSave: false });

  const opts = {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
  };

  return res
    .status(200)
    .clearCookie("accessToken", opts)
    .clearCookie("refreshToken", opts)
    .json(new ApiResponse(200, {}, "Logged out successfully"));
});

export const getCurrentUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id).select("-refreshToken -password");
  if (!user) {
    throw new ApiError(404, "User not found");
  }
  return res.status(200).json(new ApiResponse(200, user, "User retrieved successfully"));
});

export const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  await user.deleteOne();

  return res
    .status(200)
    .clearCookie("accessToken")
    .clearCookie("refreshToken")
    .json(new ApiResponse(200, {}, "Account deleted successfully"));
});

export const updateUserProfilePhoto = asyncHandler(async (req, res) => {
  const profilePhotoLocalPath = req.file?.path;
  if (!profilePhotoLocalPath) {
    throw new ApiError(422, "Profile photo is required");
  }

  const uploadProfilePhotoRes = await uploadOnCloudinary(profilePhotoLocalPath);
  if (!uploadProfilePhotoRes) {
    throw new ApiError(502, "Failed to upload profile photo");
  }

  const user = await User.findByIdAndUpdate(
    req._id,
    { profilePhoto: uploadProfilePhotoRes.url },
    { new: true }
  ).select("-password -refreshToken");

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  return res.status(200).json(new ApiResponse(200, user, "Profile photo updated successfully"));
});

export const updateUserProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const { userName, email, firstName, lastName } = req.body;

  if (userName && userName.trim() !== "") {
    const existedUserName = await User.findOne({ userName });
    if (existedUserName && existedUserName.userName !== user.userName) {
      throw new ApiError(409, "Username is already taken");
    }
  }

  if (email && email.trim() !== "") {
    const existedEmail = await User.findOne({ email });
    if (existedEmail && existedEmail.email !== user.email) {
      throw new ApiError(409, "Email is already associated with another account");
    }
  }

  await user.updateOne({
    userName: userName || user.userName,
    email: email || user.email,
    firstName: firstName || user.firstName,
    lastName: lastName || user.lastName,
  });

  const updatedUser = await User.findById(req._id).select("-password -refreshToken");

  return res.status(200).json(new ApiResponse(200, updatedUser, "Profile updated successfully"));
});

export const updatePassword = asyncHandler(async (req, res) => {
  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || oldPassword.trim() === "") {
    throw new ApiError(422, "Current password is required");
  }
  if (!newPassword || newPassword.trim() === "") {
    throw new ApiError(422, "New password is required");
  }

  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const checkPassword = await user.isPasswordCorrect(`${oldPassword}`);
  if (!checkPassword) {
    throw new ApiError(400, "Current password is incorrect");
  }

  user.password = newPassword;
  await user.save({ validateBeforeSave: false });

  return res.status(200).json(new ApiResponse(200, {}, "Password updated successfully"));
});
