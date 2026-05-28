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

export const addTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId, transformation } = req.body;

  if (!imagePublicId) {
    throw new ApiError(422, "imagePublicId is required");
  }
  if (!transformation) {
    throw new ApiError(422, "transformation is required");
  }

  const transfomationFunction = transformationHelper(transformation);
  const { resUrl, effect } = await transfomationFunction(imagePublicId, transformation);

  const transfomationList = await addTransformationToList(imagePublicId, {
    transformation,
    effect,
  });

  return res
    .status(200)
    .json(new ApiResponse(200, { previewUrl: resUrl, transfomationList }, "Transformation added successfully"));
});

export const updateTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId, transformation, transformationId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(422, "imagePublicId is required");
  }
  if (!transformation) {
    throw new ApiError(422, "transformation is required");
  }
  if (!transformationId) {
    throw new ApiError(422, "transformationId is required");
  }

  const transfomationFunction = transformationHelper(transformation);
  const { resUrl, effect } = await transfomationFunction(imagePublicId, transformation);

  const transfomationList = await modifyTransforamtionFromList(
    imagePublicId,
    { transformation, effect },
    transformationId
  );

  return res
    .status(200)
    .json(new ApiResponse(200, { previewUrl: resUrl, transfomationList }, "Transformation updated successfully"));
});

export const deleteTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId, transformationId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(422, "imagePublicId is required");
  }
  if (!transformationId) {
    throw new ApiError(422, "transformationId is required");
  }

  const transfomationList = await deleteTransformationFromList(imagePublicId, transformationId);

  const transfomationFunction = transformationHelper({ effectType: "del_transform" });
  const resUrl = await transfomationFunction(imagePublicId, transfomationList);

  return res
    .status(200)
    .json(new ApiResponse(200, { previewUrl: resUrl, transfomationList }, "Transformation removed successfully"));
});

export const clearTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(422, "imagePublicId is required");
  }

  const transfomationList = await clearTransformationList(imagePublicId);

  const transfomationFunction = transformationHelper({ effectType: "del_transform" });
  const resUrl = await transfomationFunction(imagePublicId);

  return res
    .status(200)
    .json(new ApiResponse(200, { previewUrl: resUrl, transfomationList }, "Transformation stack cleared successfully"));
});

export const saveTransformation = asyncHandler(async (req, res) => {
  const { imagePublicId } = req.body;

  if (!imagePublicId) {
    throw new ApiError(422, "imagePublicId is required");
  }

  let list = [];
  try {
    const redis = getRedisInstance();
    list = await getCurrentList(redis, imagePublicId);
  } catch (_redisErr) {
    // Redis unavailable — proceed with empty list, returning plain URL
  }

  const finalUrl = await universalTransformation(imagePublicId, list);

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
    // Upload or DB unavailable — return the generated URL as fallback
  }

  return res
    .status(201)
    .json(new ApiResponse(201, savedImage ?? { finalUrl }, "Image saved successfully"));
});
