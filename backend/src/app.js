import express from "express";
import cookieParser from "cookie-parser";
import cors from "cors";

const app = express();

app.use(cookieParser());

app.use(
  cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true,
  })
);

app.use(express.static("../public"));

app.use(express.json({ limit: "16kb" }));

app.use(express.urlencoded({ extended: true, limit: "16kb" }));
//Routers
import userRouter from "./routes/user.routes.js";
import imageRouter from "./routes/image.routes.js";
//User Route
app.use("/user", userRouter);
//image Route
app.use("/image", imageRouter);
export { app };
