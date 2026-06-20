import { app } from "./app.js";
import { connectDB } from "./db/db.js";
import { connectRedis } from "./redis/redis.js";
import { ApiError } from "./utils/ApiError.js";
import { validateEnv } from "./utils/validateEnv.js";
import dotenv from "dotenv";

dotenv.config({
  path: ".env",
});

// Validate environment variables before doing anything else
validateEnv();

const startApp = async () => {
  try {
    //Connecting MongoDB
    await connectDB();

    //Connecting Redis
    await connectRedis();

    //initializing app
    app.on("error", (error) => {
      throw new ApiError(400, "Error occured during app initialization", error);
    });
    app.listen(process.env.PORT, () => {
      console.log("Server is running on PORT:", process.env.PORT);
    });
  } catch (error) {
    console.log("App is failed to initialize", error);
    process.exit(1);
  }
};

//Initiating node js server
startApp();
