import { Router } from "express";
import mongoose from "mongoose";
import { getRedisInstance } from "../redis/redis.js";

const router = Router();

router.get("/", (req, res) => {
  const isMongoHealthy = mongoose.connection.readyState === 1;
  
  let isRedisHealthy = false;
  try {
    const redis = getRedisInstance();
    isRedisHealthy = redis && redis.status === "ready";
  } catch (error) {
    // 503 means it's temporarily unavailable
    isRedisHealthy = false;
  }

  if (isMongoHealthy && isRedisHealthy) {
    return res.status(200).json({ status: "ok", mongodb: true, redis: true });
  } else if (isMongoHealthy && !isRedisHealthy) {
    return res.status(200).json({ status: "degraded", mongodb: true, redis: false });
  } else {
    // If Mongo is dead, the service is essentially dead
    return res.status(503).json({ status: "error", mongodb: isMongoHealthy, redis: isRedisHealthy });
  }
});

export default router;
