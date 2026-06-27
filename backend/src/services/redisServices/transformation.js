import { getRedisInstance } from "../../redis/redis.js";
import { ApiError } from "../../utils/ApiError.js";

const TTL_SECONDS = 7200; // 2 hours

const getRedisKey = (publicId) => `transformation:${publicId}`;

export const getCurrentList = async (redis, publicId) => {
  let list = [];

  const redisKey = getRedisKey(publicId);
  const redisList = await redis.get(redisKey);
  if (redisList === null) {
    await redis.set(redisKey, JSON.stringify(list), "EX", TTL_SECONDS);
    return list;
  }
  
  // Refresh the TTL on read to prevent expiration during active editing
  await redis.expire(redisKey, TTL_SECONDS);
  
  return JSON.parse(redisList);
};

export const clearTransformationList = async (publicId) => {
  const redis = getRedisInstance();

  const redisKey = getRedisKey(publicId);
  const exist = await redis.exists(redisKey);

  if (exist == 0) {
    throw new ApiError(400, "Transformation list does not exists.");
  }

  const res = await redis.del(redisKey);

  if (res?.status === 0) {
    throw new ApiError(400, "Clearing transformation list failed.");
  }

  return [];
};

export const addTransformationToList = async (publicId, transformation) => {
  const redis = getRedisInstance();

  const transformationList = await getCurrentList(redis, publicId);

  transformationList.push({ id: crypto.randomUUID(), ...transformation });

  await redis.set(getRedisKey(publicId), JSON.stringify(transformationList), "EX", TTL_SECONDS);

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

  await redis.set(getRedisKey(publicId), JSON.stringify(updatedList), "EX", TTL_SECONDS);

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

  await redis.set(getRedisKey(publicId), JSON.stringify(updatedList), "EX", TTL_SECONDS);

  return updatedList;
};
