import axios from "axios";
import { getRedisInstance } from "../redis/redis.js";
import { ApiError } from "../utils/ApiError.js";

const UNSPLASH_API_URL = "https://api.unsplash.com";

const getUnsplashClient = () => {
  return axios.create({
    baseURL: UNSPLASH_API_URL,
    headers: {
      Authorization: `Client-ID ${process.env.UNSPLASH_ACCESS_KEY}`,
    },
  });
};

export class UnsplashService {
  static async searchPhotos({ query, page, perPage, orientation }) {
    const redis = getRedisInstance();
    const cacheKey = `unsplash:search:${query}:${page}:${perPage}:${orientation || "all"}`;
    
    try {
      if (redis) {
        const cached = await redis.get(cacheKey);
        if (cached) {
          return JSON.parse(cached);
        }
      }
    } catch (e) {
      console.error("Redis Cache Read Error:", e.message);
    }

    try {
      const client = getUnsplashClient();
      const response = await client.get("/search/photos", {
        params: {
          query,
          page,
          per_page: perPage,
          ...(orientation && { orientation }),
        },
      });

      const results = response.data;

      try {
        if (redis) {
          // Cache for 1 hour to save API quota
          await redis.setex(cacheKey, 3600, JSON.stringify(results));
        }
      } catch (e) {
        console.error("Redis Cache Write Error:", e.message);
      }

      return results;
    } catch (error) {
      console.error("Unsplash API Error:", error.response?.data || error.message);
      // Map Unsplash 403 Rate Limit -> 429 Too Many Requests
      if (error.response?.status === 403) {
        throw new ApiError(429, "Unsplash API rate limit exceeded");
      }
      throw new ApiError(502, "Failed to communicate with Unsplash API");
    }
  }

  static async trackDownload(photoId) {
    try {
      const client = getUnsplashClient();
      const response = await client.get(`/photos/${photoId}/download`);
      // Unsplash returns { url: "direct_download_url" }
      return response.data;
    } catch (error) {
      console.error("Unsplash Track Download Error:", error.response?.data || error.message);
      if (error.response?.status === 404) {
        throw new ApiError(404, "Photo not found on Unsplash");
      }
      throw new ApiError(502, "Failed to track download with Unsplash");
    }
  }
}
