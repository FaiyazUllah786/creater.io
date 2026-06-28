import { describe, it, expect, vi, beforeEach } from "vitest";
import { User } from "../user.model.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

vi.mock("bcryptjs", () => ({
  default: {
    hash: vi.fn(),
    compare: vi.fn(),
  },
}));

vi.mock("jsonwebtoken", () => ({
  default: {
    sign: vi.fn(),
  },
}));

describe("UserModel", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("pre-save hook", () => {
    it("hashes the password if it is modified", async () => {
      const user = new User({
        userName: "testuser",
        email: "test@example.com",
        password: "plainpassword",
      });

      user.isModified = vi.fn().mockReturnValue(true);
      bcrypt.hash.mockResolvedValue("hashedpassword");

      // We only call the pre-save hook function directly for testing
      // since testing via real mongoose save requires a DB connection.
      const preSave = userSchemaPreSaveHook(user);
      const next = vi.fn();
      await preSave.call(user, next);

      expect(bcrypt.hash).toHaveBeenCalledWith("plainpassword", 10);
      expect(user.password).toBe("hashedpassword");
      expect(next).toHaveBeenCalled();
    });

    it("does not hash the password if it is not modified", async () => {
      const user = new User({
        userName: "testuser",
        email: "test@example.com",
        password: "plainpassword",
      });

      // Simulate that password is not modified
      user.isModified = vi.fn().mockReturnValue(false);

      const preSave = userSchemaPreSaveHook(user);
      const next = vi.fn();
      await preSave.call(user, next);

      expect(bcrypt.hash).not.toHaveBeenCalled();
      expect(next).toHaveBeenCalled();
    });
  });

  describe("isPasswordCorrect", () => {
    it("compares the given password with the hashed password", async () => {
      const user = new User({ password: "hashedpassword" });
      bcrypt.compare.mockResolvedValue(true);

      const result = await user.isPasswordCorrect("plainpassword");

      expect(bcrypt.compare).toHaveBeenCalledWith("plainpassword", "hashedpassword");
      expect(result).toBe(true);
    });
  });

  describe("generateAccessToken", () => {
    it("generates an access token with correct payload", () => {
      process.env.ACCESS_TOKEN_SECRET = "access_secret";
      process.env.ACCESS_TOKEN_EXPIRY = "15m";

      const user = new User({
        _id: "userId123",
        userName: "testuser",
        email: "test@example.com",
      });

      jwt.sign.mockReturnValue("access_token");

      const token = user.generateAccessToken();

      expect(jwt.sign).toHaveBeenCalledWith(
        {
          _id: user._id,
          userName: "testuser",
          email: "test@example.com",
        },
        "access_secret",
        {
          expiresIn: "15m",
          algorithm: "HS256",
        }
      );
      expect(token).toBe("access_token");
    });
  });

  describe("generateRefreshToken", () => {
    it("generates a refresh token with correct payload", () => {
      process.env.REFRESH_TOKEN_SECRET = "refresh_secret";
      process.env.REFRESH_TOKEN_EXPIRY = "7d";

      const user = new User({
        _id: "userId123",
      });

      jwt.sign.mockReturnValue("refresh_token");

      const token = user.generateRefreshToken();

      expect(jwt.sign).toHaveBeenCalledWith(
        {
          _id: user._id,
        },
        "refresh_secret",
        {
          expiresIn: "7d",
          algorithm: "HS256",
        }
      );
      expect(token).toBe("refresh_token");
    });
  });
});

// Helper function to extract pre-save hook
function userSchemaPreSaveHook(user) {
  // Accessing the private mongoose hooks
  const preHooks = user.schema.s.hooks._pres.get("save");
  return preHooks.find(h => h.fn.toString().includes("bcrypt.hash") || h.fn.toString().includes("password")).fn;
}
