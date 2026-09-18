const { setGlobalOptions } = require("firebase-functions");
const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

// =====================================================
// SEND SCANLY NOTIFICATION TO ALL USERS
// =====================================================

exports.sendScanlyNotification = onDocumentCreated(
  "scanly_notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.log("No notification data found.");
      return;
    }

    const data = snapshot.data();

    const title = data.title || "Scanly";
    const body = data.body || "";

    const notificationId =
      event.params.notificationId;

    try {
      await admin.messaging().send({
        topic: "scanly_all",

        notification: {
          title: title,
          body: body,
        },

        data: {
          notificationId: notificationId,
          type: "scanly_broadcast",
        },

        android: {
          notification: {
            channelId: "scanly_notifications",
            sound: "default",
          },
        },
      });

      console.log(
        `Notification sent successfully: ${title}`,
      );
    } catch (error) {
      console.error(
        "Error sending Scanly notification:",
        error,
      );
    }
  },
);