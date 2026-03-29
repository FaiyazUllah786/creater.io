import { v2 as cloudinary } from "cloudinary";
import { cloudinaryConfig } from "./config.js";
import { ApiError } from "../../utils/ApiError.js";
import { getRedisInstance } from "../../redis/redis.js";
import { getCurrentList } from "../redisServices/transformation.js";

export const generativeBackgroundReplace = async (imagePublicId, { prompt = "", id: effectId }) => {
  console.log("Prompt is here: ", prompt);

  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  let effect;
  if (prompt.trim() == "") {
    effect = {
      effect: `gen_background_replace`,
    };
  } else {
    effect = {
      effect: `gen_background_replace:prompt_${prompt.trim()}`,
    };
  }
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Failed to generate transformation URL");
  }

  return { resUrl, effect };
};

export const aiImageEnhancer = async (imagePublicId) => {
  cloudinaryConfig();

  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }
  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const effects = transformationList.map(({ effect, ...rest }) => effect);

  console.log(effects, "previousEffects--aiImageEnhancer");
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [
      ...effects,
      {
        effect: "enhance",
      },
    ],
  });

  if (!resUrl) {
    throw new ApiError(400, "Failed to generate transformation URL");
  }

  return {
    resUrl,
    effect: {
      effect: "enhance",
    },
  };
};

export const generativeBackgroundFill = async (
  imagePublicId,
  { id: effectId, aspectRatio, height, width, gravity }
) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }

  if (!aspectRatio && (!height || !width)) {
    throw new ApiError(400, "Either aspect ratio or both height and width are required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = {
    gravity,
    background: "gen_fill",
    crop: "pad",
    ...(height && width ? { width, height } : { aspect_ratio: aspectRatio }),
  };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Failed to generate transformation URL");
  }

  return { resUrl, effect };
};

export const generativeObjectReplace = async (imagePublicId, itemToReplace, replaceWith) => {
  cloudinaryConfig();
  if (!itemToReplace || itemToReplace.trim() == "" || !replaceWith || replaceWith.trim() == "") {
    throw new ApiError(400, "Both item to replace and replace with prompt required");
  }
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }
  const resUrl = cloudinary.url(imagePublicId, {
    effect: `gen_replace:from_${itemToReplace.trim()};to_${replaceWith.trim()}`,
  });
  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while transforming image");
  }
  const transformImageRes = await fetch(resUrl);
  if (transformImageRes.status != 200) {
    throw new ApiError(400, "Something went wrong during image transformation");
  }
  return resUrl;
};

export const generativeObjectRemove = async (imagePublicId, { prompt = "", id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }
  if (!prompt || prompt.trim() == "") {
    throw new ApiError(400, "Prompt is required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: `gen_remove:prompt_${prompt.trim()}` };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while transforming image");
  }

  return { resUrl, effect };
};

export const backgroundRemoval = async (imagePublicId, { id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: "background_removal" };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while background remove");
  }

  return { resUrl, effect };
};

export const generativeRecolor = async (imagePublicId, { prompts, color, id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }
  if (!prompts || prompts.length == 0 || prompts.length > 3) {
    throw new ApiError(400, "Prompts items should not more than 3");
  }
  //splitting prompts and converting to string
  let str = "";
  prompts.forEach((prompt) => {
    str += `${prompt};`;
  });
  console.log("prompts: " + str);

  //validating and optimizing color
  if (!color || color.trim() == "") {
    throw new ApiError(400, "Color is required");
  }
  let hexColor = color.replace("#", "");

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: `gen_recolor:prompt_(${str});to-color_${hexColor};multiple_true` };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while background remove");
  }

  return { resUrl, effect };
};

export const generativeRestore = async (imagePublicId, { id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: "gen_restore" };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while background remove");
  }

  return { resUrl, effect };
};

export const generativeUpscale = async (imagePublicId, { id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: "upscale" };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while background remove");
  }

  return { resUrl, effect };
};

export const contentExtraction = async (imagePublicId, { prompts, id: effectId } = {}) => {
  if (!imagePublicId) {
    throw new ApiError(400, "Image public id is required");
  }
  if (!prompts || prompts.length == 0) {
    throw new ApiError(400, "Prompts items required");
  }
  //splitting prompts and converting to string
  let str = "";
  prompts.forEach((prompt) => {
    str += `${prompt};`;
  });
  console.log("prompts: " + str);

  const redis = getRedisInstance();
  const transformationList = await getCurrentList(redis, imagePublicId);

  const previousEffects = transformationList.reduce((acc, { id, effect }) => {
    if (id !== effectId) acc.push(effect);
    return acc;
  }, []);

  cloudinaryConfig();

  const effect = { effect: `extract:prompt_(${str})` };
  const resUrl = cloudinary.url(imagePublicId, {
    transformation: [...previousEffects, effect],
  });

  if (!resUrl) {
    throw new ApiError(400, "Something went wrong while background remove");
  }

  return { resUrl, effect };
};

export const universalTransformation = async (imagePublicId, transformationList) => {
  cloudinaryConfig();

  let res;

  if (!transformationList || transformationList?.length === 0) {
    res = cloudinary.url(imagePublicId);
    return res;
  }

  const effects = transformationList.map(({ effect, ...rest }) => effect);

  res = cloudinary.url(imagePublicId, { transformation: effects });

  if (!res) {
    throw new ApiError(400, "Something went wrong while transforming image.");
  }

  return res;
};
