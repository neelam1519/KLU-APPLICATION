const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnDocumentCreate = functions.firestore
    .document("KLU/STUDENTDETAILS/{year}/{regNo}/LEAVEFORMS/{leaveId}")
    .onCreate(async (snapshot, context) => {
      try {
        const encryptedData = snapshot.data(); // Access document data
        const regNo = encryptedData["REGISTRATION NUMBER"];
        const year = context.params.year;

        const data = await decryptData(`${regNo}@klu.ac.in`, encryptedData);

        const studentDetails = await admin.firestore().doc(`KLU/STUDENTDETAILS/${year}/${regNo}`).get();
        if (!studentDetails.exists) {
          throw new Error(`Student details not found for year: ${year} and regNo: ${regNo}`);
        }
        const staffID = studentDetails.data()["FACULTY ADVISOR STAFF ID"];
        const branch = studentDetails.data()["BRANCH"];

        console.log(`STUDENT REFERENCE: ${staffID}`);

        const faDetails = await admin.firestore().doc(`KLU/STAFFDETAILS/${branch}/${staffID}`).get();
        if (!faDetails.exists) {
          throw new Error(`Faculty advisor details not found for branch: ${branch} and staffID: ${staffID}`);
        }
        const token = faDetails.data()["FCMTOKEN"];

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
    .document("KLU/STUDENTDETAILS/{year}/{regNo}/LEAVEFORMS/{leaveId}")
    .onUpdate(async (change, context) => {
      try {
        console.log("Function execution started");

        // Log context information
        console.log("Context params:", context.params);
        console.log("Event type:", context.eventType);
        console.log("Resource:", context.resource);

        const newData = change.after.data(); // New data after the update
        const oldData = change.before.data(); // Old data before the update

        // Log data before and after update
        console.log("Old data:", oldData);
        console.log("New data:", newData);

        // Check if different fields have changed
        const faApprovalChanged = newData && oldData && newData["FACULTY ADVISOR APPROVAL"] != oldData["FACULTY ADVISOR APPROVAL"];
        const yearApprovalChanged = newData && oldData && newData["YEAR COORDINATOR APPROVAL"] != oldData["YEAR COORDINATOR APPROVAL"];
        const hostelApprovalChanged = newData && oldData && newData["HOSTEL WARDEN APPROVAL"] != oldData["HOSTEL WARDEN APPROVAL"];

        // Log approval changes
        console.log("FA approval changed:", faApprovalChanged);
        console.log("Year approval changed:", yearApprovalChanged);
        console.log("Hostel approval changed:", hostelApprovalChanged);

        const regNo = newData["REGISTRATION NUMBER"];
        const year = context.params.year;
        console.log("regNo:", regNo);
        console.log("year:", year);

        const studentRef = await admin.firestore().doc(`KLU/STUDENTDETAILS/${year}/${regNo}`).get();
        const studentDetails = studentRef.data();
        if (!studentDetails || !studentDetails["FCMTOKEN"]) {
          console.error(`FCMTOKEN not found for year: ${year} and regNo: ${regNo}`);
          return null;
        }
        const studentToken = studentDetails["FCMTOKEN"];
        console.log("Student token:", studentToken);

        const yearStaffID = studentDetails["YEAR COORDINATOR STAFF ID"];
        console.log("Year coordinator staff ID:", yearStaffID);

        const yearStaffRef = await admin.firestore().doc(`KLU/STAFFDETAILS/LECTURERS/${yearStaffID}`).get();
        const yearStaffDetails = yearStaffRef.data();
        if (!yearStaffDetails || !yearStaffDetails["FCMTOKEN"]) {
          console.error(`FCMTOKEN not found for year coordinator with ID: ${yearStaffID}`);
          return null;
        }
        const yearCoordinatorToken = yearStaffDetails["FCMTOKEN"];
        console.log("Year coordinator token:", yearCoordinatorToken);

        // Send different notifications based on different conditions
        if (faApprovalChanged) {
          const message = {
            notification: {
              title: `FACULTY ADVISOR ${newData["FACULTY ADVISOR APPROVAL"]}`,
              body: `${regNo}`,
            },
          };
          console.log("Sending notification to student and year coordinator for FA approval change");
          await admin.messaging().sendToDevice([studentToken, yearCoordinatorToken], message);
          console.log("Notification sent successfully");
        }

        if (yearApprovalChanged) {
          const message = {
            notification: {
              title: `YEAR COORDINATOR ${newData["YEAR COORDINATOR APPROVAL"]}`,
              body: `${regNo}`,
            },
          };
          console.log("Sending notification to student for year coordinator approval change");
          await admin.messaging().sendToDevice(studentToken, message);
          console.log("Notification sent successfully");
        }

        if (hostelApprovalChanged) {
          const message = {
            notification: {
              title: `HOSTEL WARDEN ${newData["HOSTEL WARDEN APPROVAL"]}`,
              body: `${regNo}`,
            },
          };
          console.log("Sending notification to student for hostel warden approval change");
          await admin.messaging().sendToDevice(studentToken, message);
          console.log("Notification sent successfully");
        }

        console.log("Function execution completed successfully");
        return null;
      } catch (error) {
        console.error("Error in the Cloud Function:", error);
        return null;
      }
    });

// Import necessary libraries
const crypto = require("crypto");

// Function to decrypt data using AES encryption with CBC mode
function decryptData(keySalt, encryptedData) {
  // Generate key using keySalt
  const key = generateKey(keySalt);

  // Initialize decipher using AES encryption with CBC mode
  const decipher = crypto.createDecipheriv("aes-256-cbc", key, Buffer.alloc(16));

  // Decrypt each encrypted value in encryptedData
  const decryptedData = {};
  for (const key in encryptedData) {
    const encryptedValue = encryptedData[key];
    if (excludeKeys(key)) {
      const [ivBase64, encryptedValueBase64] = encryptedValue.split(":");
      const iv = Buffer.from(ivBase64, "base64");
      const encrypted = Buffer.from(encryptedValueBase64, "base64");
      const decryptedValue = decipher.update(encrypted, null, "utf8") + decipher.final("utf8");
      decryptedData[key] = decryptedValue;
    } else {
      decryptedData[key] = encryptedValue; // Keep value as it is without decryption
    }
  }
  return decryptedData;
}

// Function to check if key should be excluded from decryption
function excludeKeys(key) {
  const keysToExclude = ['FCMTOKEN', 'UID', 'REGISTRATION NUMBER']; // List of keys to exclude from encryption
  return !keysToExclude.includes(key);
}

// Function to generate a unique key for a user based on their email
function generateKey(email) {
  const salt = Buffer.from(email, "utf8"); // Convert email to bytes
  const hash = crypto.createHash("sha256").update(salt).digest();
  return hash.slice(0, 32); // Use first 32 bytes of hash as key
}


