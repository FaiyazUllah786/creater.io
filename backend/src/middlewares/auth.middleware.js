import jwt from "jsonwebtoken";
import { asyncHandler } from "../utils/asyncHandler.js";
import { User } from "../models/user.model.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import configurePassport from "../passport/auth.passport.js";

const passport = configurePassport();

export const generateAccessRefreshToken = async (userId) => {
  try {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(404, "User not found");
    }

    const accessToken = user.generateAccessToken();
    const refreshToken = user.generateRefreshToken();
    if (!accessToken || !refreshToken) {
      throw new ApiError(500, "Failed to generate authentication tokens");
    }

    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    return { accessToken, refreshToken };
  } catch (error) {
    console.log("Error generating tokens:", error);
    throw new ApiError(500, "Failed to generate authentication tokens");
  }
};

export const verifyJWT = asyncHandler(async (req, _, next) => {
  try {

    const token =
      req.cookies?.accessToken ||
      req.header("Authorization")?.replace("Bearer ", "");

    if (!token) {
      throw new ApiError(401, "Access token is missing");
    }

    const decodedData = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
    if (!decodedData) {
      throw new ApiError(401, "Invalid or expired access token");
    }

    const user = await User.findById(decodedData._id).select("-password -refreshToken");
    if (!user) {
      throw new ApiError(401, "Invalid access token or user does not exist");
    }

    req.user = user;
    req._id = user._id;
    next();
  } catch (error) {
    console.log("JWT verification failed:", error);
    throw error;
  }
});

export const refreshAccessToken = async (req, res) => {
  try {
    const incomingRefreshToken =
      req.cookies.refreshToken || req.body.refreshToken;

    if (!incomingRefreshToken) {
      throw new ApiError(401, "Refresh token is missing");
    }

    const decodedData = jwt.verify(
      incomingRefreshToken,
      process.env.REFRESH_TOKEN_SECRET
    );

    const user = await User.findById(decodedData?._id);
    if (!user) {
      throw new ApiError(401, "Refresh token is invalid or user no longer exists");
    }

    if (user.refreshToken !== incomingRefreshToken) {
      user.refreshToken = null;
      await user.save({ validateBeforeSave: false });
      throw new ApiError(403, "Refresh token has expired or been revoked");
    }

    const { accessToken, refreshToken } = await generateAccessRefreshToken(user._id);

    const updatedUser = await User.findById(user._id).select("-password -refreshToken");

    const opts = {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
    };

    return res
      .status(200)
      .cookie("accessToken", accessToken, opts)
      .cookie("refreshToken", refreshToken, opts)
      .json(
        new ApiResponse(
          200,
          { user: updatedUser, accessToken, refreshToken },
          "Tokens refreshed successfully"
        )
      );
  } catch (error) {
    console.log("Failed to refresh tokens:", error);
    return res
      .clearCookie("accessToken")
      .clearCookie("refreshToken")
      .status(error.statusCode ?? 401)
      .json(new ApiError(error.statusCode ?? 401, error.message ?? "Failed to refresh tokens"));
  }
};

export const githubAuthMiddleware = passport.authenticate("github", {
  scope: ["user:email"],
});

export const githubCallbackMiddleware = passport.authenticate("github", {
  failureRedirect: "/login",
  session: false,
});

export const googleAuthMiddleware = passport.authenticate("google", {
  scope: ["profile", "email"],
});

export const googleCallbackMiddleware = passport.authenticate("google", {
  failureRedirect: "/login",
  session: false,
});
