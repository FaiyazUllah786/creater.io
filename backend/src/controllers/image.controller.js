import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import {
  uploadOnCloudinary,
  deleteImageFromCloudinary,
} from "../services/cloudinary/cloudinary.js";
import { Image } from "../models/image.model.js";
import { v2 as cloudinary } from "cloudinary";
import { User } from "../models/user.model.js";
import {
  aiImageEnhancer,
  backgroundRemoval,
  contentExtraction,
  generativeBackgroundFill,
  generativeBackgroundReplace,
  generativeObjectRemove,
  generativeObjectReplace,
  generativeRecolor,
  generativeRestore,
  generativeUpscale,
} from "../services/cloudinary/imageTransformations.js";

export const imageUploads = asyncHandler(async (req, res) => {
  try {
    //take user data
    const user = await User.findById(req._id);
    //validate user
    if (!user) {
      throw new ApiError(400, "User not found");
    }
    //taking images from frontend
    const images = req.files;
    console.log(req.files);
    //validating images
    if (req.files?.length == 0) {
      throw new ApiError(400, "Image is required");
    }
    console.log(images);
    //upload image to cloudinary
    const imageUploadCycle = images.map((image) => {
      return uploadOnCloudinary(image.path);
    });
    const response = await Promise.all(imageUploadCycle);
    //validating cloud upload on error
    if (!response) {
      throw new ApiError(400, "Something went wrong during uploading images");
    }
    //create new image documents in database
    const imageDocCreate = response.map((imageRes) => {
      return Image.create({
        publicId: imageRes.public_id,
        secureUrl: imageRes.secure_url,
        height: imageRes.height,
        width: imageRes.width,
        createdAt: imageRes.created_at,
        author: user._id,
      });
    });
    const imageDocCreateRes = await Promise.all(imageDocCreate);
    if (!imageDocCreateRes) {
      throw new ApiError(400, "Something went wrong during image upload");
    }
    console.log(imageDocCreateRes);
    return res
      .status(200)
      .json(
        new ApiResponse(200, imageDocCreateRes, "Image uploaded successfully")
      );
  } catch (error) {
    console.log("Error while uploading image", error);
    throw error.message;
  }
});

export const getImageFromDatabase = asyncHandler(async (req, res) => {
  //fetch user profile
  const user = await User.findById(req._id);
  //validate user
  if (!user) {
    throw new ApiError(400, "User not found");
  }
  //fetch image upload by user
  const images = await Image.aggregate([
    {
      $match: {
        author: user._id,
      },
    },
  ]);
  //validate res
  if (!images) {
    throw new ApiError(400, "Something went wrong while getting images");
  }
  console.log(images);
  //send res
  return res
    .status(200)
    .json(new ApiResponse(200, images, "Images found successfully"));
});

export const saveImageToDatabase = asyncHandler(async (req, res) => {
  //fetch user
  const user = await User.findById(req._id);
  //validate user
  if (!user) {
    throw new ApiError(400, "User not found");
  }
  //get image url from frontend
  const { imageUrl } = req.body;
  //validate url
  if (!imageUrl || imageUrl.trim() == "") {
    throw new ApiError(400, "Image url is required");
  }
  await fetch(imageUrl)
    .then((res) => {
      if (res.status != 200) throw new ApiError(400, "Something went wrong");
    })
    .catch((err) => {
      throw new ApiError(400, "Something went wrong or not a valid image");
    });
  //upload image to cloudinary
  const imageUploadRes = await uploadOnCloudinary(imageUrl);
  if (!imageUploadRes) {
    throw new ApiError(400, "Something went wrong while uploading image");
  }

  //save image to database
  const imageSaved = await Image.create({
    publicId: imageUploadRes.public_id,
    secureUrl: imageUploadRes.secure_url,
    height: imageUploadRes.height,
    width: imageUploadRes.width,
    createdAt: imageUploadRes.created_at,
    author: user._id,
  });
  if (!imageSaved) {
    throw new ApiError(
      400,
      "Somthing went wrong while saving image to database"
    );
  }
  return res
    .status(200)
    .json(
      new ApiResponse(200, imageSaved, "Image saved to database successfully")
    );
});

