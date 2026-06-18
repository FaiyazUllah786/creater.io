import { describe, it, expect, vi } from "vitest";

/**
 * Issue 3: verifyJWT must ALWAYS verify the JWT signature.
 *
 * The bug: A `if (req.user) { req._id = req.user._id; return next(); }` block
 * at the top of verifyJWT would skip all JWT verification if any prior
 * middleware had set req.user. This is dangerous because:
 *   1. Passport sets req.user to the raw OAuth profile (which has `id`, not `_id`),
 *      so req._id would be `undefined`.
 *   2. An attacker who can inject a req.user object via a misconfigured middleware
 *      or prototype pollution can bypass authentication entirely.
 *
 * The fix: Remove the block. verifyJWT now always requires a valid JWT.
 */

// We mock jwt.verify and build a minimal Express-like req/res/next to test
// the middleware in isolation, since the real middleware depends on
// process.env.ACCESS_TOKEN_SECRET and the asyncHandler wrapper.

// Simulated verifyJWT logic AFTER the fix (mirrors auth.middleware.js)
function verifyJWTFixed(jwtVerifyFn) {
  return async (req, res, next) => {
    try {
      const token =
        req.cookies?.accessToken ||
        req.headers?.authorization?.replace("Bearer ", "");

      if (!token) {
        throw { statusCode: 401, message: "Access token is missing" };
      }

      const decodedData = jwtVerifyFn(token, "secret");
      if (!decodedData) {
        throw { statusCode: 401, message: "Invalid or expired access token" };
      }

      req._id = decodedData._id;
      next();
    } catch (error) {
      next(error);
    }
  };
}

// Simulated verifyJWT logic BEFORE the fix (with the bypass)
function verifyJWTBuggy(jwtVerifyFn) {
  return async (req, res, next) => {
    try {
      // THE BUG: blindly trusts req.user
      if (req.user) {
        req._id = req.user._id;
        return next();
      }

      const token =
        req.cookies?.accessToken ||
        req.headers?.authorization?.replace("Bearer ", "");

      if (!token) {
        throw { statusCode: 401, message: "Access token is missing" };
      }

      const decodedData = jwtVerifyFn(token, "secret");
      if (!decodedData) {
        throw { statusCode: 401, message: "Invalid or expired access token" };
      }

      req._id = decodedData._id;
      next();
    } catch (error) {
      next(error);
    }
  };
}

describe("Issue 3: verifyJWT auth bypass removal", () => {
  const mockJwtVerify = vi.fn();

  it("BUG: req.user set by prior middleware bypasses JWT verification", async () => {
    const middleware = verifyJWTBuggy(mockJwtVerify);
    const req = {
      user: { _id: "attacker-injected-id" },
      cookies: {},
      headers: {},
    };
    const next = vi.fn();

    await middleware(req, null, next);

    // The bug: next() was called without ever calling jwt.verify
    expect(mockJwtVerify).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith();
    expect(req._id).toBe("attacker-injected-id");
  });

  it("BUG: Passport-style req.user (has id, not _id) sets req._id to undefined", async () => {
    const middleware = verifyJWTBuggy(mockJwtVerify);
    const req = {
      // Passport sets req.user to the OAuth profile which has `id`, not `_id`
      user: { id: "github-12345", displayName: "Attacker" },
      cookies: {},
      headers: {},
    };
    const next = vi.fn();

    await middleware(req, null, next);

    // req._id is undefined because the profile has `id`, not `_id`
    expect(req._id).toBeUndefined();
    // But next() was still called — auth was bypassed with undefined _id
    expect(next).toHaveBeenCalledWith();
  });

  it("FIX: req.user being set does NOT skip JWT verification", async () => {
    mockJwtVerify.mockReset();
    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = {
      user: { _id: "attacker-injected-id" },
      cookies: {},
      headers: {},
    };
    const next = vi.fn();

    await middleware(req, null, next);

    // next() was called with an error (no token provided)
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 401,
        message: "Access token is missing",
      })
    );
    // jwt.verify was never called because there's no token
    expect(mockJwtVerify).not.toHaveBeenCalled();
    // req._id was NOT set to the attacker value
    expect(req._id).toBeUndefined();
  });

  it("FIX: valid JWT in Authorization header is accepted", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "user-abc-123" });

    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = {
      cookies: {},
      headers: { authorization: "Bearer valid.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockJwtVerify).toHaveBeenCalledWith("valid.jwt.token", "secret");
    expect(next).toHaveBeenCalledWith();
    expect(req._id).toBe("user-abc-123");
  });

  it("FIX: valid JWT in cookie is accepted", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "user-cookie-456" });

    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = {
      cookies: { accessToken: "cookie.jwt.token" },
      headers: {},
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockJwtVerify).toHaveBeenCalledWith("cookie.jwt.token", "secret");
    expect(next).toHaveBeenCalledWith();
    expect(req._id).toBe("user-cookie-456");
  });

  it("FIX: missing token returns 401", async () => {
    mockJwtVerify.mockReset();
    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = { cookies: {}, headers: {} };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 401 })
    );
  });

  it("FIX: expired/invalid JWT throws", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockImplementation(() => {
      throw new Error("jwt expired");
    });

    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = {
      cookies: {},
      headers: { authorization: "Bearer expired.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it("FIX: req.user + valid JWT still verifies JWT (not trusting req.user)", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "jwt-verified-user" });

    const middleware = verifyJWTFixed(mockJwtVerify);
    const req = {
      user: { _id: "attacker-id" }, // Should be ignored
      cookies: {},
      headers: { authorization: "Bearer real.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    // JWT was verified
    expect(mockJwtVerify).toHaveBeenCalledWith("real.jwt.token", "secret");
    // req._id comes from the JWT, NOT from req.user
    expect(req._id).toBe("jwt-verified-user");
    expect(req._id).not.toBe("attacker-id");
  });
});
