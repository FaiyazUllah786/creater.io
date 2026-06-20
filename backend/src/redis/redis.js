import Redis from "ioredis";
import dotenv from "dotenv";
import { app } from "./../app.js";
import { ApiError } from "./../utils/ApiError.js";

dotenv.config();

let redisClient = null;

export const connectRedis = async () => {
  return new Promise((resolve, reject) => {
    let settled = false;

    const redis = new Redis(process.env.REDIS_URL, {
      maxRetriesPerRequest: 1,
      retryStrategy(times) {
        // Retry a few times on startup before failing, or during runtime to reconnect
        if (times > 3) return null; // Stop retrying after 3 attempts
        return Math.min(times * 50, 2000);
      }
    });

    redis.on("connect", () => {
      console.log("Redis connected");
    });

    redis.on("ready", () => {
      console.log("Redis ready");
      redisClient = redis;
      app.locals.redis = redis;

      if (!settled) {
        settled = true;
        resolve(redis);
      }
    });

    redis.on("reconnecting", () => {
      console.warn("Redis reconnecting...");
    });

    redis.on("close", () => {
      console.warn("Redis connection closed");
    });

    redis.on("end", () => {
      console.error("Redis connection ended");
      redisClient = null;
    });

    redis.on("error", (err) => {
      console.error("Redis connection error:", err.message);
      // If we haven't successfully connected for the first time, fail startup
      if (!settled) {
        settled = true;
        reject(new ApiError(500, "Failed to initialize Redis during startup", err));
      }
      // If it's a runtime error, do NOT crash process, just log.
      // getRedisInstance() will throw 503 when called.
    });
  });
};

export const getRedisInstance = () => {
  if (!redisClient || redisClient.status !== "ready") {
    throw new ApiError(503, "Transformation service temporarily unavailable");
  }
  return redisClient;
};