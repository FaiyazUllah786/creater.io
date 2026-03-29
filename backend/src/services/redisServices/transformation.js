import { getRedisInstance } from "../../redis/redis.js";
import { ApiError } from "../../utils/ApiError.js";

export const getCurrentList = async (redis, publicId) => {
  let list = [];

  const redisList = await redis.get(publicId);
  if (redisList === null) {
    await redis.set(publicId, JSON.stringify(list), "EX", 1800);
    return list;
  }
  return JSON.parse(redisList);
};

export const clearTransformationList = async (publicId) => {
  const redis = getRedisInstance();

  const exist = await redis.exists(publicId);

  if (exist == 0) {
    throw new ApiError(400, "Transformation list does not exists.");
  }

  const res = await redis.del(publicId);

  if (res?.status === 0) {
    throw new ApiError(400, "Clearing transformation list failed.");
  }

  return [];
};

export const addTransformationToList = async (publicId, transformation) => {
  const redis = getRedisInstance();

  const transformationList = await getCurrentList(redis, publicId);

  transformationList.push({ id: crypto.randomUUID(), ...transformation });

  await redis.set(publicId, JSON.stringify(transformationList), "EX", 1800);

  return transformationList;
};

export const modifyTransforamtionFromList = async (publicId, transformation, transformationId) => {
  const redis = getRedisInstance();

  if (!transformationId) {
    throw new ApiError(400, "Transformation id is required.");
  }

  const transformationList = await getCurrentList(redis, publicId);

  if (!transformationList || transformationList.length === 0) {
    throw new ApiError(400, "Transformation failed");
  }

  const itemExists = transformationList.some((item) => item?.id === transformationId);
  if (!itemExists) {
    throw new ApiError(400, "Transformation not found.");
  }

  const updatedList = transformationList.map((item) =>
    item?.id === transformationId ? { ...transformation, id: transformationId } : item
  );

  await redis.set(publicId, JSON.stringify(updatedList), "EX", 1800);

  return updatedList;
};

export const deleteTransformationFromList = async (publicId, transformationId) => {
  const redis = getRedisInstance();

  const transformationList = await getCurrentList(redis, publicId);

  if (!transformationList || transformationList.length === 0) {
    throw new ApiError(400, "Transformation list is already empty");
  }

  const effectFound = transformationList.find((item) => item?.id === transformationId);
  if (!effectFound) {
    throw new ApiError(400, "No Effect found");
  }
  const updatedList = transformationList.filter((item) => item?.id != transformationId);

  await redis.set(publicId, JSON.stringify(updatedList), "EX", 1800);

  return updatedList;
};
