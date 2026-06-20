import mongoose from "mongoose";

const schema = new mongoose.Schema({ name: String, email: String });
const Test = mongoose.model("Test", schema);

const query = Test.findOne({ $or: [] });
console.log(JSON.stringify(query.getQuery()));
