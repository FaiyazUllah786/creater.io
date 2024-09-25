import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { User } from "../models/user.model.js";
import { uploadImage } from "../utils/cloudinary.js";
import { generateAccessRefreshToken } from "../middlewares/auth.middleware.js";

export const registerUser = asyncHandler(async (req, res) => {
  //Take data from frontend
  const { userName, email, password, firstName, lastName } = req.body;
  if (!userName || userName.trim() === "") {
    throw new ApiError(400, "Username is required");
  } else if (!email || email.trim() === "") {
    throw new ApiError(400, "Email is required");
  } else if (!password || password.trim() === "") {
    throw new ApiError(400, "Password is required");
  }

  //validate data
  const existedUser = await User.findOne({
    $or: [{ userName }, { email }],
  });
  console.log(existedUser);
  const existedUsername = await User.findOne({ userName });
  console.log(existedUsername);
  const existedEmail = await User.findOne({ email });
  console.log(existedEmail);
  if (existedUser) {
    throw new ApiError(401, "User already exists");
  } else if (existedUsername) {
    throw new ApiError(401, "Username already exists");
  } else if (existedEmail) {
    throw new ApiError(401, "Email already exists");
  }
  //Take profile Photo from req.files
  console.log("i am here");
  const profilePhotoLocalPath = req.file?.path;
  console.log("i am here also");
  console.log(profilePhotoLocalPath);

  //validate profile photo path
  if (!profilePhotoLocalPath) {
    throw new ApiError(400, "Profile photo is required");
  }

  //upload photo to cloudinary
  const imageUploadResponse = await uploadImage(profilePhotoLocalPath);
  if (!imageUploadResponse) {
    throw new ApiError(400, "Something went wrong du");
  }
  console.log("image upload on cloudinary:", imageUploadResponse);
  //validate updload
  //*************Validation of upload is happening in cloudinary upload*************
  const profilePhoto = imageUploadResponse.url;

  //register user in database
  const newUser = await User.create({
    userName,
    email,
    password,
    profilePhoto,
    firstName,
    lastName,
  });

  console.log("User created:", newUser);
  return res
    .status(200)
    .json(new ApiResponse(200, newUser, "User registered successfully"));
});

export const loginUser = asyncHandler(async (req, res) => {
  //take userName or email and password from frontend
  const { userName, email, password } = req.body;

  //validate userName or email and password
  if ((!userName || userName.trim() == "") && (!email || email.trim() == "")) {
    throw new ApiError(400, "Username or Email is required");
  }

  if (!password || password.trim() == "") {
    throw new ApiError(400, "Password is required");
  }

  //find user based on userName or email
  const existedUser = await User.findOne({
    $or: [{ userName }, { email }],
  });

  //validate user
  if (!existedUser) {
    throw new ApiError(400, "User does not exist");
  }
  //validate user password
  const checkPassword = await existedUser.isPasswordCorrect(password);
  if (!checkPassword) {
    throw new ApiError(400, "Password is incorrect");
  }

  //generate access and refresh token
  const { accessToken, refreshToken } = await generateAccessRefreshToken(
    existedUser._id
  );

  //update login user refresh token
  //***********updating user database is done on  generateAccessRefreshToken func **************
  const udpatedUser = await User.findById(existedUser._id).select(
    "-password -refreshToken"
  );
  //store access and refresh token to cookie storage
  const opts = {
    httpOnly: true,
    secure: true,
  };
  return res
    .status(200)
    .cookie("accessToken", accessToken, opts)
    .cookie("refreshToken", refreshToken, opts)
    .json(
      new ApiResponse(
        200,
        { udpatedUser, accessToken, refreshToken },
        "User successfully logged in"
      )
    );
});

export const getCurrentUser = asyncHandler(async (req, res) => {
  //get current user id by verifying jwt of current session
  const user = await User.findById(req._id).select("-refreshToken -password");
  if (!user) {
    throw new ApiError(400, "User not found");
  }
  return res.status(200).json(new ApiResponse(200, user, "User found"));
});

export const deleteUser = asyncHandler(async (req, res) => {
  //take id from frontend
  const user = await User.findById(req._id);

  //validate user
  if (!user) {
    throw new ApiError(400, "user is required");
  }

  //delete user
  const deletedUser = await user.deleteOne();
  if (!deletedUser) {
    throw new ApiError(400, "Something went wrong while deleting account");
  }
  console.log(deletedUser);

  return res
    .status(200)
    .clearCookie("accessToken")
    .clearCookie("refreshToken")
    .json(
      new ApiResponse(200, { deletedUser }, "User account deleted successfully")
    );
});
