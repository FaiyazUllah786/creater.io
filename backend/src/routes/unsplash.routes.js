import { Router } from "express";
import { searchPhotos, triggerDownload } from "../controllers/unsplash.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { generalLimiter } from "../middlewares/rateLimit.middleware.js";

const router = Router();

// Protect endpoints with JWT and rate limiting to prevent API exhaustion
router.use(verifyJWT);
router.use(generalLimiter);

router.route("/photos").get(searchPhotos);
router.route("/photos/:photoId/download").post(triggerDownload);

export default router;
