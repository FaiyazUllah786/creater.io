import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  getCurrentList,
  clearTransformationList,
  addTransformationToList,
  modifyTransforamtionFromList,
  deleteTransformationFromList,
} from "../transformation.js";
import { getRedisInstance } from "../../../redis/redis.js";

vi.mock("../../../redis/redis.js", () => ({
  getRedisInstance: vi.fn(),
}));

describe("Redis Image Transformation Service", () => {
  let mockRedis;
  const publicId = "test_image_id";

  beforeEach(() => {
    vi.clearAllMocks();

    mockRedis = {
      get: vi.fn(),
      set: vi.fn(),
      exists: vi.fn(),
      del: vi.fn(),
      expire: vi.fn(),
    };

    getRedisInstance.mockReturnValue(mockRedis);
  });

  describe("getCurrentList", () => {
    it("should create new list if not exists", async () => {
      mockRedis.get.mockResolvedValue(null);
      
      const result = await getCurrentList(mockRedis, publicId);
      
      expect(mockRedis.set).toHaveBeenCalledWith(`transformation:${publicId}`, "[]", "EX", 7200);
      expect(result).toEqual([]);
    });

    it("should return existing list and update TTL", async () => {
      const existingList = [{ id: "1", type: "crop" }];
      mockRedis.get.mockResolvedValue(JSON.stringify(existingList));
      
      const result = await getCurrentList(mockRedis, publicId);
      
      expect(mockRedis.expire).toHaveBeenCalledWith(`transformation:${publicId}`, 7200);
      expect(result).toEqual(existingList);
    });
  });

  describe("clearTransformationList", () => {
    it("should throw ApiError if list does not exist", async () => {
      mockRedis.exists.mockResolvedValue(0);
      await expect(clearTransformationList(publicId)).rejects.toThrow("Transformation list does not exists.");
    });

    it("should delete list and return empty array", async () => {
      mockRedis.exists.mockResolvedValue(1);
      mockRedis.del.mockResolvedValue({ status: 1 }); // success

      const result = await clearTransformationList(publicId);

      expect(mockRedis.del).toHaveBeenCalledWith(`transformation:${publicId}`);
      expect(result).toEqual([]);
    });
  });

  describe("addTransformationToList", () => {
    it("should add transformation and save to redis", async () => {
      mockRedis.get.mockResolvedValue("[]"); // existing list
      
      const result = await addTransformationToList(publicId, { type: "blur" });
      
      expect(result.length).toBe(1);
      expect(result[0]).toHaveProperty("id");
      expect(result[0].type).toBe("blur");
      expect(mockRedis.set).toHaveBeenCalledWith(`transformation:${publicId}`, expect.any(String), "EX", 7200);
    });
  });

  describe("modifyTransforamtionFromList", () => {
    it("should throw ApiError if transformationId is not provided", async () => {
      await expect(modifyTransforamtionFromList(publicId, { type: "blur" }, null)).rejects.toThrow("Transformation id is required.");
    });

    it("should throw ApiError if list is empty", async () => {
      mockRedis.get.mockResolvedValue("[]");
      await expect(modifyTransforamtionFromList(publicId, { type: "blur" }, "123")).rejects.toThrow("Transformation failed");
    });

    it("should throw ApiError if transformation not found", async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify([{ id: "999", type: "crop" }]));
      await expect(modifyTransforamtionFromList(publicId, { type: "blur" }, "123")).rejects.toThrow("Transformation not found.");
    });

    it("should modify existing transformation", async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify([{ id: "123", type: "crop" }]));
      
      const result = await modifyTransforamtionFromList(publicId, { type: "blur" }, "123");
      
      expect(result.length).toBe(1);
      expect(result[0].id).toBe("123");
      expect(result[0].type).toBe("blur");
      expect(mockRedis.set).toHaveBeenCalled();
    });
  });

  describe("deleteTransformationFromList", () => {
    it("should throw ApiError if list is empty", async () => {
      mockRedis.get.mockResolvedValue("[]");
      await expect(deleteTransformationFromList(publicId, "123")).rejects.toThrow("Transformation list is already empty");
    });

    it("should throw ApiError if transformation not found", async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify([{ id: "999", type: "crop" }]));
      await expect(deleteTransformationFromList(publicId, "123")).rejects.toThrow("No Effect found");
    });

    it("should remove transformation from list", async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify([{ id: "123", type: "crop" }, { id: "999", type: "blur" }]));
      
      const result = await deleteTransformationFromList(publicId, "123");
      
      expect(result.length).toBe(1);
      expect(result[0].id).toBe("999");
      expect(mockRedis.set).toHaveBeenCalled();
    });
  });
});
