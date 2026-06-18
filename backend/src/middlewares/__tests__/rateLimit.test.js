import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import express from "express";
import request from "supertest";
import { authLimiter } from "../rateLimit.middleware.js";

// Helper to create a test app
function createTestApp(limiter) {
  const app = express();
  app.set("trust proxy", 1);
  app.use(limiter);
  app.get("/", (req, res) => res.status(200).json({ success: true }));
  // Custom error handler to catch ApiError thrown by the rate limiter handler
  app.use((err, req, res, next) => {
    res.status(err.statusCode || 500).json({ message: err.message });
  });
  return app;
}

describe("Issue 10: Express Rate Limiting", () => {
  let app;

  beforeEach(() => {
    vi.useFakeTimers();
    // authLimiter allows 5 requests per 15 minutes
    app = createTestApp(authLimiter);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllTimers();
  });

  it("requests below limit succeed", async () => {
    for (let i = 0; i < 5; i++) {
      const res = await request(app).get("/").set("X-Forwarded-For", "192.168.1.1");
      expect(res.status).toBe(200);
    }
  });

  it("requests above limit return 429", async () => {
    // 5 successful requests
    for (let i = 0; i < 5; i++) {
      await request(app).get("/").set("X-Forwarded-For", "192.168.1.2");
    }

    // 6th request should fail
    const res = await request(app).get("/").set("X-Forwarded-For", "192.168.1.2");
    expect(res.status).toBe(429);
    expect(res.body.message).toContain("Too many authentication attempts");
  });

  it("different IPs are isolated", async () => {
    // IP 1 exhausts limit
    for (let i = 0; i < 5; i++) {
      await request(app).get("/").set("X-Forwarded-For", "10.0.0.1");
    }
    const resFail = await request(app).get("/").set("X-Forwarded-For", "10.0.0.1");
    expect(resFail.status).toBe(429);

    // IP 2 should still succeed
    const resSuccess = await request(app).get("/").set("X-Forwarded-For", "10.0.0.2");
    expect(resSuccess.status).toBe(200);
  });

  it("limit resets appropriately after windowMs", async () => {
    // Exhaust limit
    for (let i = 0; i < 5; i++) {
      await request(app).get("/").set("X-Forwarded-For", "172.16.0.1");
    }
    let res = await request(app).get("/").set("X-Forwarded-For", "172.16.0.1");
    expect(res.status).toBe(429);

    // Fast forward 15 minutes + 1 second
    vi.advanceTimersByTime(15 * 60 * 1000 + 1000);

    // Request should succeed again
    res = await request(app).get("/").set("X-Forwarded-For", "172.16.0.1");
    expect(res.status).toBe(200);
  });
});
