import { Router } from "express";
import {
  deleteImage,
  getImageFromDatabase,
  imageBackgroundFill,
  imageBackgroundRemoval,
  imageBackgroundReplace,
  imageEnhancer,
  imageObjectExtraction,
  imageObjectRecolor,
  imageObjectRemove,
  imageObjectReplace,
  imageRestore,
  imageUploads,
  imageUpscale,
  saveImageToDatabase,
} from "../controllers/image.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { upload } from "../middlewares/multer.middleware.js";

const router = Router();

//http:localhost:8000/image/upload
router.route("/upload").post(verifyJWT, upload.array("images"), imageUploads);

//http:localhost:8000/image/get-images
router.route("/get-images").get(verifyJWT, getImageFromDatabase);

//http:localhost:8000/image/save-image
router.route("/save-image").post(verifyJWT, saveImageToDatabase);

//http:localhost:8000/image/delete-image
router.route("/delete-image").post(verifyJWT, deleteImage);

//http:localhost:8000/image/background-replace
router.route("/background-replace").post(verifyJWT, imageBackgroundReplace);

//http:localhost:8000/image/enhancer
router.route("/enhancer").post(verifyJWT, imageEnhancer);

//http:localhost:8000/image/generative-fill
router.route("/generative-fill").post(verifyJWT, imageBackgroundFill);

//http:localhost:8000/image/generative-replace
router.route("/generative-replace").post(verifyJWT, imageObjectReplace);

//http:localhost:8000/image/generative-remove
router.route("/generative-remove").post(verifyJWT, imageObjectRemove);

//http:localhost:8000/image/background-removal
router.route("/background-removal").post(verifyJWT, imageBackgroundRemoval);

//http:localhost:8000/image/object-recolor
router.route("/object-recolor").post(verifyJWT, imageObjectRecolor);

//http:localhost:8000/image/image-restore
router.route("/image-restore").post(verifyJWT, imageRestore);

//http:localhost:8000/image/image-upscale
router.route("/image-upscale").post(verifyJWT, imageUpscale);

//http:localhost:8000/image/image-object-extraction
router.route("/image-object-extraction").post(verifyJWT, imageObjectExtraction);

export default router;
