import { describe, it, expect, vi, beforeEach } from "vitest";
import { githubCallbackHandler } from "../auth.contrller.js";
import { User } from "../../models/user.model.js";

/**
 * Issue 5: Duplicate Refresh Token Save
 *
 * Verifies that OAuth handlers persist the refresh token EXACTLY once
 * instead of redundantly saving an older memory reference of the user object
 * and triggering double database writes or race conditions.
 */

describe("Issue 5: Duplicate Refresh Token Save Prevention", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("OAuth login triggers exactly one user.save() for existing users", async () => {
    // Mock existing user
    const mockUser = {
      _id: "testUserId123",
      githubId: "git_123",
      generateAccessToken: vi.fn().mockReturnValue("mockAccess"),
      generateRefreshToken: vi.fn().mockReturnValue("mockRefresh"),
      save: vi.fn().mockImplementation(() => {
        console.log("SAVE WAS CALLED");
        return Promise.resolve(true);
      }),
    };

    // 1. First lookup in controller
    const findOneSpy = vi.spyOn(User, "findOne").mockResolvedValue(mockUser);
    
    // 2. Lookup inside generateAccessRefreshToken
    const findByIdSpy = vi.spyOn(User, "findById").mockResolvedValue(mockUser);

    // Mock Express Req/Res
    const req = {
      user: {
        id: "git_123",
        username: "testuser",
        displayName: "Test User",
        photos: [{ value: "photo.jpg" }],
      },
    };

    const res = {
      cookie: vi.fn().mockReturnThis(),
    };

    // Wait for the handler to complete by hooking into redirect
    await new Promise((resolve, reject) => {
      res.redirect = vi.fn().mockImplementation(() => {
        resolve();
      });
      
      githubCallbackHandler(req, res, (err) => {
        if (err) reject(err);
      });
    });

    // Assertions
    expect(findOneSpy).toHaveBeenCalledTimes(1);
    expect(findByIdSpy).toHaveBeenCalledTimes(1);
    
    expect(res.redirect).not.toHaveBeenCalledWith(expect.stringContaining("failure"));

    // The critical assertion: Save must be called exactly once (by generateAccessRefreshToken)
    expect(mockUser.save).toHaveBeenCalledTimes(1);
    expect(mockUser.refreshToken).toBe("mockRefresh");
    
    expect(res.cookie).toHaveBeenCalledWith("refreshToken", "mockRefresh", expect.any(Object));
  });

  it("OAuth registration triggers exactly two saves (User.create + generateAccessRefreshToken)", async () => {
    // Mock that user does NOT exist
    vi.spyOn(User, "findOne").mockResolvedValue(null);

    const mockNewUser = {
      _id: "newUserId123",
      generateAccessToken: vi.fn().mockReturnValue("mockAccess"),
      generateRefreshToken: vi.fn().mockReturnValue("mockRefresh"),
      save: vi.fn().mockResolvedValue(true),
    };

    // Mock User.create to return the new user
    const createSpy = vi.spyOn(User, "create").mockResolvedValue(mockNewUser);
    
    // generateAccessRefreshToken calls findById
    vi.spyOn(User, "findById").mockResolvedValue(mockNewUser);

    const req = {
      user: {
        id: "git_999",
        username: "newuser",
      },
    };

    const res = {
      cookie: vi.fn().mockReturnThis(),
    };

    await new Promise((resolve, reject) => {
      res.redirect = vi.fn().mockImplementation(() => {
        resolve();
      });
      
      githubCallbackHandler(req, res, (err) => {
        if (err) reject(err);
      });
    });

    expect(createSpy).toHaveBeenCalledTimes(1);
    // User.create internally performs a save/insert.
    // generateAccessRefreshToken performs the second save for the token.
    expect(mockNewUser.save).toHaveBeenCalledTimes(1);
  });
});
