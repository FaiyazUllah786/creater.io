import { describe, it, expect, vi, beforeEach } from "vitest";
import fs from "fs";
import { v2 as cloudinary } from "cloudinary";
import {
  extractPublicId,
  uploadOnCloudinary,
  deleteImageFromCloudinary,
  transformationUsingCloudinary,
} from "../cloudinary.js";

// Mock cloudinary configuration
vi.mock("../config.js", () => ({
  cloudinaryConfig: vi.fn(),
}));

vi.mock("fs", () => ({
  default: {
    existsSync: vi.fn(),
    unlinkSync: vi.fn(),
  }
}));

vi.mock("cloudinary", () => ({
  v2: {
    uploader: {
      upload: vi.fn(),
      destroy: vi.fn(),
    },
    url: vi.fn(),
  },
}));

describe("Cloudinary Service", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("extractPublicId", () => {
    it("should return null if url is falsy", () => {
      expect(extractPublicId(null)).toBeNull();
      expect(extractPublicId("")).toBeNull();
    });

    it("should extract public id without version", () => {
      const url = "http://res.cloudinary.com/demo/image/upload/sample.jpg";
      expect(extractPublicId(url)).toBe("sample");
    });

    it("should extract public id with version", () => {
      const url = "http://res.cloudinary.com/demo/image/upload/v1612345678/sample.jpg";
      expect(extractPublicId(url)).toBe("sample");
    });

    it("should handle complex public ids with folders", () => {
      const url = "http://res.cloudinary.com/demo/image/upload/v1612345678/folder/subfolder/sample.jpg";
      expect(extractPublicId(url)).toBe("folder/subfolder/sample");
    });

    it("should return null for invalid urls", () => {
      const url = "http://example.com/image.jpg";
      expect(extractPublicId(url)).toBeNull();
    });
  });

  describe("uploadOnCloudinary", () => {
    const localFilePath = "path/to/test/image.jpg";

    it("should return null if localFilePath is falsy", async () => {
      const result = await uploadOnCloudinary(null);
      expect(result).toBeNull();
    });

    it("should upload image and return response", async () => {
      const mockResponse = { secure_url: "url", public_id: "id" };
      cloudinary.uploader.upload.mockResolvedValue(mockResponse);
      fs.existsSync.mockReturnValue(true);

      const result = await uploadOnCloudinary(localFilePath);

      expect(cloudinary.uploader.upload).toHaveBeenCalledWith(localFilePath, {
        upload_preset: "creater.io",
        resource_type: "image",
        allowed_formats: ["jpg", "png", "webp", "jpeg"],
      });
      expect(fs.existsSync).toHaveBeenCalledWith(localFilePath);
      expect(fs.unlinkSync).toHaveBeenCalledWith(localFilePath);
      expect(result).toEqual(mockResponse);
    });

    it("should throw ApiError if upload fails and remove local file", async () => {
      cloudinary.uploader.upload.mockRejectedValue(new Error("Upload failed"));
      fs.existsSync.mockReturnValue(true);

      await expect(uploadOnCloudinary(localFilePath)).rejects.toThrow("File failed to upload,Something went wrong");

      expect(fs.unlinkSync).toHaveBeenCalledWith(localFilePath);
    });
  });

  describe("deleteImageFromCloudinary", () => {
    it("should return null if imagePublicId is falsy", async () => {
      const result = await deleteImageFromCloudinary(null);
      expect(result).toBeNull();
    });

    it("should delete image and return response", async () => {
      const mockResponse = { result: "ok" };
      cloudinary.uploader.destroy.mockResolvedValue(mockResponse);

      const result = await deleteImageFromCloudinary("public_id");

      expect(cloudinary.uploader.destroy).toHaveBeenCalledWith("public_id");
      expect(result).toEqual(mockResponse);
    });

    it("should throw ApiError if deletion fails", async () => {
      cloudinary.uploader.destroy.mockRejectedValue(new Error("Delete failed"));
      await expect(deleteImageFromCloudinary("public_id")).rejects.toThrow("File failed to delete,Something went wrong");
    });
  });

  describe("transformationUsingCloudinary", () => {
    it("should return null if imagePublicId is falsy", async () => {
      const result = await transformationUsingCloudinary(null, [{ width: 100 }]);
      expect(result).toBeNull();
    });

    it("should apply transformation and return url", async () => {
      const mockUrl = "transformed_url";
      cloudinary.url.mockReturnValue(mockUrl);

      const result = await transformationUsingCloudinary("public_id", [{ width: 100 }]);

      expect(cloudinary.url).toHaveBeenCalledWith("public_id", {
        transformation: [{ width: 100 }]
      });
      expect(result).toEqual(mockUrl);
    });

    it("should throw ApiError if url generation fails", async () => {
      cloudinary.url.mockImplementation(() => {
        throw new Error("Transformation failed");
      });

      await expect(transformationUsingCloudinary("public_id", [{ width: 100 }])).rejects.toThrow("Failed to apply transformation");
    });
  });
});
