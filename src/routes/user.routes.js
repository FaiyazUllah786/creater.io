import { Router } from "express";
import {
  refreshAccessToken,
  verifyJWT,
} from "../middlewares/auth.middleware.js";
import { upload } from "../middlewares/multer.middleware.js";
import {
  deleteUser,
  getCurrentUser,
  loginUser,
  registerUser,
} from "../controllers/user.controllers.js";

const router = Router();

router
  .route("/auth/register")
  .post(upload.single("profilePhoto"), registerUser);
router.route("/auth/login").post(loginUser);
router.route("/auth/refresh-tokens").post(refreshAccessToken);
router.route("/auth/current-user").get(verifyJWT, getCurrentUser);
router.route("/auth/delete-user").post(verifyJWT, deleteUser);

export default router;
