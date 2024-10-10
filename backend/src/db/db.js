import mongoose from "mongoose";
import { DB_NAME } from "../constants.js";

export const connectDB = async () => {
  try {
    const connectionInstance = await mongoose.connect(
      `${process.env.MONGODB_URI}`,
      { dbName: DB_NAME },
    );
    console.log(
      `Database connected successfully!!! connection host: ${connectionInstance.connection.host}`,
    );
  } catch (err) {
    console.log(`Error occured during connection of database\n${err}`);
    process.exit(1);
  }
};