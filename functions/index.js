const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnDocumentCreate = functions.firestore
    .document("KLU/STUDENT DETAILS/{year}/{branch}/{stream}/{regNo}/LEAVE FORMS/{leaveId}")
    .onCreate(async (snapshot, context) => {
      try {
        const data = snapshot.data(); // Access document data
        const regNo = data["REGISTRATION NUMBER"];

        const studentDetails = await admin.firestore().doc(`KLU/STUDENT DETAILS/${context.params.year}/${context.params.branch}/${context.params.stream}/${regNo}`).get();
        const staffID = studentDetails.data()["FACULTY ADVISOR STAFF ID"];
        const branch = studentDetails.data()["BRANCH"];

        console.log(`STUDENT REFERENCE: ${staffID}`);

        const faDetails = await admin.firestore().doc(`KLU/STAFF DETAILS/${branch}/${staffID}`).get();
        const token = faDetails.data()["FCM TOKEN"];

        console.log(`FA REFERENCE: ${token}`);

        const message = {
          notification: {
            title: "APPLIED FOR LEAVE",
            body: `${regNo}`,
          },
          data: {
            documentId: data["LEAVE ID"],
          },
        };

        const response = await admin.messaging().sendToDevice(token, message);
        console.log("Notification sent successfully:", response);
        return null;
      } catch (error) {
        console.error("Error in the Cloud Function:", error);
        return null;
      }
    });

exports.sendNotificationOnDataUpdate = functions.firestore
    .document("KLU/STUDENT DETAILS/{year}/{branch}/{stream}/{regNo}/LEAVE FORMS/{leaveId}")
    .onUpdate(async (change, context) => {
      const newData = change.after.data(); // New data after the update
      const oldData = change.before.data(); // Old data before the update

      // Check if different fields have changed
      const faApprovalChanged = newData && oldData && newData["FACULTY ADVISOR APPROVAL"] !== oldData["FACULTY ADVISOR APPROVAL"];
      const faDeclinedChanged = newData && oldData && newData["FACULTY ADVISOR DECLINED"] !== oldData["FACULTY ADVISOR DECLINED"];
      const yearApprovalChanged = newData && oldData && newData["YEAR COORDINATOR APPROVAL"] !== oldData["YEAR COORDINATOR APPROVAL"];
      const yearDeclineChanged = newData && oldData && newData["YEAR COORDINATOR DECLINED"] !== oldData["YEAR COORDINATOR DECLINED"];
      const hostelApprovalChanged = newData && oldData && newData["HOSTEL WARDEN APPROVAL"] !== oldData["HOSTEL WARDEN APPROVAL"];
      const hostelDeclineChanged = newData && oldData && newData["HOSTEL WARDEN DECLINED"] !== oldData["HOSTEL WARDEN DECLINED"];

      const regNo = newData["REGISTRATION NUMBER"];

      const studentRef = await admin.firestore().doc(`KLU/STUDENT DETAILS/${context.params.year}/${context.params.branch}/${context.params.stream}/${regNo}`).get();
      const studentDetails = studentRef.data();
      const studentToken = studentDetails["FCM TOKEN"];

      const branch = studentDetails["BRANCH"];
      const yearStaffID = studentDetails["YEAR COORDINATOR STAFF ID"];

      const yearStaffRef = await admin.firestore().doc(`KLU/STAFF DETAILS/${branch}/${yearStaffID}`).get();
      const yearStaffDetails = yearStaffRef.data();

      const yearCoordinatorToken = yearStaffDetails["FCM TOKEN"];

      // Send different notifications based on different conditions
      if (faApprovalChanged) {
        const message = {
          notification: {
            title: "FACULTY ADVISOR APPROVED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice([studentToken, yearCoordinatorToken], message);
      }

      if (faDeclinedChanged) {
        const message = {
          notification: {
            title: "FACULTY ADVISOR DECLINED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice(studentToken, message);
      }

      if (yearApprovalChanged) {
        const message = {
          notification: {
            title: "YEAR COORDINATOR APPROVED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice(studentToken, message);
      }

      if (yearDeclineChanged) {
        const message = {
          notification: {
            title: "YEAR COORDINATOR DECLINED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice(studentToken, message);
      }

      if (hostelApprovalChanged) {
        const message = {
          notification: {
            title: "HOSTEL WARDEN APPROVED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice(studentToken, message);
      }

      if (hostelDeclineChanged) {
        const message = {
          notification: {
            title: "HOSTEL WARDEN DECLINED",
            body: `${regNo}`,
          },
        };
        await admin.messaging().sendToDevice(studentToken, message);
      }

      return null;
    });
