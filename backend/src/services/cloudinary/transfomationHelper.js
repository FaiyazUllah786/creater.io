import { ApiError } from "../../utils/ApiError.js";
import {
  aiImageEnhancer,
  backgroundRemoval,
  contentExtraction,
  generativeBackgroundFill,
  generativeBackgroundReplace,
  generativeObjectRemove,
  generativeObjectReplace,
  generativeRecolor,
  generativeRestore,
  generativeUpscale,
  universalTransformation,
} from "./imageTransformations.js";

export const transformationHelper = (transformation) => {
  const { effectType } = transformation;
  switch (effectType) {
    case "gen_fill":
      return generativeBackgroundFill;
    case "gen_background_replace":
      return generativeBackgroundReplace;
    case "enhance":
      return aiImageEnhancer;
    case "gen_replace":
      return generativeObjectReplace;
    case "gen_remove":
      return generativeObjectRemove;
    case "background_removal":
      return backgroundRemoval;
    case "gen_recolor":
      return generativeRecolor;
    case "gen_restore":
      return generativeRestore;
    case "upscale":
      return generativeUpscale;
    case "extract":
      return contentExtraction;
    case "del_transform":
      return universalTransformation;
    default:
      throw new ApiError(400, `Unknown transformation type: ${effectType}`);
  }
};
