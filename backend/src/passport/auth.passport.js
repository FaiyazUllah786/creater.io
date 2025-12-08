import passport from "passport";
import dotenv from "dotenv";
import { Strategy as GithubStrategy } from "passport-github2";

dotenv.config();

export default function configurePassport() {
  passport.use(
    new GithubStrategy(
      {
        clientID: process.env.GITHUB_CLIENT_ID,
        clientSecret: process.env.GITHUB_CLIENT_SECRET,
        callbackURL: "http://localhost:3000/auth/github/callback",
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
