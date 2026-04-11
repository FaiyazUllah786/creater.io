import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { User } from "../models/user.model.js";
import { generateAccessRefreshToken } from "../middlewares/auth.middleware.js";

import { OAuth2Client } from "google-auth-library";
import crypto from "crypto";
import axios from "axios";

const client = new OAuth2Client(process.env.GOOGLE_ANDROID_CLIENT_ID);

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
    } = githubProfile;
    console.log(githubProfile);

    const email = `${githubId}@github.user`;
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

export const googleCallbackHandler = asyncHandler(async (req, res) => {
  try {
    const googleProfile = req.user;

    if (!googleProfile) {
      throw new ApiError(400, "Google profile not found!");
    }

    const { id: googleId, displayName, name, photos, emails } = googleProfile;
    console.log(googleProfile);
    console.log(googleId);

    const email = emails?.[0]?.value || `${googleId}@github.user`;
    const profilePhoto =
      photos?.[0]?.value || "https://www.gravatar.com/avatar/?d=mp&s=200";
    const firstName = name?.givenName || displayName?.split(" ")[0] || "";
    const lastName = name?.familyName || displayName?.split(" ")[1] || "";
    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (!user) {
      // Create new GitHub user
      user = await User.create({
        userName: `${firstName}_${googleId.slice(-4)}`,
        firstName,
        lastName,
        email,
        googleId,
        profilePhoto,
        authProvider: "google",
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
    console.error("Error in google callback:", error);
    res.redirect(
      `${process.env.CLIENT_URL}/auth/failure?reason=${encodeURIComponent(
        "Google authentication failed"
      )}`
    );
    throw new ApiError(
      500,
      "Something went wrong during GitHub authentication"
    );
  }
});


export const googleMobileAuthHandler = asyncHandler(async (req, res) => {

  const { idToken } = req.body;

  console.log(req.body)

  if (!idToken) {
    throw new ApiError(400, "No tokens provided!");
  }

  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_ANDROID_CLIENT_ID,
  });

  const googleProfile = ticket.getPayload();

  if (!googleProfile) {
    throw new ApiError(400, "Google profile not found!");
  }

  const { sub: googleId, name, givenName, familyName, picture, email } = googleProfile;
  console.log(googleProfile);

  const profilePhoto =
    picture || "";
  const firstName = givenName || name?.split(" ")[0] || "";
  const lastName = familyName || name?.split(" ")[1] || "";
  let user = await User.findOne({ $or: [{ googleId }, { email }] });

  if (!user) {
    // Create new GitHub user
    user = await User.create({
      userName: `${firstName}_${googleId.slice(-4)}`,
      firstName,
      lastName,
      email,
      googleId,
      profilePhoto,
      authProvider: "google",
      password: crypto.randomBytes(32).toString("hex"),
    });
  }

  const { accessToken, refreshToken } = await generateAccessRefreshToken(
    user._id
  );
  user.refreshToken = refreshToken;
  await user.save({ validateBeforeSave: false });

  const userWithoutPass = await User.findById(user._id).select(
    "-password"
  );

  console.log("User:", user);
  return res
    .status(200)
    .json(
      new ApiResponse(200, { userWithoutPass, accessToken, refreshToken }, "User registered successfully")
    );
})


export const githubMobileAuthHandler = asyncHandler(async (req, res) => {

  const { code } = req.body;

  if (!code) {
    throw new ApiError(400, "No code provided");
  }

  const tokenRes = await axios.post(
    "https://github.com/login/oauth/access_token",
    {
      client_id: process.env.GITHUB_ANDROID_CLIENT_ID,
      client_secret: process.env.GITHUB_ANDROID_CLIENT_SECRET,
      code,
    },
    {
      headers: { Accept: "application/json" },
    }
  );

  const access_token = tokenRes.data.access_token;

  if (!access_token) {
    throw new ApiError(400, "Failed to get github access token");
  }

  const response = await axios.get("https://api.github.com/user", {
    headers: { Authorization: `Bearer ${access_token}` },
  });

  console.log(response?.data, '[------------]');
  const githubProfile = response?.data;

  if (!githubProfile) {
    throw new ApiError(400, "Github profile not found!");
  }

  const {
    id: githubId,
    login: username,
    name,
    avatar_url,
  } = githubProfile;
  console.log(githubProfile);

  const email = `${githubId}@github.user`;
  const profilePhoto =
    avatar_url || "";
  const [firstName, lastName = ""] = name?.split(" ") || [];

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

  // Cookie options (same as your local login)
  const { accessToken, refreshToken } = await generateAccessRefreshToken(
    user._id
  );
  user.refreshToken = refreshToken;
  await user.save({ validateBeforeSave: false });

  const userWithoutPass = await User.findById(user._id).select(
    "-password"
  );

  console.log("User:", user);
  return res
    .status(200)
    .json(
      new ApiResponse(200, { userWithoutPass, accessToken, refreshToken }, "User registered successfully")
    );

})