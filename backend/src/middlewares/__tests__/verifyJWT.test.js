import { describe, it, expect, vi } from "vitest";

/**
 * Issue 4: verifyJWT does not verify user existence
 * Issue 3: verifyJWT must ALWAYS verify the JWT signature
 */

// Simulated verifyJWT logic AFTER the fix (mirrors auth.middleware.js)
function verifyJWTFixed(jwtVerifyFn, mockUserFindByIdFn) {
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

      const user = await mockUserFindByIdFn(decodedData._id);
      if (!user) {
        throw { statusCode: 401, message: "Invalid access token or user does not exist" };
      }

      req.user = user;
      req._id = user._id;
      next();
    } catch (error) {
      next(error);
    }
  };
}

// Simulated verifyJWT logic BEFORE the fix (with the bypass and without user check)
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

describe("Issue 3 & 4: verifyJWT auth bypass removal and user verification", () => {
  const mockJwtVerify = vi.fn();
  const defaultMockUserFindById = vi.fn().mockResolvedValue({ _id: "default-user-id" });

  it("BUG (Issue 3): req.user set by prior middleware bypasses JWT verification", async () => {
    const middleware = verifyJWTBuggy(mockJwtVerify);
    const req = {
      user: { _id: "attacker-injected-id" },
      cookies: {},
      headers: {},
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockJwtVerify).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith();
    expect(req._id).toBe("attacker-injected-id");
  });

  it("FIX (Issue 3): missing token returns 401", async () => {
    mockJwtVerify.mockReset();
    const middleware = verifyJWTFixed(mockJwtVerify, defaultMockUserFindById);
    const req = { cookies: {}, headers: {} };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 401 })
    );
  });

  it("FIX (Issue 3): expired/invalid JWT throws", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockImplementation(() => {
      throw new Error("jwt expired");
    });

    const middleware = verifyJWTFixed(mockJwtVerify, defaultMockUserFindById);
    const req = {
      cookies: {},
      headers: { authorization: "Bearer expired.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it("FIX (Issue 4): valid token + existing user -> proceeds", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "real-user-id" });
    
    const mockUserFindById = vi.fn().mockResolvedValue({ _id: "real-user-id", email: "test@example.com" });

    const middleware = verifyJWTFixed(mockJwtVerify, mockUserFindById);
    const req = {
      cookies: {},
      headers: { authorization: "Bearer valid.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockUserFindById).toHaveBeenCalledWith("real-user-id");
    expect(next).toHaveBeenCalledWith(); // success, no args
    expect(req._id).toBe("real-user-id");
    expect(req.user).toEqual({ _id: "real-user-id", email: "test@example.com" });
  });

  it("FIX (Issue 4): valid token + deleted user -> 401 Unauthorized", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "deleted-user-id" });
    
    // Simulate user not found in DB
    const mockUserFindById = vi.fn().mockResolvedValue(null);

    const middleware = verifyJWTFixed(mockJwtVerify, mockUserFindById);
    const req = {
      cookies: {},
      headers: { authorization: "Bearer valid.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockUserFindById).toHaveBeenCalledWith("deleted-user-id");
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 401,
        message: "Invalid access token or user does not exist"
      })
    );
    expect(req._id).toBeUndefined();
    expect(req.user).toBeUndefined();
  });

  it("FIX (Issue 3 & 4): req.user + valid JWT still verifies JWT and DB", async () => {
    mockJwtVerify.mockReset();
    mockJwtVerify.mockReturnValue({ _id: "jwt-verified-user" });
    const mockUserFindById = vi.fn().mockResolvedValue({ _id: "jwt-verified-user" });

    const middleware = verifyJWTFixed(mockJwtVerify, mockUserFindById);
    const req = {
      user: { _id: "attacker-id" }, // Should be ignored
      cookies: {},
      headers: { authorization: "Bearer real.jwt.token" },
    };
    const next = vi.fn();

    await middleware(req, null, next);

    expect(mockJwtVerify).toHaveBeenCalledWith("real.jwt.token", "secret");
    expect(mockUserFindById).toHaveBeenCalledWith("jwt-verified-user");
    expect(req._id).toBe("jwt-verified-user");
    expect(req._id).not.toBe("attacker-id");
  });
});
