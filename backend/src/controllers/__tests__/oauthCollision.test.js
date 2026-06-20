import { describe, it, expect, vi } from "vitest";

/**
 * Issue 11: GitHub/Google Synthetic Email Collision Prevention
 *
 * Tests the registration validation logic and OAuth lookup logic
 * to verify that:
 * 1. Reserved synthetic email domains are blocked during registration.
 * 2. Valid emails are accepted.
 * 3. OAuth handlers correctly construct synthetic emails.
 * 4. Cross-provider collisions are prevented.
 */

// ── Registration email validation logic (mirrors user.controllers.js) ──

function validateRegistrationEmail(email) {
  if (!email || email.trim() === "") {
    return { valid: false, code: 422, message: "Email is required" };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return { valid: false, code: 422, message: "Invalid email format" };
  }

  const reservedDomains = ["github.user", "google.user"];
  const emailDomain = email.split("@")[1]?.toLowerCase();
  if (reservedDomains.includes(emailDomain)) {
    return { valid: false, code: 422, message: "This email domain is not allowed for registration" };
  }

  return { valid: true };
}

// ── Synthetic email generation (mirrors auth.contrller.js) ──

function generateGithubSyntheticEmail(githubId) {
  return `${githubId}@github.user`;
}

function generateGoogleSyntheticEmail(googleId) {
  return `${googleId}@google.user`;
}

// ── OAuth user lookup (mirrors auth.contrller.js $or queries) ──

function findUserByOAuth(users, { githubId, googleId, email }) {
  return users.find(
    (u) =>
      (githubId && u.githubId === githubId) ||
      (googleId && u.googleId === googleId) ||
      u.email === email
  ) || null;
}

describe("Issue 11: OAuth Email Collision Prevention", () => {
  // ── Registration Validation ──

  describe("Registration email validation", () => {
    it("accepts valid email addresses", () => {
      expect(validateRegistrationEmail("alice@gmail.com").valid).toBe(true);
      expect(validateRegistrationEmail("user@example.co.uk").valid).toBe(true);
      expect(validateRegistrationEmail("test+tag@domain.com").valid).toBe(true);
    });

    it("rejects empty or missing email", () => {
      expect(validateRegistrationEmail("").valid).toBe(false);
      expect(validateRegistrationEmail(null).valid).toBe(false);
      expect(validateRegistrationEmail(undefined).valid).toBe(false);
      expect(validateRegistrationEmail("  ").valid).toBe(false);
    });

    it("rejects invalid email format", () => {
      expect(validateRegistrationEmail("notanemail").valid).toBe(false);
      expect(validateRegistrationEmail("@missing.local").valid).toBe(false);
      expect(validateRegistrationEmail("missing@").valid).toBe(false);
    });

    it("BLOCKS registration with @github.user domain", () => {
      const result = validateRegistrationEmail("12345@github.user");
      expect(result.valid).toBe(false);
      expect(result.code).toBe(422);
      expect(result.message).toContain("not allowed");
    });

    it("BLOCKS registration with @google.user domain", () => {
      const result = validateRegistrationEmail("67890@google.user");
      expect(result.valid).toBe(false);
      expect(result.code).toBe(422);
      expect(result.message).toContain("not allowed");
    });

    it("blocks reserved domains case-insensitively", () => {
      expect(validateRegistrationEmail("12345@GitHub.User").valid).toBe(false);
      expect(validateRegistrationEmail("12345@GITHUB.USER").valid).toBe(false);
      expect(validateRegistrationEmail("12345@Google.User").valid).toBe(false);
    });
  });

  // ── Synthetic Email Generation ──

  describe("Synthetic email generation", () => {
    it("GitHub generates @github.user emails", () => {
      expect(generateGithubSyntheticEmail("12345")).toBe("12345@github.user");
    });

    it("Google generates @google.user emails (not @github.user)", () => {
      const email = generateGoogleSyntheticEmail("67890");
      expect(email).toBe("67890@google.user");
      expect(email).not.toContain("github");
    });

    it("GitHub and Google with same numeric ID produce different emails", () => {
      const ghEmail = generateGithubSyntheticEmail("99999");
      const goEmail = generateGoogleSyntheticEmail("99999");
      expect(ghEmail).not.toBe(goEmail);
    });
  });

  // ── Cross-Provider Collision Scenarios ──

  describe("OAuth user lookup isolation", () => {
    const existingUsers = [
      { _id: "u1", email: "alice@gmail.com", authProvider: "local" },
      { _id: "u2", email: "12345@github.user", githubId: "12345", authProvider: "github" },
      { _id: "u3", email: "67890@google.user", googleId: "67890", authProvider: "google" },
    ];

    it("GitHub user with matching githubId finds their own account", () => {
      const found = findUserByOAuth(existingUsers, {
        githubId: "12345",
        email: "12345@github.user",
      });
      expect(found._id).toBe("u2");
    });

    it("Google user with matching googleId finds their own account", () => {
      const found = findUserByOAuth(existingUsers, {
        googleId: "67890",
        email: "67890@google.user",
      });
      expect(found._id).toBe("u3");
    });

    it("new GitHub user with unique ID does not collide", () => {
      const found = findUserByOAuth(existingUsers, {
        githubId: "99999",
        email: "99999@github.user",
      });
      expect(found).toBeNull();
    });

    it("Google user with real email matching local user finds local account (implicit linking)", () => {
      // This is the known implicit-linking behavior documented as a tradeoff
      const found = findUserByOAuth(existingUsers, {
        googleId: "new-google-id",
        email: "alice@gmail.com",
      });
      expect(found._id).toBe("u1");
    });

    it("GitHub and Google synthetic emails with same numeric ID do NOT collide", () => {
      const usersWithSameId = [
        { _id: "gh", email: "11111@github.user", githubId: "11111", authProvider: "github" },
        { _id: "go", email: "11111@google.user", googleId: "11111", authProvider: "google" },
      ];

      // GitHub lookup finds GitHub user
      const ghFound = findUserByOAuth(usersWithSameId, {
        githubId: "11111",
        email: "11111@github.user",
      });
      expect(ghFound._id).toBe("gh");

      // Google lookup finds Google user
      const goFound = findUserByOAuth(usersWithSameId, {
        googleId: "11111",
        email: "11111@google.user",
      });
      expect(goFound._id).toBe("go");
    });
  });

  // ── Attack Scenario Tests ──

  describe("Attack scenario: pre-registered synthetic email", () => {
    it("attacker cannot register 12345@github.user via the registration endpoint", () => {
      const result = validateRegistrationEmail("12345@github.user");
      expect(result.valid).toBe(false);
    });

    it("attacker cannot register 67890@google.user via the registration endpoint", () => {
      const result = validateRegistrationEmail("67890@google.user");
      expect(result.valid).toBe(false);
    });

    it("legitimate user with real email can still register", () => {
      const result = validateRegistrationEmail("real.user@protonmail.com");
      expect(result.valid).toBe(true);
    });
  });
});
