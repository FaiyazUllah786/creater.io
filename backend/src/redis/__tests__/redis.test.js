import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { connectRedis, getRedisInstance } from "../redis.js";
import Redis from "ioredis";

vi.mock("ioredis", () => {
  const MockRedis = vi.fn().mockImplementation(function() {
    this.on = vi.fn();
    this.status = "ready";
    return this;
  });
  return { default: MockRedis };
});



describe("Redis Connection Lifecycle", () => {
  let mockOn;

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    // Reset the internal redisClient state by triggering the "end" callback if available
    if (mockOn) {
      const endCall = mockOn.mock.calls.find(call => call[0] === "end");
      if (endCall) {
        endCall[1](); // trigger end
      }
    }
  });

  it("Startup succeeds when Redis connects", async () => {
    Redis.mockImplementation(function() {
      this.on = vi.fn((event, cb) => {
        if (event === "connect") setTimeout(cb, 5);
        if (event === "ready") setTimeout(cb, 5);
      });
      mockOn = this.on;
      return this;
    });

    const client = await connectRedis();
    expect(client).toBeTruthy();
  });

  it("Startup fails if Redis cannot connect during startup", async () => {
    Redis.mockImplementation(function() {
      this.on = vi.fn((event, cb) => {
        if (event === "error") {
          setTimeout(() => cb(new Error("Connection refused")), 5);
        }
      });
      mockOn = this.on;
      return this;
    });

    await expect(connectRedis()).rejects.toMatchObject({
      message: "Failed to initialize Redis during startup",
    });
  });

  it("Runtime errors after startup do not crash the promise or throw synchronously", async () => {
    let errorCallback;
    let readyCallback;

    Redis.mockImplementation(function() {
      this.status = "ready";
      this.on = vi.fn((event, cb) => {
        if (event === "ready") readyCallback = cb;
        if (event === "error") errorCallback = cb;
      });
      mockOn = this.on;
      return this;
    });

    const connectPromise = connectRedis();
    
    await new Promise(r => setTimeout(r, 10));
    
    readyCallback(); // Emit ready
    await connectPromise;

    expect(() => {
      errorCallback(new Error("Runtime disconnect"));
    }).not.toThrow();
  });

  it("redisClient is assigned only after ready and becomes null after end", async () => {
    let readyCallback;
    let endCallback;
    let connectCallback;

    Redis.mockImplementation(function() {
      this.status = "ready";
      this.on = vi.fn((event, cb) => {
        if (event === "connect") connectCallback = cb;
        if (event === "ready") readyCallback = cb;
        if (event === "end") endCallback = cb;
      });
      mockOn = this.on;
      return this;
    });

    const connectPromise = connectRedis();
    await new Promise(r => setTimeout(r, 10));

    // After connect, but before ready, getRedisInstance should throw 503
    connectCallback();
    expect(() => getRedisInstance()).toThrow(/Transformation service temporarily unavailable/);

    // After ready, getRedisInstance should succeed
    readyCallback();
    await connectPromise;
    expect(getRedisInstance()).toBeTruthy();

    // After end, getRedisInstance should throw 503 again
    endCallback();
    expect(() => getRedisInstance()).toThrow(/Transformation service temporarily unavailable/);
  });
});
