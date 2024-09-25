import jwt from "jsonwebtoken";
import { asyncHandler } from "../utils/asyncHandler.js";
import { User } from "../models/user.model.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";

export const generateAccessRefreshToken = async (userId) => {
  try {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(400, "User does not exist");
    }

    const accessToken = await user.generateAccessToken();
    const refreshToken = await user.generateRefreshToken();
    if (!accessToken || !refreshToken) {
      throw new ApiError(
        400,
        "Something went wrong during generation of access and refresh token"
      );
    }

    user.refreshToken = refreshToken;
    const updatedUserWithRefreshToken = await user.save({
      validateBeforeSave: false,
    });

    console.log(updatedUserWithRefreshToken);
    return { accessToken, refreshToken };
  } catch (error) {
    console.log("error on generating tokens:", error);
    throw new ApiError(
      400,
      "Something went wrong during generation of access and refresh token"
    );
  }
};

export const verifyJWT = asyncHandler(async (req, _, next) => {
  try {
    //take cookies from req
    const token =
      req.cookies?.accessToken ||
      req.header("Authorization")?.replace("Bearer ", "");

    //validate cookies
    if (!token) {
      throw new ApiError(400, "access token missing");
    }

    //extract data from cookies
    const decodedData = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
    if (!decodedData) {
      throw new ApiError(401, "invalid or expired token");
    }
    console.log("verifiedJWT Data:", decodedData);
    //set user id in req
    req._id = decodedData._id;
    //move the control to next middleware
    next();
  } catch (error) {
    console.log("Error during JWT verification:", error);
    throw error;
  }
});

export const refreshAccessToken = asyncHandler(async (req, res) => {
  //take refresh token from cookies or frontend
  const incomingRefreshToken =
    req.cookies.refreshToken || req.body.refreshToken;
  //validate refresh token
  if (!incomingRefreshToken) {
    throw new ApiError(401, "Refresh Token is missing");
  }
  //decode refresh token
  const decodedData = jwt.verify(
    incomingRefreshToken,
    process.env.REFRESH_TOKEN_SECRET
  );
  const user = await User.findById(decodedData?._id);
  //validate user
  if (!user) {
    throw new ApiError(400, "User not found");
  }
  //validate user with incomingrefreshtoken
  const token = user?.refreshToken;
  console.log("incoming refresh token :", incomingRefreshToken);
  console.log("user refresh token :", token);
  console.log(
    "check whether they are same or not:",
    token != incomingRefreshToken
  );
  if (user?.refreshToken != incomingRefreshToken) {
    throw new ApiError(403, "Refresh Token expired");
  }
  //get new access and refresh token
  const { accessToken, refreshToken } = await generateAccessRefreshToken(
    user._id
  );
  const updatedUserWithRefreshToken = await User.findById(user._id).select(
    "-password -refreshToken"
  );
  //set access and refreshtoken
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
        201,
        { updatedUserWithRefreshToken, accessToken, refreshToken },
        "New access and refresh token generated"
      )
    );
});
