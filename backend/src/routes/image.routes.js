import { Router } from "express";
import {
  deleteImage,
  getImageFromDatabase,
  imageUploads,
  saveImageToDatabase,
} from "../controllers/image.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { upload } from "../middlewares/multer.middleware.js";
import {
  addTransformation,
  clearTransformation,
  deleteTransformation,
  updateTransformation,
  saveTransformation,
} from "../controllers/transformation.controller.js";

const router = Router();

//http:localhost:8000/image/upload
router.route("/upload").post(verifyJWT, upload.array("images"), imageUploads);

//http:localhost:8000/image/get-images
router.route("/get-images").get(verifyJWT, getImageFromDatabase);

//http:localhost:8000/image/save-image
router.route("/save-image").post(verifyJWT, saveImageToDatabase);

//http:localhost:8000/image/delete-image
router.route("/delete-image").post(verifyJWT, deleteImage);

//http:localhost:8000/image/add-transformation
router.route("/add-transformation").post(verifyJWT, addTransformation);

//http:localhost:8000/image/update-transformation
router.route("/update-transformation").post(verifyJWT, updateTransformation);

//http:localhost:8000/image/delete-transformation
router.route("/delete-transformation").post(verifyJWT, deleteTransformation);

//http:localhost:8000/image/clear-transformation
router.route("/clear-transformation").post(verifyJWT, clearTransformation);

//http:localhost:8000/image/save
router.route("/save").post(verifyJWT, saveTransformation);

export default router;
