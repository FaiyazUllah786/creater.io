import { Router } from "express";
import {
  githubCallbackHandler,
  googleCallbackHandler,
} from "../controllers/auth.contrller.js";
import {
  githubAuthMiddleware,
  githubCallbackMiddleware,
  googleAuthMiddleware,
  googleCallbackMiddleware,
} from "../middlewares/auth.middleware.js";

const router = Router();

router.route("/github").get(githubAuthMiddleware);

router
  .route("/github/callback")
  .get(githubCallbackMiddleware, githubCallbackHandler);

router.route("/google").get(googleAuthMiddleware);

router
  .route("/google/callback")
  .get(googleCallbackMiddleware, googleCallbackHandler);

export default router;
