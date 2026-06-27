import express from "express";
import cookieParser from "cookie-parser";
import cors from "cors";
import dotenv from "dotenv";
import morgan from "morgan";
import { ApiError } from "./utils/ApiError.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import helmet from "helmet";

//import dotenv here cause index.js execute app module first without env
dotenv.config();

const app = express();

app.set("trust proxy", 1);

// Configure HTTP security headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
  })
);

app.use(morgan("dev"));

app.use(cookieParser());

const allowedOrigins = [
  process.env.FRONTEND_URL,
  process.env.CLIENT_URL,
  ...(process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : []),
]
  .filter(Boolean)
  .map((url) => url.trim().replace(/\/$/, "")); // Normalize origins by removing trailing slashes

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps, curl, or server-to-server)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
  })
);

app.use(express.static("../public"));

app.use(express.json({ limit: "16kb" }));

app.use(express.urlencoded({ extended: true, limit: "16kb" }));
//Routers
import userRouter from "./routes/user.routes.js";
import imageRouter from "./routes/image.routes.js";
import authRouter from "./routes/auth.routes.js";
import unsplashRouter from "./routes/unsplash.routes.js";
import { generalLimiter } from "./middlewares/rateLimit.middleware.js";
import healthRouter from "./routes/health.routes.js";

app.use(generalLimiter);

//User Route
app.use("/user", userRouter);
//image Route
app.use("/image", imageRouter);

app.use("/auth", authRouter);

app.use("/unsplash", unsplashRouter);

app.use("/health", healthRouter);

// Catch 404
app.use((req, res, next) => {
  next(new ApiError(404, "Route not found"));
});

// Global Error Handler (Must be at the very end)
app.use(errorHandler);

export { app };
