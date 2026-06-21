import rateLimit from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";
import { ApiError } from "../utils/ApiError.js";
import { getRedisInstance } from "../redis/redis.js";

const handler = (req, res, next, options) => {
  next(new ApiError(options.statusCode, options.message));
};

const store = new RedisStore({
  sendCommand: async (...args) => {
    try {
      const client = getRedisInstance();
      return client.call(...args);
    } catch (error) {
      throw error;
    }
  },
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many authentication attempts, please try again after 15 minutes",
  handler,
  store,
  passOnStoreError: true,
});

export const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many refresh token requests, please try again after 15 minutes",
  handler,
  store,
  passOnStoreError: true,
});

export const cloudinaryLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 1000, // High ceiling abuse safeguard
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many image operations, please try again later",
  handler,
  store,
  passOnStoreError: true,
  keyGenerator: (req) => {
    return req._id ? req._id.toString() : req.ip;
  },
});

export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many requests, please try again after 15 minutes",
  handler,
  store,
  passOnStoreError: true,
});
