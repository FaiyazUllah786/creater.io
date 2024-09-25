import { v2 as cloudinary } from "cloudinary";
import fs from "fs";
import { ApiError } from "./ApiError.js";

export const uploadImage = async (localFilePath) => {
  try {
    if (!localFilePath) {
      return null;
    }
    cloudinary.config({
      cloud_name: process.env.CLOUD_NAME,
      api_key: process.env.API_KEY,
      api_secret: process.env.API_SECRET,
    });
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
    if (localFilePath) {
      fs.unlinkSync(localFilePath);
    }
  }
};
