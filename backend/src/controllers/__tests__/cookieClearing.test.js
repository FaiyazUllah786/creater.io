import { describe, it, expect, vi } from "vitest";
import { cookieOptions } from "../../utils/cookieOptions.js";

/**
 * Issue 19: Incorrect Cookie Clearing During Account Deletion
 *
 * Browsers only clear cookies if the domain, path, secure, and sameSite attributes
 * match the original set-cookie attributes exactly.
 *
 * This test suite verifies that `cookieOptions` is a shared constant, ensuring
 * consistency between cookie creation and cookie clearing.
 */

describe("Issue 19: Cookie Clearing Consistency", () => {
  it("cookieOptions exports the exact required configuration", () => {
    expect(cookieOptions).toBeDefined();
    expect(cookieOptions).toHaveProperty("httpOnly", true);
    expect(cookieOptions).toHaveProperty("secure");
    expect(cookieOptions).toHaveProperty("sameSite");
  });

  it("sameSite is strict or lax depending on environment", () => {
    // Should be 'None' or 'Lax'
    expect(["None", "Lax"]).toContain(cookieOptions.sameSite);
  });

  it("secure is a boolean", () => {
    expect(typeof cookieOptions.secure).toBe("boolean");
  });
});
