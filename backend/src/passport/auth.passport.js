import passport from "passport";
import dotenv from "dotenv";
import { Strategy as GithubStrategy } from "passport-github2";
import { Strategy as GoogleStrategy } from "passport-google-oauth20";

dotenv.config();

export default function configurePassport() {
  passport.use(
    new GithubStrategy(
      {
        clientID: process.env.GITHUB_CLIENT_ID,
        clientSecret: process.env.GITHUB_CLIENT_SECRET,
        callbackURL: `${process.env.SERVER_URL}/auth/github/callback`,
      },
      (accessToken, refreshToken, profile, done) => {
        // You can store/find the user here
        return done(null, profile);
      }
    )
  );

  passport.use(
    new GoogleStrategy(
      {
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: `${process.env.SERVER_URL}/auth/google/callback`,
      },
      (accessToken, refreshToken, profile, done) => {
        // You can store/find the user here
        return done(null, profile);
      }
    )
  );

  passport.serializeUser((user, done) => {
    done(null, user);
  });

  passport.deserializeUser((user, done) => {
    done(null, user);
  });

  return passport;
}
