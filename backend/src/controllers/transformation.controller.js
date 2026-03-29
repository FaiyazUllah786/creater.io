import { transformationHelper } from "../services/cloudinary/transfomationHelper.js";
import {
  addTransformationToList,
  clearTransformationList,
  deleteTransformationFromList,
  modifyTransforamtionFromList,
  getCurrentList,
} from "../services/redisServices/transformation.js";
import { universalTransformation } from "../services/cloudinary/imageTransformations.js";
import { uploadOnCloudinary } from "../services/cloudinary/cloudinary.js";
import { getRedisInstance } from "../redis/redis.js";
import { User } from "../models/user.model.js";
import { Image } from "../models/image.model.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";

//add transformation
export const addTransformation = asyncHandler(async (req, res) => {
  try {
    const { imagePublicId, transformation } = req.body;

    if (!imagePublicId) {
      throw new ApiError(400, "Image id is required.");
    }

    if (!transformation) {
      throw new ApiError(400, "Transformation effect is required.");
    }

    const tranfomationFunction = transformationHelper(transformation);
    const { resUrl, effect } = await tranfomationFunction(imagePublicId, transformation);

    const transfomationList = await addTransformationToList(imagePublicId, {
      transformation,
      effect,
    });

    return res
      .status(200)
      .json(new ApiResponse(200, { resUrl, transfomationList }, "Transformation applied"));
  } catch (error) {
    res.status(400).json(new ApiError(400, "Error occured ", error.message));
  }
});

export const updateTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId, transformation, transformationId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(400, "Image id is required.");
  }

  if (!transformation) {
    throw new ApiError(400, "Transformation effect is required.");
  }
  if (!transformationId) {
    throw new ApiError(400, "transformation id is required.");
  }

  const tranfomationFunction = transformationHelper(transformation);
  const { resUrl, effect } = await tranfomationFunction(imagePublicId, transformation);

  const transfomationList = await modifyTransforamtionFromList(
    imagePublicId,
    { transformation, effect },
    transformationId
  );

  return res
    .status(200)
    .json(new ApiResponse(200, { resUrl, transfomationList }, "Transformation applied"));
});

export const deleteTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId, transformationId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(400, "Image id is required.");
  }

  if (!transformationId) {
    throw new ApiError(400, "Transformation id is required.");
  }

  const transfomationList = await deleteTransformationFromList(imagePublicId, transformationId);

  const tranfomationFunction = transformationHelper({ effectType: "del_transform" });
  const resUrl = await tranfomationFunction(imagePublicId, transfomationList);

  return res
    .status(200)
    .json(new ApiResponse(200, { resUrl, transfomationList }, "Transformation applied"));
});

export const clearTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(400, "Image id is required.");
  }

  const transfomationList = await clearTransformationList(imagePublicId);

  const tranfomationFunction = transformationHelper({ effectType: "del_transform" });
  const resUrl = await tranfomationFunction(imagePublicId);

  return res
    .status(200)
    .json(new ApiResponse(200, { resUrl, transfomationList }, "Transformation applied"));
});

export const saveTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(400, "Image id is required.");
  }

  // Get Redis list — fall back to empty list if Redis is unavailable
  let list = [];
  try {
    const redis = getRedisInstance();
    list = await getCurrentList(redis, imagePublicId);
  } catch (_redisErr) {
    // Redis unavailable; proceed with empty transformation list
  }

  const finalUrl = await universalTransformation(imagePublicId, list);

  // Attempt to upload and persist; skip gracefully if services are unavailable
  let savedImage = null;
  try {
    const uploadResponse = await uploadOnCloudinary(finalUrl);
    if (uploadResponse) {
      const user = await User.findById(req._id);
      if (user) {
        savedImage = await Image.create({
          publicId: uploadResponse.public_id,
          secureUrl: uploadResponse.secure_url,
          height: uploadResponse.height,
          width: uploadResponse.width,
          createdAt: uploadResponse.created_at,
          author: user._id,
        });
      }
    }
  } catch (_saveErr) {
    // Upload or DB unavailable; return the generated URL
  }

  return res
    .status(200)
    .json(new ApiResponse(200, savedImage ?? { finalUrl }, "Image saved successfully."));
});
