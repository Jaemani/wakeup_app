const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

// Cloud Function to hash the API key
exports.hashApiKey = functions.https.onCall((data, context) => {
  const apiKey = data.apiKey;

  if (!apiKey) {
    throw new functions.https.HttpsError("invalid-arg", "API key not provided");
  }

  // Hash the API key using SHA-256
  const hashedApiKey = crypto.createHash("sha256").update(apiKey).digest("hex");

  // Simulate a userId based on hashed API key
  const userId = "user_" + hashedApiKey.substring(0, 6); // Example userId

  return {userId, hashedApiKey};
});
