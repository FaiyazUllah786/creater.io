import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { User } from "../models/user.model.js";
import { uploadOnCloudinary } from "../services/cloudinary/cloudinary.js";
import { generateAccessRefreshToken } from "../middlewares/auth.middleware.js";
import fs from "fs";

export const registerUser = asyncHandler(async (req, res) => {
  try {
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
      $and: [{ userName }, { email }],
    });
    const existedUsername = await User.findOne({ userName });
    const existedEmail = await User.findOne({ email });
    if (existedUser) {
      throw new ApiError(401, "User already exists");
    } else if (existedUsername) {
      throw new ApiError(401, "Username already exists");
    } else if (existedEmail) {
      throw new ApiError(401, "Email already exists");
    }
    //Take profile Photo from req.files
    const profilePhotoLocalPath = req.file?.path;
    console.log(profilePhotoLocalPath);

    //validate profile photo path
    if (!profilePhotoLocalPath) {
      throw new ApiError(400, "Profile photo is required");
    }

    //upload photo to cloudinary
    const imageUploadResponse = await uploadOnCloudinary(profilePhotoLocalPath);
    if (!imageUploadResponse) {
      throw new ApiError(400, "Something went wrong during image upload");
    }
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
    const userWithoutPass = await User.findById(newUser._id).select(
      "-password"
    );

    console.log("User created:", newUser);
    return res
      .status(200)
      .json(
        new ApiResponse(200, userWithoutPass, "User registered successfully")
      );
  } catch (error) {
    console.log("Something went wrong during user registration", error);
    throw error;
  }
});

export const loginUser = asyncHandler(async (req, res) => {
  try {
    //take userName or email and password from frontend
    const { userName, email, password } = req.body;
    //validate userName or email and password
    if (
      (!userName || userName.trim() == "") &&
      (!email || email.trim() == "")
    ) {
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
    const loggedInUser = await User.findById(existedUser._id).select(
      "-password -refreshToken"
    );
    //store access and refresh token to cookie storage
    const opts = {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production", // only HTTPS in prod
      sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
    };
    return res
      .status(200)
      .cookie("accessToken", accessToken, opts)
      .cookie("refreshToken", refreshToken, opts)
      .json(
        new ApiResponse(
          200,
          { loggedInUser, accessToken, refreshToken },
          "User successfully logged in"
        )
      );
  } catch (error) {
    console.log("Something went wrong during user login", error);
    throw error;
  }
});

export const logoutUser = asyncHandler(async (req, res) => {
  try {
    //fetch user using userid
    const user = await User.findById(req._id);
    //validate user
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    //delete refresh token from user database
    user.refreshToken = null;
    await user.save({ validateBeforeSave: false });
    //reset cookies
    const opts = {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production", // only HTTPS in prod
      sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
    };
    return res
      .status(200)
      .clearCookie("accessToken", opts)
      .clearCookie("refreshToken", opts)
      .json(new ApiResponse(200, {}, "user logout successfully"));
  } catch (error) {
    console.log("Something went wrong during user logout", error);
    throw error;
  }
});

export const getCurrentUser = asyncHandler(async (req, res) => {
  try {
    //get current user id by verifying jwt of current session
    const user = await User.findById(req._id).select("-refreshToken -password");
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    return res.status(200).json(new ApiResponse(200, user, "User found"));
  } catch (error) {
    console.log("Something went wrong during current user fetch", error);
    throw error;
  }
});

export const deleteUser = asyncHandler(async (req, res) => {
  try {
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
        new ApiResponse(
          200,
          { deletedUser },
          "User account deleted successfully"
        )
      );
  } catch (error) {
    console.log("Something went wrong during user account deletion", error);
    throw error;
  }
});

export const updateUserProfilePhoto = asyncHandler(async (req, res) => {
  try {
    //take profile photo from frontend
    const profilePhotoLocalPath = req.file?.path;
    console.log(profilePhotoLocalPath);
    //validate profile photo
    if (!profilePhotoLocalPath) {
      throw new ApiError(400, "Proflie photo is missing");
    }
    //upload new profile photo to cloudinary
    const uploadProfilePhotoRes = await uploadOnCloudinary(
      profilePhotoLocalPath
    );
    //validate response
    if (!uploadProfilePhotoRes) {
      throw new ApiError(
        400,
        "Something went wrong during profile photo update"
      );
    }
    // fetch currentUser profile and update user profilephoto
    const profilePhoto = uploadProfilePhotoRes.url;
    const user = await User.findByIdAndUpdate(
      req._id,
      {
        profilePhoto,
      },
      {
        new: true,
      }
    ).select("-password -refreshToken");
    //validate current user
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    return res
      .status(200)
      .json(new ApiResponse(200, user, "Profile photo updated successfully"));
  } catch (error) {
    console.log("Something went wrong during user profile photo update", error);
    throw error;
  }
});

export const updateUserProfile = asyncHandler(async (req, res) => {
  try {
    //get the previous data of user
    const user = await User.findById(req._id);
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    //get all or any update data from frontend
    const { userName, email, firstName, lastName } = req.body;
    console.log(userName, email, firstName, lastName);
    //validate data
    //1.validate userName with database
    if (userName && userName.trim() != "") {
      const existedUserName = await User.findOne({ userName });
      if (existedUserName && existedUserName.userName != user.userName) {
        throw new ApiError(400, "UserName already exists");
      }
    }
    //2.validate email
    if (email && email.trim() != "") {
      const existedEmail = await User.findOne({ email });
      if (existedEmail && existedEmail.email != user.email) {
        throw new ApiError(400, "Email already exist");
      }
    }
    //update user
    await user.updateOne({
      userName: userName || user.userName,
      email: email || user.email,
      firstName: firstName || user.firstName,
      lastName: lastName || user.lastName,
    });

    const updatedUser = await User.findById(req._id).select(
      "-password -refreshToken"
    );
    return res
      .status(200)
      .json(new ApiResponse(200, { updatedUser }, "User account updated"));
  } catch (error) {
    console.log("Something went wrong during user account update", error);
    throw error;
  }
});

export const updatePassword = asyncHandler(async (req, res) => {
  try {
    //take old and new password
    const { oldPassword, newPassword } = req.body;

    //validate password
    if (
      !oldPassword ||
      oldPassword.trim() == "" ||
      !newPassword ||
      newPassword.trim() == ""
    ) {
      throw new ApiError(400, "Password is required");
    }
    //get user from req._id
    const user = await User.findById(req._id);
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    //check password of user validate
    const checkPassword = await user.isPasswordCorrect(`${oldPassword}`);
    if (!checkPassword) {
      throw new ApiError(400, "Password is incorrect");
    }
    //update password
    user.password = newPassword;
    const response = await user.save({ validateBeforeSave: false });
    return res
      .status(200)
      .json(new ApiResponse(200, "Password updated successfully"));
  } catch (error) {
    console.log("Something went wrong during password update", error);
    throw error;
  }
});
