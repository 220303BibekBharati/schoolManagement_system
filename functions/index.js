const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Admin SDK once per function instance
admin.initializeApp();

// Triggered whenever admin creates a document in `notification_requests`
exports.sendNotificationOnRequest = functions.firestore
  .document("notification_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = data.title || "Notification";
    const body = data.body || "";
    const target = data.target || "all"; // 'all' | 'teachers' | 'students'

    const messages = [];

    const base = {
      notification: {
        title,
        body,
      },
      android: {
        notification: {
          channelId: "high_importance_channel",
          sound: "ring_notification", // custom sound name (Android)
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "ring_notification.caf", // custom sound name (iOS)
          },
        },
      },
    };

    if (target === "teachers" || target === "all") {
      messages.push({
        ...base,
        topic: "teachers",
      });
    }

    if (target === "students" || target === "all") {
      messages.push({
        ...base,
        topic: "students",
      });
    }

    if (!messages.length) return null;

    try {
      await Promise.all(messages.map((m) => admin.messaging().send(m)));
      console.log("Notifications sent for request", context.params.requestId);
    } catch (err) {
      console.error("Error sending notifications", err);
    }

    return null;
  });
