import Redis from "ioredis";
import dotenv from "dotenv";
import { app } from "./../app.js";
import { ApiError } from "./../utils/ApiError.js";

dotenv.config();

let redisClient = null;

export const connectRedis = async () => {
  return new Promise((resolve, reject) => {
    const redis = new Redis(process.env.REDIS_URL);
    redisClient = redis;

    redis.on("connect", () => {
      console.log("Redis connected successfully");
      app.locals.redis = redis;
      resolve(redis);
    });

    redis.on("error", (err) => {
      reject(new ApiError(400, "Error occured during app initialization", err));
      process.exit(1);
    });
  });
};

export const getRedisInstance = () => {
  if (!redisClient) {
    throw new ApiError(404, "Redis client not found");
  }
  return redisClient;
}