import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  registerUser,
  loginUser,
  logoutUser,
  getCurrentUser,
  deleteUser,
  updateUserProfilePhoto,
  updateUserProfile,
  updatePassword,
} from "../user.controllers.js";
import { User } from "../../models/user.model.js";
import { Image } from "../../models/image.model.js";
import {
  uploadOnCloudinary,
  deleteImageFromCloudinary,
  extractPublicId,
} from "../../services/cloudinary/cloudinary.js";
import { generateAccessRefreshToken } from "../../middlewares/auth.middleware.js";

vi.mock("../../models/user.model.js", () => ({
  User: {
    findOne: vi.fn(),
    create: vi.fn(),
    findById: vi.fn(),
    deleteOne: vi.fn(),
    findByIdAndUpdate: vi.fn(),
    updateOne: vi.fn(),
  },
}));

vi.mock("../../models/image.model.js", () => ({
  Image: {
    find: vi.fn(),
    deleteMany: vi.fn(),
  },
}));

vi.mock("../../services/cloudinary/cloudinary.js", () => ({
  uploadOnCloudinary: vi.fn(),
  deleteImageFromCloudinary: vi.fn(),
  extractPublicId: vi.fn(),
}));

vi.mock("../../middlewares/auth.middleware.js", () => ({
  generateAccessRefreshToken: vi.fn(),
}));

vi.mock("../../utils/asyncHandler.js", () => ({
  asyncHandler: (fn) => fn,
}));

describe("UserController", () => {
  let mockReq;
  let mockRes;
  let mockNext;

  beforeEach(() => {
    vi.clearAllMocks();

    mockReq = {
      body: {},
      file: {},
      cookies: {},
      user: {},
      _id: "userId123",
    };

    mockRes = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn().mockReturnThis(),
      cookie: vi.fn().mockReturnThis(),
      clearCookie: vi.fn().mockReturnThis(),
    };

    mockNext = vi.fn();
  });

  describe("registerUser", () => {
    it("should throw 422 if username is missing", async () => {
      mockReq.body = { email: "test@example.com", password: "password123" };
      await expect(registerUser(mockReq, mockRes, mockNext)).rejects.toThrow("Username is required");
    });

    it("should throw 422 if email is missing", async () => {
      mockReq.body = { userName: "testuser", password: "password123" };
      await expect(registerUser(mockReq, mockRes, mockNext)).rejects.toThrow("Email is required");
    });

    it("should throw 422 if email domain is reserved", async () => {
      mockReq.body = { userName: "testuser", email: "test@github.user", password: "password123" };
      await expect(registerUser(mockReq, mockRes, mockNext)).rejects.toThrow("This email domain is not allowed");
    });

    it("should register user successfully without profile photo", async () => {
      mockReq.body = { userName: "testuser", email: "test@example.com", password: "password123" };
      mockReq.file = undefined;

      User.findOne.mockResolvedValue(null);
      User.create.mockResolvedValue({ _id: "newUserId" });
      
      const mockSelect = vi.fn().mockResolvedValue({ _id: "newUserId", userName: "testuser" });
      User.findById.mockReturnValue({ select: mockSelect });

      await registerUser(mockReq, mockRes, mockNext);

      expect(User.create).toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(201);
      expect(mockRes.json).toHaveBeenCalled();
    });
  });

  describe("loginUser", () => {
    it("should throw 422 if no username or email provided", async () => {
      mockReq.body = { password: "password123" };
      await expect(loginUser(mockReq, mockRes, mockNext)).rejects.toThrow("Username or email is required");
    });

    it("should login user successfully", async () => {
      mockReq.body = { userName: "testuser", password: "password123" };
      const mockUser = {
        _id: "userId123",
        isPasswordCorrect: vi.fn().mockResolvedValue(true),
      };
      
      User.findOne.mockResolvedValue(mockUser);
      generateAccessRefreshToken.mockResolvedValue({ accessToken: "access", refreshToken: "refresh" });
      
      const mockSelect = vi.fn().mockResolvedValue({ _id: "userId123", userName: "testuser" });
      User.findById.mockReturnValue({ select: mockSelect });

      await loginUser(mockReq, mockRes, mockNext);
      
      expect(mockUser.isPasswordCorrect).toHaveBeenCalledWith("password123");
      expect(generateAccessRefreshToken).toHaveBeenCalledWith("userId123");
      expect(mockRes.cookie).toHaveBeenCalledTimes(2);
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalled();
    });

    it("should throw 400 for incorrect password", async () => {
      mockReq.body = { userName: "testuser", password: "wrongpassword" };
      const mockUser = {
        _id: "userId123",
        isPasswordCorrect: vi.fn().mockResolvedValue(false),
      };
      
      User.findOne.mockResolvedValue(mockUser);

      await expect(loginUser(mockReq, mockRes, mockNext)).rejects.toThrow("Incorrect password");
    });
  });

  describe("logoutUser", () => {
    it("should logout successfully", async () => {
      const mockUser = {
        _id: "userId123",
        save: vi.fn().mockResolvedValue(true),
      };
      User.findById.mockResolvedValue(mockUser);

      await logoutUser(mockReq, mockRes, mockNext);

      expect(mockUser.refreshToken).toBeNull();
      expect(mockUser.save).toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(200);
    });
  });

  describe("getCurrentUser", () => {
    it("should return current user", async () => {
      mockReq.user = { userName: "testuser" };
      await getCurrentUser(mockReq, mockRes, mockNext);
      
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalled();
    });
  });
});
