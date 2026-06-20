import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import express from "express";
import healthRouter from "../health.routes.js";
import mongoose from "mongoose";
import * as redisModule from "../../redis/redis.js";

vi.mock("mongoose", () => ({
  default: {
    connection: {
      readyState: 1, // 1 = connected
    },
  },
}));

vi.mock("../../redis/redis.js", () => ({
  getRedisInstance: vi.fn(),
}));

const app = express();
app.use("/health", healthRouter);

describe("Health Endpoint", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("Returns status: ok when MongoDB and Redis are healthy", async () => {
    mongoose.connection.readyState = 1; // Connected
    redisModule.getRedisInstance.mockReturnValue({ status: "ready" });

    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      status: "ok",
      mongodb: true,
      redis: true,
    });
  });

  it("Returns status: degraded when MongoDB is healthy but Redis is unavailable", async () => {
    mongoose.connection.readyState = 1; // Connected
    redisModule.getRedisInstance.mockImplementation(() => {
      const { ApiError } = require("../../utils/ApiError.js");
      throw new ApiError(503, "Transformation service temporarily unavailable");
    });

    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      status: "degraded",
      mongodb: true,
      redis: false,
    });
  });

  it("Returns status: error when MongoDB is unavailable", async () => {
    mongoose.connection.readyState = 0; // Disconnected
    redisModule.getRedisInstance.mockReturnValue({ status: "ready" });

    const response = await request(app).get("/health");

    expect(response.status).toBe(503);
    expect(response.body).toEqual({
      status: "error",
      mongodb: false,
      redis: true,
    });
  });
});