export const deleteImage = asyncHandler(async (req, res) => {
  //fetch user
  const user = await User.findById(req._id);
  //validate user
  if (!user) {
    throw new ApiError(400, "User not found");
  }
  //take image id from frontend
  const { imageId } = req.body;

  const image = await Image.findById(imageId);
  if (!image) {
    throw new ApiError(400, "Something went wrong while deleting image");
  }
  const imagePublicId = image.publicId;
  //validate and delete image from cloudinary
  const deleteCloudinaryRes = await deleteImageFromCloudinary(imagePublicId);
  if (!deleteCloudinaryRes) {
    throw new ApiError(400, "Something went wrong while deleting image");
  }
  //validate and delete image from database
  const deleteDatabaseRes = await Image.findByIdAndDelete(imageId);
  if (!deleteDatabaseRes) {
    throw new ApiError(400, "Something went wrong while deleting image");
  }
  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Image deleted successfully"));
});

export const imageBackgroundReplace = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId, prompt } = req.body;
    //validate image, prompt and perform generative fill on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await generativeBackgroundReplace(
      image.publicId,
      prompt
    );
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log(
      "Something went wrong during image background replace transformation",
      error
    );
    throw error;
  }
});

export const imageEnhancer = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId } = req.body;
    //validate image, prompt and perform generative fill on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await aiImageEnhancer(image.publicId);
    console.log("enhance image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log(
      "Something went wrong during image enhancement transformation",
      error
    );
    throw error;
  }
});

export const imageBackgroundFill = asyncHandler(async (req, res) => {
  try {
    //take an image url and prompt if any
    const { imageUrl, aspectRatio, height, width, gravity } = req.body;
    console.log(imageUrl, aspectRatio, height, width, gravity);
    const image = await uploadOnCloudinary(imageUrl);
    const responseUrl = await generativeBackgroundFill(
      image.public_id,
      aspectRatio,
      height,
      width,
      gravity
    );
    const deleteImage = await deleteImageFromCloudinary(image.public_id);
    console.log("Image Deleted: ", deleteImage);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }

    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log(
      "Something went wrong during image background replace transformation",
      error
    );
    throw error;
  }
});

export const imageUpscale = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageUrl } = req.body;
    //validate image, prompt and perform backgroung removal on image
    const image = await uploadOnCloudinary(imageUrl);
    const responseUrl = await generativeUpscale(image.publicId);
    const deleteImage = await deleteImageFromCloudinary(image.public_id);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log("Something went wrong during image background removal", error);
    throw error;
  }
});

export const imageObjectReplace = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId, itemToReplace, replaceWith } = req.body;
    //validate image, prompt and perform generative fill on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await generativeObjectReplace(
      image.publicId,
      itemToReplace,
      replaceWith
    );
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log(
      "Something went wrong during image object replace transformation",
      error
    );
    throw error;
  }
});

export const imageObjectRemove = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId, prompt } = req.body;
    //validate image, prompt and perform generative fill on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await generativeObjectRemove(image.publicId, prompt);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log(
      "Something went wrong during image object replace transformation",
      error
    );
    throw error;
  }
});

export const imageBackgroundRemoval = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId } = req.body;
    //validate image, prompt and perform backgroung removal on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await backgroundRemoval(image.publicId);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log("Something went wrong during image background removal", error);
    throw error;
  }
});

export const imageObjectRecolor = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId, promptsArray, color } = req.body;
    //validate image, prompt and perform backgroung removal on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await generativeRecolor(
      image.publicId,
      promptsArray,
      color
    );
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log("Something went wrong during image background removal", error);
    throw error;
  }
});

export const imageRestore = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId } = req.body;
    //validate image, prompt and perform backgroung removal on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await generativeRestore(image.publicId);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log("Something went wrong during image background removal", error);
    throw error;
  }
});

export const imageObjectExtraction = asyncHandler(async (req, res) => {
  try {
    //take an image from gallery or upload an image and prompt if any
    const { imageId, promptsArray } = req.body;
    //validate image, prompt and perform backgroung removal on image
    const image = await Image.findById(imageId);
    if (!image) {
      throw new ApiError(400, "Something went wrong while transformation");
    }
    const responseUrl = await contentExtraction(image.publicId, promptsArray);
    console.log("transformed image response", responseUrl);
    //validate transform image
    if (!responseUrl || responseUrl.trim() == "") {
      throw new ApiError(400, "Something went wrong during transformation");
    }
    //send res
    return res
      .status(200)
      .json(
        new ApiResponse(200, responseUrl, "Image transformed successfully")
      );
  } catch (error) {
    console.log("Something went wrong during image background removal", error);
    throw error;
  }
});
