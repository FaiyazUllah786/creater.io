import { describe, it, expect, vi, beforeEach } from "vitest";
import { saveTransformation } from "../transformation.controller.js";
import { loginUser } from "../user.controllers.js";
import { getRedisInstance } from "../../redis/redis.js";
import { User } from "../../models/user.model.js";
import { ApiError } from "../../utils/ApiError.js";

vi.mock("../../redis/redis.js", () => ({
  getRedisInstance: vi.fn(),
}));

vi.mock("../../models/user.model.js", () => ({
  User: {
    findOne: vi.fn(),
    findById: vi.fn(),
  },
}));

describe("Redis Failure Behavior", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("Transformation APIs return 503 when Redis is unavailable", async () => {
    getRedisInstance.mockImplementation(() => {
      throw new ApiError(503, "Transformation service temporarily unavailable");
    });

    const req = {
      body: { imagePublicId: "test_public_id" },
    };
    const res = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn(),
    };

    saveTransformation(req, res, () => {});

    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(res.status).toHaveBeenCalledWith(503);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      statusCode: 503,
      message: "Transformation service temporarily unavailable",
    }));
  });

  it("Login remains unaffected when Redis is unavailable", async () => {
    getRedisInstance.mockImplementation(() => {
      throw new ApiError(503, "Transformation service temporarily unavailable");
    });

    const mockUser = {
      _id: "user123",
      isPasswordCorrect: vi.fn().mockResolvedValue(true),
      generateAccessToken: vi.fn().mockReturnValue("access_token"),
      generateRefreshToken: vi.fn().mockReturnValue("refresh_token"),
      save: vi.fn().mockResolvedValue(true),
    };

    User.findOne.mockResolvedValue(mockUser);
    
    User.findById.mockImplementation(() => {
      const promise = Promise.resolve(mockUser);
      promise.select = vi.fn().mockResolvedValue(mockUser);
      return promise;
    });

    const req = {
      body: { email: "test@example.com", password: "password123" },
    };
    const res = {
      status: vi.fn().mockReturnThis(),
      cookie: vi.fn().mockReturnThis(),
      json: vi.fn(),
    };

    loginUser(req, res, () => {});

    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      message: "Logged in successfully",
    }));
  });
});
