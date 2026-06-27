import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { UnsplashService } from "../services/unsplash.service.js";

export const searchPhotos = asyncHandler(async (req, res) => {
  const { query = "latest", page = 1, perPage = 10, orientation } = req.query;

  const results = await UnsplashService.searchPhotos({
    query,
    page: parseInt(page, 10),
    perPage: parseInt(perPage, 10),
    orientation,
  });

  return res.status(200).json(
    new ApiResponse(200, results, "Photos fetched successfully")
  );
});

export const triggerDownload = asyncHandler(async (req, res) => {
  const { photoId } = req.params;

  if (!photoId) {
    throw new ApiError(400, "photoId is required");
  }

  const downloadData = await UnsplashService.trackDownload(photoId);

  return res.status(200).json(
    new ApiResponse(200, downloadData, "Download tracked successfully")
  );
});
