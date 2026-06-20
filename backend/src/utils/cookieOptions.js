import ms from "ms";

const accessExpiry = process.env.ACCESS_TOKEN_EXPIRY || "1h";
const refreshExpiry = process.env.REFRESH_TOKEN_EXPIRY || "30d";

export const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: process.env.NODE_ENV === "production" ? "None" : "Lax",
};

export const accessTokenCookieOptions = {
  ...cookieOptions,
  maxAge: ms(accessExpiry), // 1 hour (aligns with ACCESS_TOKEN_EXPIRY)
};

export const refreshTokenCookieOptions = {
  ...cookieOptions,
  maxAge: ms(refreshExpiry), // 30 days (aligns with REFRESH_TOKEN_EXPIRY)
};
