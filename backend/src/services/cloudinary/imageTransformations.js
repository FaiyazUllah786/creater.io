import { v2 as cloudinary } from "cloudinary";
import { cloudinaryConfig } from "./config.js";
import { ApiError } from "../../utils/ApiError.js";

export const generativeBackgroundReplace = async (
  imagePublicId,
  prompt = ""
) => {
  try {
    cloudinaryConfig();
    console.log("Prompt is here: ", prompt);

    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    let res;
    if (prompt.trim() == "") {
      res = cloudinary.url(imagePublicId, {
        effect: `gen_background_replace`,
      });
    } else {
      console.log("I am transforming here");
      res = cloudinary.url(
        imagePublicId,
        transformations[
          {
            effect: `gen_background_replace:prompt_${prompt.trim()}`,
          }
        ]
      );
    }
    if (!res) {
      throw new ApiError(400, "Something went wrong while transforming image");
    }
    const transformImageRes = await fetch(res);
    console.log(transformImageRes);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image transformation"
      );
    }
    return res;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const aiImageEnhancer = async (imagePublicId) => {
  try {
    cloudinaryConfig();

    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    const res = cloudinary.url(imagePublicId, { effect: "enhance" });
    if (!res) {
      throw new ApiError(400, "Something went wrong while enhancing image");
    }
    const transformImageRes = await fetch(res);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image transformation"
      );
    }
    return res;
  } catch (error) {
    console.log("Something went wrong while enhancing image");
    throw error;
  }
};

export const generativeBackgroundFill = async (
  imagePublicId,
  aspectRatio,
  height,
  width,
  gravity
) => {
  try {
    cloudinaryConfig();

    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    let resUrl;
    if (height && width) {
      resUrl = cloudinary.url(imagePublicId, {
        width: width,
        height: height,
        gravity: gravity,
        background: "gen_fill",
        crop: "pad",
      });
    } else {
      resUrl = cloudinary.url(imagePublicId, {
        aspect_ratio: aspectRatio,
        gravity: gravity,
        background: "gen_fill",
        crop: "pad",
      });
    }
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while transforming image");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image transformation"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const generativeObjectReplace = async (
  imagePublicId,
  itemToReplace,
  replaceWith
) => {
  try {
    cloudinaryConfig();
    if (
      !itemToReplace ||
      itemToReplace.trim() == "" ||
      !replaceWith ||
      replaceWith.trim() == ""
    ) {
      throw new ApiError(
        400,
        "Both item to replace and replace with prompt required"
      );
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
      throw new ApiError(
        400,
        "Something went wrong during image transformation"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const generativeObjectRemove = async (imagePublicId, prompt) => {
  try {
    cloudinaryConfig();
    if (!prompt || prompt.trim() == "") {
      throw new ApiError(400, "Prompt is required");
    }
    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    const resUrl = cloudinary.url(imagePublicId, {
      effect: `gen_remove:prompt_${prompt.trim()}`,
    });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while transforming image");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image transformation"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const backgroundRemoval = async (imagePublicId) => {
  try {
    cloudinaryConfig();
    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    const resUrl = cloudinary.url(imagePublicId, {
      effect: "background_removal",
    });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while background remove");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image background remove"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const generativeRecolor = async (imagePublicId, prompts, color) => {
  try {
    cloudinaryConfig();
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

    const resUrl = cloudinary.url(imagePublicId, {
      effect: `gen_recolor:prompt_(${str});to-color_${hexColor};multiple_true`,
    });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while background remove");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image background remove"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const generativeRestore = async (imagePublicId) => {
  try {
    cloudinaryConfig();
    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    const resUrl = cloudinary.url(imagePublicId, { effect: "gen_restore" });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while background remove");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image background remove"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const generativeUpscale = async (imagePublicId) => {
  try {
    cloudinaryConfig();
    if (!imagePublicId) {
      throw new ApiError(400, "Image public id is required");
    }
    const resUrl = cloudinary.url(imagePublicId, { effect: "upscale" });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while background remove");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image background remove"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};

export const contentExtraction = async (imagePublicId, prompts) => {
  try {
    cloudinaryConfig();
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

    const resUrl = cloudinary.url(imagePublicId, {
      effect: `extract:prompt_(${str})`,
    });
    if (!resUrl) {
      throw new ApiError(400, "Something went wrong while background remove");
    }
    const transformImageRes = await fetch(resUrl);
    if (transformImageRes.status != 200) {
      throw new ApiError(
        400,
        "Something went wrong during image background remove"
      );
    }
    return resUrl;
  } catch (error) {
    console.log("Something went wrong while transforming image");
    throw error;
  }
};
