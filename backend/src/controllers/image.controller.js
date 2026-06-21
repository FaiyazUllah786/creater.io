import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import {
  uploadOnCloudinary,
  deleteImageFromCloudinary,
} from "../services/cloudinary/cloudinary.js";
import { Image } from "../models/image.model.js";
import { User } from "../models/user.model.js";

export const imageUploads = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const images = req.files;
  if (!images || images.length === 0) {
    throw new ApiError(422, "At least one image file is required");
  }

  const uploadResults = await Promise.all(images.map((image) => uploadOnCloudinary(image.path)));

  const failed = uploadResults.filter(Boolean).length !== uploadResults.length;
  if (failed) {
    throw new ApiError(502, "One or more images failed to upload");
  }

  const imageDocs = await Promise.all(
    uploadResults.map((imageRes) =>
      Image.create({
        publicId: imageRes.public_id,
        secureUrl: imageRes.secure_url,
        height: imageRes.height,
        width: imageRes.width,
        createdAt: imageRes.created_at,
        author: user._id,
      })
    )
  );

  return res
    .status(201)
    .json(new ApiResponse(201, imageDocs, "Images uploaded successfully"));
});

export const getImageFromDatabase = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const images = await Image.aggregate([{ $match: { author: user._id } }]);

  return res
    .status(200)
    .json(new ApiResponse(200, images, "Images retrieved successfully"));
});

export const saveImageToDatabase = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const { imageUrl } = req.body;
  if (!imageUrl || imageUrl.trim() === "") {
    throw new ApiError(422, "Image URL is required");
  }

  try {
    const parsedUrl = new URL(imageUrl);
    if (parsedUrl.protocol !== "https:" || parsedUrl.hostname !== "res.cloudinary.com") {
      throw new Error("unauthorized");
    }
  } catch (error) {
    throw new ApiError(422, "Invalid image URL format or unauthorized domain");
  }

  const urlCheck = await fetch(imageUrl).catch(() => null);
  if (!urlCheck || urlCheck.status !== 200) {
    throw new ApiError(422, "Provided image URL is not accessible");
  }

  const imageUploadRes = await uploadOnCloudinary(imageUrl);
  if (!imageUploadRes) {
    throw new ApiError(502, "Failed to upload image to storage");
  }

  const imageSaved = await Image.create({
    publicId: imageUploadRes.public_id,
    secureUrl: imageUploadRes.secure_url,
    height: imageUploadRes.height,
    width: imageUploadRes.width,
    createdAt: imageUploadRes.created_at,
    author: user._id,
  });

  return res
    .status(201)
    .json(new ApiResponse(201, imageSaved, "Image saved successfully"));
});

export const deleteImage = asyncHandler(async (req, res) => {
  const user = await User.findById(req._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const { imageId } = req.body;
  if (!imageId) {
    throw new ApiError(422, "Image ID is required");
  }

  const image = await Image.findById(imageId);
  if (!image) {
    throw new ApiError(404, "Image not found");
  }

  await deleteImageFromCloudinary(image.publicId);
  await Image.findByIdAndDelete(imageId);

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Image deleted successfully"));
});
