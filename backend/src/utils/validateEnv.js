import ms from "ms";

export const validateEnv = () => {
  const errors = [];

  const requiredSecrets = ["ACCESS_TOKEN_SECRET", "REFRESH_TOKEN_SECRET"];
  const requiredExpirys = ["ACCESS_TOKEN_EXPIRY", "REFRESH_TOKEN_EXPIRY"];
  const requiredMongos = ["MONGODB_URI"];

  const placeholderValues = [
    "your_secret",
    "changeme",
    "secret",
    "test",
    "password",
    "123456"
  ];

  for (const secret of requiredSecrets) {
    const value = process.env[secret];
    if (!value || value.trim() === "") {
      errors.push(`Missing or empty environment variable ${secret}`);
      continue;
    }
    if (placeholderValues.includes(value.toLowerCase().trim())) {
      errors.push(`Environment variable ${secret} contains an insecure placeholder value`);
      continue;
    }
    if (value.trim().length < 32) {
      errors.push(`Environment variable ${secret} is too weak (must be at least 32 characters)`);
    }
  }

  for (const expiry of requiredExpirys) {
    const value = process.env[expiry];
    if (!value || value.trim() === "") {
      errors.push(`Missing or empty environment variable ${expiry}`);
      continue;
    }
    const parsed = ms(value);
    if (parsed === undefined || isNaN(parsed) || parsed <= 0) {
      errors.push(`Environment variable ${expiry} contains an invalid time format`);
    }
  }

  // Frontend URL Contract
  // We prefer FRONTEND_URL as the standard, but support CLIENT_URL for backward compatibility.
  // One of them MUST be present and be a valid URL.
  const frontendUrl = process.env.FRONTEND_URL;
  const clientUrl = process.env.CLIENT_URL;

  if ((!frontendUrl || frontendUrl.trim() === "") && (!clientUrl || clientUrl.trim() === "")) {
    errors.push(`Missing or empty environment variable FRONTEND_URL (or CLIENT_URL fallback)`);
  } else {
    try {
      if (frontendUrl && frontendUrl.trim() !== "") new URL(frontendUrl);
      if (clientUrl && clientUrl.trim() !== "") new URL(clientUrl);
    } catch (error) {
      errors.push(`Environment variable FRONTEND_URL/CLIENT_URL is a malformed URL`);
    }
  }

  for (const mongo of requiredMongos) {
    const value = process.env[mongo];

    if (!value || value.trim() === "") {
      errors.push(
        `Missing or empty environment variable ${mongo}`
      );
      continue;
    }

    if (
      !value.startsWith("mongodb://") &&
      !value.startsWith("mongodb+srv://")
    ) {
      errors.push(
        `Environment variable ${mongo} is malformed`
      );
    }
  }

  // Port validation
  const port = process.env.PORT;

  if (!port || !/^\d+$/.test(port)) {
    errors.push("Missing or invalid environment variable PORT");
  } else {
    const parsedPort = Number(port);

    if (parsedPort <= 0 || parsedPort > 65535) {
      errors.push(
        "Environment variable PORT must be between 1 and 65535"
      );
    }
  }


  if (errors.length > 0) {
    throw new Error(`Startup failed due to environment configuration errors:\n- ${errors.join("\n- ")}`);
  }
};
