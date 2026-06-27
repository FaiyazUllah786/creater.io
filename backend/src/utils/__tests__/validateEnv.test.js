import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { validateEnv } from "../validateEnv.js";

describe("validateEnv", () => {
  let originalEnv;

  beforeEach(() => {
    // Clone environment variables
    originalEnv = { ...process.env };
    
    // Set a valid baseline (32+ chars for secrets)
    process.env.ACCESS_TOKEN_SECRET = "12345678901234567890123456789012";
    process.env.REFRESH_TOKEN_SECRET = "abcdefghijklmnopqrstuvwxyz123456";
    process.env.ACCESS_TOKEN_EXPIRY = "1h";
    process.env.REFRESH_TOKEN_EXPIRY = "30d";
    process.env.FRONTEND_URL = "http://localhost:3000";
    process.env.CLIENT_URL = "http://localhost:5173";
    process.env.MONGODB_URI = "mongodb://localhost:27017";
    process.env.PORT = "3000";
  });

  afterEach(() => {
    // Restore environment variables
    process.env = originalEnv;
  });

  it("passes with a completely valid configuration", () => {
    expect(() => validateEnv()).not.toThrow();
  });

  it("fails if a required secret is missing", () => {
    delete process.env.ACCESS_TOKEN_SECRET;
    expect(() => validateEnv()).toThrow(/Missing or empty environment variable ACCESS_TOKEN_SECRET/);
  });

  it("fails if a required secret contains a placeholder value", () => {
    process.env.REFRESH_TOKEN_SECRET = "changeme";
    expect(() => validateEnv()).toThrow(/Environment variable REFRESH_TOKEN_SECRET contains an insecure placeholder value/);
  });

  it("fails if a secret is less than 32 characters", () => {
    process.env.ACCESS_TOKEN_SECRET = "too_short_secret";
    expect(() => validateEnv()).toThrow(/must be at least 32 characters/);
  });

  it("fails if expiry time format is invalid", () => {
    process.env.ACCESS_TOKEN_EXPIRY = "invalid_format";
    expect(() => validateEnv()).toThrow(/Environment variable ACCESS_TOKEN_EXPIRY contains an invalid time format/);
  });

  it("fails if expiry time is negative", () => {
    process.env.REFRESH_TOKEN_EXPIRY = "-1h";
    expect(() => validateEnv()).toThrow(/Environment variable REFRESH_TOKEN_EXPIRY contains an invalid time format/);
  });

  it("fails if URLs are malformed", () => {
    process.env.FRONTEND_URL = "not_a_valid_url";
    expect(() => validateEnv()).toThrow(/Environment variable FRONTEND_URL\/CLIENT_URL is a malformed URL/);
  });

  it("passes if CLIENT_URL is valid but FRONTEND_URL is missing", () => {
    delete process.env.FRONTEND_URL;
    process.env.CLIENT_URL = "http://localhost:5173";
    expect(() => validateEnv()).not.toThrow();
  });

  it("fails if MongoDB URI is missing", () => {
    process.env.MONGODB_URI = "   ";
    expect(() => validateEnv()).toThrow(/Missing or empty environment variable MONGODB_URI/);
  });

  it("fails if PORT is invalid", () => {
    process.env.PORT = "abc";
    expect(() => validateEnv()).toThrow(/PORT/);
  });

  it("aggregates multiple errors", () => {
    delete process.env.ACCESS_TOKEN_SECRET;
    process.env.REFRESH_TOKEN_EXPIRY = "invalid";
    process.env.PORT = "99999";

    try {
      validateEnv();
      // Should not reach here
      expect(true).toBe(false);
    } catch (e) {
      expect(e.message).toContain("ACCESS_TOKEN_SECRET");
      expect(e.message).toContain("REFRESH_TOKEN_EXPIRY");
      expect(e.message).toContain("PORT");
    }
  });
});
