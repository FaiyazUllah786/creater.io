import { app } from "./app.js";
import { connectDB } from "./db/db.js";
import { ApiError } from "./utils/ApiError.js";
import dotenv from "dotenv";

dotenv.config({
  path: ".env",
});

connectDB()
  .then(() => {
    app.on("error", (error) => {
      throw new ApiError(400, "Error occured during app initialization", error);
    });
    app.listen(process.env.PORT, () => {
      console.log("Server is running on PORT:", process.env.PORT);
    });
  })
  .catch((err) => {
    console.log("App is failed to initialize", err);
  });
