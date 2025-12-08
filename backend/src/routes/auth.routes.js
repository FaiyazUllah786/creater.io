import { Router } from "express";
import { githubCallbackHandler } from "../controllers/auth.contrller.js";
import {
  githubAuthMiddleware,
  githubCallbackMiddleware,
} from "../middlewares/auth.middleware.js";

const router = Router();

router.route("/github").get(githubAuthMiddleware);

router
  .route("/github/callback")
  .get(githubCallbackMiddleware, githubCallbackHandler);

export default router;
