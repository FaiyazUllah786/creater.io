import { describe, it, expect } from "vitest";
import { 
  cookieOptions, 
  accessTokenCookieOptions, 
  refreshTokenCookieOptions 
} from "../../utils/cookieOptions.js";

/**
 * Issue 12: Cookie maxAge Missing
 *
 * Verifies that authentication cookies are NOT treated as session cookies.
 * - Access token cookie maxAge matches the 1-hour access token JWT expiry.
 * - Refresh token cookie maxAge matches the 30-day refresh token JWT expiry.
 * - clearCookie uses the base cookieOptions without maxAge to guarantee deletion.
 */

describe("Issue 12: Cookie maxAge Policy", () => {
  it("base cookieOptions does NOT have maxAge (for safe clearing)", () => {
    expect(cookieOptions).not.toHaveProperty("maxAge");
  });

  it("accessTokenCookieOptions enforces a 1-hour maxAge", () => {
    expect(accessTokenCookieOptions).toHaveProperty("maxAge", 60 * 60 * 1000);
    // Should inherit the base secure flags
    expect(accessTokenCookieOptions.httpOnly).toBe(true);
  });

  it("refreshTokenCookieOptions enforces a 30-day maxAge", () => {
    expect(refreshTokenCookieOptions).toHaveProperty("maxAge", 30 * 24 * 60 * 60 * 1000);
    // Should inherit the base secure flags
    expect(refreshTokenCookieOptions.httpOnly).toBe(true);
  });
});
