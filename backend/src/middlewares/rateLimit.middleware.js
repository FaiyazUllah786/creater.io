import rateLimit from "express-rate-limit";
import { ApiError } from "../utils/ApiError.js";

const handler = (req, res, next, options) => {
  next(new ApiError(options.statusCode, options.message));
};

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many authentication attempts, please try again after 15 minutes",
  handler,
});

export const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many refresh token requests, please try again after 15 minutes",
  handler,
});

export const cloudinaryLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many image operations, please try again after 1 hour",
  handler,
});

export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many requests, please try again after 15 minutes",
  handler,
});
