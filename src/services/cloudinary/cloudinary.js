import { v2 as cloudinary } from "cloudinary";
import { cloudinaryConfig } from "./config.js";
import fs from "fs";
import { ApiError } from "../../utils/ApiError.js";

//TODO:upload any file
export const uploadOnCloudinary = async (localFilePath) => {
  try {
    cloudinaryConfig();
    if (!localFilePath) {
      return null;
    }
    const uploadResponse = await cloudinary.uploader.upload(localFilePath, {
      upload_preset: "creater.io",
      resource_type: "auto",
    });
    console.log(uploadResponse);
    return uploadResponse;
  } catch (error) {
    console.log("File failed to upload,Something went wrong", error);
    throw new ApiError(
      400,
      "File failed to upload,Something went wrong",
      error
    );
  } finally {
    if (fs.existsSync(localFilePath)) {
      fs.unlinkSync(localFilePath); // Remove the temporary file
    }
  }
};
//TODO:delete any file
export const deleteImageFromCloudinary = async (imagePublicId) => {
  try {
    cloudinaryConfig();
    if (!imagePublicId) {
      return null;
    }
    const res = await cloudinary.uploader.destroy(imagePublicId);
    console.log(res);
    return res;
  } catch (error) {
    console.log("File failed to delete image,Something went wrong", error);
    throw new ApiError(
      400,
      "File failed to delete,Something went wrong",
      error
    );
  }
};
