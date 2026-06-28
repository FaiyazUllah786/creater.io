import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  githubCallbackHandler,
  googleCallbackHandler,
  googleMobileAuthHandler,
  githubMobileAuthHandler,
} from "../auth.contrller.js";
import { User } from "../../models/user.model.js";
import { generateAccessRefreshToken } from "../../middlewares/auth.middleware.js";
import axios from "axios";

// Mock dependencies
vi.mock("axios");
vi.mock("../../models/user.model.js", () => ({
  User: {
    findOne: vi.fn(),
    create: vi.fn(),
    findById: vi.fn(),
  },
}));

vi.mock("../../middlewares/auth.middleware.js", () => ({
  generateAccessRefreshToken: vi.fn(),
}));

vi.mock("../../utils/asyncHandler.js", () => ({
  asyncHandler: (fn) => fn,
}));

// Mock google-auth-library
const { mockVerifyIdToken } = vi.hoisted(() => ({
  mockVerifyIdToken: vi.fn(),
}));

vi.mock("google-auth-library", () => ({
  OAuth2Client: class {
    verifyIdToken = mockVerifyIdToken;
  },
}));

describe("AuthController", () => {
  let mockReq;
  let mockRes;
  let mockNext;

  beforeEach(() => {
    vi.clearAllMocks();

    mockReq = {
      user: null,
      body: {},
    };

    mockRes = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn().mockReturnThis(),
      cookie: vi.fn().mockReturnThis(),
      redirect: vi.fn(),
    };

    mockNext = vi.fn();
  });

  describe("githubCallbackHandler", () => {
    it("should redirect to failure if github profile not found", async () => {
      mockReq.user = null;
      await githubCallbackHandler(mockReq, mockRes, mockNext);
      expect(mockRes.redirect).toHaveBeenCalledWith(expect.stringContaining("/auth/failure"));
    });

    it("should handle new github user and redirect", async () => {
      mockReq.user = {
        id: "git123",
        username: "gituser",
        displayName: "Git User",
        photos: [{ value: "photo.jpg" }],
      };

      User.findOne.mockResolvedValue(null); // new user
      User.create.mockResolvedValue({ _id: "newUserId" });
      generateAccessRefreshToken.mockResolvedValue({ accessToken: "access", refreshToken: "refresh" });

      await githubCallbackHandler(mockReq, mockRes, mockNext);

      expect(User.create).toHaveBeenCalledWith(expect.objectContaining({
        githubId: "git123",
        authProvider: "github",
        userName: "gituser",
      }));
      expect(mockRes.cookie).toHaveBeenCalledTimes(2);
      expect(mockRes.redirect).toHaveBeenCalledWith(expect.stringContaining("/"));
    });
  });

  describe("googleCallbackHandler", () => {
    it("should redirect to failure if google profile not found", async () => {
      mockReq.user = null;
      await googleCallbackHandler(mockReq, mockRes, mockNext);
      expect(mockRes.redirect).toHaveBeenCalledWith(expect.stringContaining("/auth/failure"));
    });

    it("should handle existing google user and redirect", async () => {
      mockReq.user = {
        id: "g123",
        displayName: "Google User",
        emails: [{ value: "google@example.com" }],
      };

      User.findOne.mockResolvedValue({ _id: "existingUserId" });
      generateAccessRefreshToken.mockResolvedValue({ accessToken: "access", refreshToken: "refresh" });

      await googleCallbackHandler(mockReq, mockRes, mockNext);

      expect(User.create).not.toHaveBeenCalled();
      expect(generateAccessRefreshToken).toHaveBeenCalledWith("existingUserId");
      expect(mockRes.cookie).toHaveBeenCalledTimes(2);
      expect(mockRes.redirect).toHaveBeenCalledWith(expect.stringContaining("/"));
    });
  });

  describe("googleMobileAuthHandler", () => {
    it("should throw 400 if no idToken provided", async () => {
      mockReq.body = {};
      await expect(googleMobileAuthHandler(mockReq, mockRes, mockNext)).rejects.toThrow("No tokens provided!");
    });

    it("should authenticate and return tokens", async () => {
      mockReq.body = { idToken: "valid_token" };
      const mockPayload = {
        sub: "g123",
        name: "Google User",
        email: "google@example.com",
      };
      mockVerifyIdToken.mockResolvedValue({
        getPayload: () => mockPayload,
      });

      User.findOne.mockResolvedValue({ _id: "existingUserId" });
      generateAccessRefreshToken.mockResolvedValue({ accessToken: "access", refreshToken: "refresh" });
      User.findById.mockReturnValue({ select: vi.fn().mockResolvedValue({ _id: "existingUserId" }) });

      await googleMobileAuthHandler(mockReq, mockRes, mockNext);

      expect(mockVerifyIdToken).toHaveBeenCalledWith(expect.objectContaining({ idToken: "valid_token" }));
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalled();
    });
  });

  describe("githubMobileAuthHandler", () => {
    it("should throw 400 if no code provided", async () => {
      mockReq.body = {};
      await expect(githubMobileAuthHandler(mockReq, mockRes, mockNext)).rejects.toThrow("No code provided");
    });
  });
});
