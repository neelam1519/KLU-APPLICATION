const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnDocumentCreate = functions.firestore
    .document("KLU/STUDENT DETAILS/{year}/{branch}/{stream}/{regNo}/LEAVE FORMS/{leaveId}")
    .onCreate(async (snapshot, context) => {
      const data = snapshot.data(); // Access document data

      // Log that a new document has been added
      console.log("New document added:", data);

      const token = data.TOKEN;

      const message = {
        notification: {
          title: "New Document Added!",
          body: `A new document has been added to ${snapshot.ref.parent.path}`,
        },
        data: {
          documentId: "testing",

        },
      };

      return admin.messaging().sendToDevice(token, message)
          .then((response) => {
            console.log("Notification sent successfully:", response);
          })
          .catch((error) => {
            console.error("Error sending notification:", error);
          });
    });
