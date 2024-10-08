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
  logoutUser,
  registerUser,
  updatePassword,
  updateUserProfile,
  updateUserProfilePhoto,
} from "../controllers/user.controllers.js";

const router = Router();

//http://localhost:8000/user/auth/register
router
  .route("/auth/register")
  .post(upload.single("profilePhoto"), registerUser);

//http://localhost:8000/user/auth/login
router.route("/auth/login").post(loginUser);

//http://localhost:8000/user/auth/logout
router.route("/auth/logout").post(verifyJWT, logoutUser);

//http://localhost:8000/user/auth/refresh-token
router.route("/auth/refresh-tokens").post(refreshAccessToken);

//http://localhost:8000/user/current-user
router.route("/current-user").get(verifyJWT, getCurrentUser);

//http://localhost:8000/user/delete-user
router.route("/delete-user").post(verifyJWT, deleteUser);

//http://localhost:8000/user/profile-photo
router
  .route("/profile-photo")
  .post(verifyJWT, upload.single("profilePhoto"), updateUserProfilePhoto);

//http://localhost:8000/user/update-account
router.route("/update-account").post(verifyJWT, updateUserProfile);

//http://localhost:8000/user/update-password
router.route("/update-password").post(verifyJWT, updatePassword);

export default router;
