import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { User } from "../models/user.model.js";
import { generateAccessRefreshToken } from "../middlewares/auth.middleware.js";

import crypto from "crypto";

export const githubCallbackHandler = asyncHandler(async (req, res) => {
  try {
    const githubProfile = req.user;

    if (!githubProfile) {
      throw new ApiError(400, "Github profile not found!");
    }

    const {
      id: githubId,
      username,
      displayName,
      photos,
      emails,
    } = githubProfile;
    console.log(githubProfile);

    const email = emails?.[0]?.value || `${githubId}@github.user`;
    const profilePhoto =
      photos?.[0]?.value || "https://www.gravatar.com/avatar/?d=mp&s=200";
    const [firstName, lastName = ""] = displayName?.split(" ") || [];

    let user = await User.findOne({ $or: [{ githubId }, { email }] });

    if (!user) {
      // Create new GitHub user
      user = await User.create({
        userName: username || `user_${githubId}`,
        firstName,
        lastName,
        email,
        githubId,
        profilePhoto,
        authProvider: "github",
        password: crypto.randomBytes(32).toString("hex"),
      });
    }
    const { accessToken, refreshToken } = await generateAccessRefreshToken(
      user._id
    );
    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    // Cookie options (same as your local login)
    const opts = {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
    };

    // Set cookies and redirect (no tokens in URL!)
    res
      .cookie("accessToken", accessToken, opts)
      .cookie("refreshToken", refreshToken, opts)
      .redirect(`${process.env.CLIENT_URL}/`);
  } catch (error) {
    console.error("Error in GitHub callback:", error);
    res.redirect(
      `${process.env.CLIENT_URL}/auth/failure?reason=${encodeURIComponent(
        "GitHub authentication failed"
      )}`
    );
    throw new ApiError(
      500,
      "Something went wrong during GitHub authentication"
    );
  }
});
