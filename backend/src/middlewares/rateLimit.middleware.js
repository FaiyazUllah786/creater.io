import rateLimit from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";
import { ApiError } from "../utils/ApiError.js";
import { getRedisInstance } from "../redis/redis.js";

const handler = (req, res, next, options) => {
  next(new ApiError(options.statusCode, options.message));
};

const skip = () => process.env.NODE_ENV === "development";

// User-based key generator (falls back to IP if not authenticated)
const userKeyGenerator = (req) => {
  return req._id ? req._id.toString() : req.ip;
};

const createRedisStore = () => new RedisStore({
  sendCommand: (...args) => getRedisInstance().call(...args),
});

const baseConfig = {
  standardHeaders: true,
  legacyHeaders: false,
  handler,
  skip,
  passOnStoreError: true,
  validate: false,
};


export const authLimiter = rateLimit({
  ...baseConfig,
  store: createRedisStore(),
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10,
  message: "Too many authentication attempts, please try again after 5 minutes",
  // Authentication routes are IP-based because the user is not yet authenticated.
  keyGenerator: (req) => req.ip || "unknown-ip",
});

export const refreshLimiter = rateLimit({
  ...baseConfig,
  store: createRedisStore(),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50,
  message:
    "Too many refresh token requests, please try again after 15 minutes",
  keyGenerator: userKeyGenerator,
});

export const cloudinaryLimiter = rateLimit({
  ...baseConfig,
  store: createRedisStore(),
  windowMs: 15 * 60 * 1000, // 15 minute
  max: 50,
  message: "Too many image operations, please try again later",
  keyGenerator: userKeyGenerator,
});

export const generalLimiter = rateLimit({
  ...baseConfig,
  store: createRedisStore(),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000,
  message: "Too many requests, please try again after 15 minutes",
  keyGenerator: userKeyGenerator,
});
