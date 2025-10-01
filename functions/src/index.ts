import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const NAVER_CLIENT_ID = process.env.NAVER_CLIENT_ID;
const NAVER_CLIENT_SECRET = process.env.NAVER_CLIENT_SECRET;

export const naverAuth = functions.https.onRequest(
  async (request, response) => {
    try {
      const naverAccessToken = request.body.token;
      if (!naverAccessToken) {
        functions.logger.error("Naver access token not provided.");
        response.status(400).send({error: "Naver token not provided."});
        return;
      }

      const profileResponse = await axios.get(
        "https://openapi.naver.com/v1/nid/me",
        {
          headers: {
            'Authorization': `Bearer ${naverAccessToken}`,
            'X-Naver-Client-Id': NAVER_CLIENT_ID,
            'X-Naver-Client-Secret': NAVER_CLIENT_SECRET,
          },
        },
      );

      const naverProfile = profileResponse.data.response;
      const naverUserId = naverProfile.id;

      if (!naverUserId) {
        throw new Error("Failed to get Naver user ID from profile API.");
      }

      const firebaseToken = await admin.auth().createCustomToken(
        naverUserId, {
          email: naverProfile.email,
          name: naverProfile.name,
          profileImage: naverProfile.profile_image,
        });

      response.status(200).send({firebase_token: firebaseToken});
    } catch (error: any) {
      functions.logger.error("--- DETAILED AUTHENTICATION ERROR ---");
      functions.logger.error("1. Loaded NAVER_CLIENT_ID:", NAVER_CLIENT_ID ? `...${NAVER_CLIENT_ID.slice(-4)}` : "!!! NOT LOADED !!!");
      functions.logger.error("2. Loaded NAVER_CLIENT_SECRET:", NAVER_CLIENT_SECRET ? "Loaded (hidden)" : "!!! NOT LOADED !!!");
      functions.logger.error("3. Axios Error Message:", error.message);
      if (error.response) {
        functions.logger.error("4. Naver API Response Status:", error.response.status);
        functions.logger.error("5. Naver API Response Data:", error.response.data);
      }
      response.status(500).send({error: "Authentication failed. Check server logs."});
    }
  },
);