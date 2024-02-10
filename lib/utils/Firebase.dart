import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:klu_flutter/model/model.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class FirebaseService {
  SharedPreferences sharedPreferences=SharedPreferences();
  Utils utils=Utils();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> uploadMapDetailsToDoc(DocumentReference documentReference, Map<String, String> data) async {
    try {
      // Use SetOptions to merge data if the document exists, create if it doesn't
      await documentReference.set(data, SetOptions(merge: true));

      print('Map values uploaded successfully!');
    } catch (error) {
      print('Error uploading map values: $error');
      // Handle the error as needed
    }
  }

  Future<Map<String, dynamic>> getMapDetailsFromDoc(DocumentReference documentReference) async {
    try {
      // Get the document snapshot
      DocumentSnapshot snapshot = await documentReference.get();

      // Check if the document exists
      if (snapshot.exists) {
        // Access the data from the snapshot
        Map<String, dynamic>? mapData = snapshot.data() as Map<String, dynamic>?;

        // Return the map details
        return mapData ?? {};
      } else {
        // Document does not exist
        print('Document does not exist getMapDetailsFromDoc');
        return {}; // Return an empty map or handle it accordingly
      }
    } catch (error) {
      print('Error getting map details: $error');
      // Handle the error as needed
      return {}; // Return an empty map or handle it accordingly
    }
  }



  Future<List<String>> getDocuments(CollectionReference collectionReference) async {
    try {
      final QuerySnapshot querySnapshot = await collectionReference.get();
      final List<String> documentIds = querySnapshot.docs.map((doc) => doc.id)
          .toList();
      return documentIds;
    } catch (error) {
      print('Error: $error');
      rethrow; // Rethrow the error to propagate it up the call stack
    }
  }

  Future<LeaveCardViewData?> getSpecificLeaveData(DocumentReference documentReference) async {
    print('getSpecificLeaveData: ${documentReference.toString()}');

    DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      print('Firebase getSpecificLeaveData: ${data.toString()}');

      String returnDate, startDate, id;
      bool facultyAdvisorApproval = false,
          yearCoordinatorApproval = false,
          hostelWardenApproval = false,
          facultyAdvisorDeclined = false,
          yearCoordinatorDeclined = false,
          hostelWardenDeclined = false;

      id = data['LEAVE ID'] ?? 'ID NOT ASSIGNED';
      returnDate = data['RETURN DATE'] ?? 'NOT FOUND';
      startDate = data['START DATE'] ?? 'NOT FOUND';
      facultyAdvisorApproval = data['FACULTY ADVISOR APPROVAL'] ?? false;
      yearCoordinatorApproval = data['YEAR COORDINATOR APPROVAL'] ?? false;
      hostelWardenApproval = data['HOSTEL WARDEN APPROVAL'] ?? false;
      facultyAdvisorDeclined = data['FACULTY ADVISOR DECLINED'] ?? false;
      yearCoordinatorDeclined = data['YEAR COORDINATOR DECLINED'] ?? false;
      hostelWardenDeclined = data['HOSTEL WARDEN DECLINED'] ?? false;

      bool verified = facultyAdvisorApproval && yearCoordinatorApproval && hostelWardenApproval;
      bool declined = facultyAdvisorDeclined || yearCoordinatorDeclined || hostelWardenDeclined;

      String verification;
      if (verified) {
        verification = "APPROVED";
      } else if (declined) {
        if (facultyAdvisorDeclined) {
          verification = 'FACULTY ADVISOR DECLINED';
        } else if (yearCoordinatorDeclined) {
          verification = 'YEAR COORDINATOR DECLINED';
        } else {
          verification = 'HOSTEL WARDEN DECLINED';
        }
      } else {
        verification = 'PENDING';
      }

      return LeaveCardViewData(id, startDate, returnDate, verification);
    } else {
      // Handle the case when the document doesn't exist
      print('Document does not exist getSpecificLeaveData');
      return null;
    }
  }

  Future<List<LeaveCardViewData>> getLeaveCardViewData(DocumentReference documentReference) async {
    try {
      List<LeaveCardViewData> leaveCardList = [];

        DocumentSnapshot documentSnapshot = await documentReference.get();

        if (documentSnapshot.exists) {
          Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

          for (MapEntry<String, dynamic> entry in data.entries) {
            String key = entry.key;
            dynamic leaveDetails = entry.value;
            print("getLeaveCardViewData leaveDetails: $leaveDetails");

            String returnDate = '',startDate = '';
            bool facultyAdvisorApproval = false, yearCoordinatorApproval = false, hostelWardenApproval = false, facultyAdvisorDeclined = false, yearCoordinatorDeclined = false, hostelWardenDeclined = false;

            if (leaveDetails is Map<String, dynamic>) {
              // If leaveDetails is a map, extract values
              returnDate = leaveDetails['RETURN DATE'] ?? 'NOT FOUND';
              startDate = leaveDetails['START DATE'] ?? 'NOT FOUND';
              facultyAdvisorApproval = leaveDetails['FACULTY ADVISOR APPROVAL'] ?? false;
              yearCoordinatorApproval = leaveDetails['YEAR COORDINATOR APPROVAL'] ?? false;
              hostelWardenApproval = leaveDetails['HOSTEL WARDEN APPROVAL'] ?? false;
              facultyAdvisorDeclined = leaveDetails['FACULTY ADVISOR DECLINED'] ?? false;
              yearCoordinatorDeclined = leaveDetails['YEAR COORDINATOR DECLINED'] ?? false;
              hostelWardenDeclined = leaveDetails['HOSTEL WARDEN DECLINED'] ?? false;
            } else if (leaveDetails is bool) {
              // Handle boolean values directly
              facultyAdvisorApproval = leaveDetails;
            }

            bool verified = facultyAdvisorApproval && yearCoordinatorApproval && hostelWardenApproval;
            bool declined = facultyAdvisorDeclined || yearCoordinatorDeclined || hostelWardenDeclined;

            String verification;
            if (verified) {
              verification = "APPROVED";
            } else if (declined) {
              if (facultyAdvisorDeclined) {
                verification = 'FACULTY ADVISOR DECLINED';
              } else if (yearCoordinatorDeclined) {
                verification = 'YEAR COORDINATOR DECLINED';
              } else {
                verification = 'HOSTEL WARDEN DECLINED';
              }
            } else {
              verification = 'PENDING';
            }

            LeaveCardViewData leaveCardData = LeaveCardViewData(key, startDate, returnDate, verification);leaveCardList.add(leaveCardData);

            print("getLeaveCardViewData PENDING Leave Request Key: $key");
          }
        } else {
          print("getLeaveCardViewData PENDING not found.");
        }
      print("LeaveCardViewData: ${documentReference.toString()}");

      return leaveCardList;
    } catch (error) {
      print('Error getting leave card data: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFieldValuesAsMap(DocumentReference documentReference, String field) async {
    try {
      DocumentSnapshot documentSnapshot = await documentReference.get();

      if (documentSnapshot.exists) {
        dynamic fieldValue = documentSnapshot.get(FieldPath([field]));

        if (fieldValue is Map<String, dynamic>) {
          print("getFieldValuesAsMap: $field");
          return fieldValue;
        }
      }
    } catch (e) {
      print("Error in getFieldValuesAsMap: $e");
    }

    return null; // Return null if the field is not found or an error occurs
  }

    Future<void> deleteField(DocumentReference documentReference, String field) async {

      try {
        // Get the document snapshot
        DocumentSnapshot documentSnapshot = await documentReference.get();

        if (documentSnapshot.exists) {
          // Check if the specified field is present in the document
          Map<String, dynamic> data = documentSnapshot.data() as Map<
              String,
              dynamic>;

          if (data.containsKey(field)) {
            // Delete the specified field
            await documentReference.update({
              field: FieldValue.delete(),
            });

            print('Field $field deleted successfully.');
          } else {
            print('Field $field not found in document.');
          }
        } else {
          print('Document does not exist at path ${documentReference.path}');
        }
      } catch (error) {
        print('Error deleting field $field: $error');
      }
    }

  Future<void> storeDocumentReference(DocumentReference documentReference, String field, DocumentReference value) async {
    try {
      // Check if the document exists
      DocumentSnapshot documentSnapshot = await documentReference.get();

      if (documentSnapshot.exists) {
        // Document exists, update the existing document
        await documentReference.update({
          field: value,
        });
      } else {
        // Document does not exist, create a new document
        await documentReference.set({
          field: value,
        });
      }

      print('Field updated/created successfully.');
    } catch (e) {
      print('Error updating/creating field: $e');
    }
  }


    Future<DocumentReference?> getDocumentReferenceFieldValue(DocumentReference documentReference, String field) async {
    try {
      //DocumentReference documentReference=FirebaseFirestore.instance.doc('KLU/ADMINS/3/CSE/YEAR COORDINATOR/CS/LEAVE FORMS/PENDING');
      DocumentSnapshot documentSnapshot = await documentReference.get();
      print('getDocumentReferenceFieldValue documentReference: ${documentReference.toString()}  field: $field');
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

        // Check if the field exists in the document
        if (data.containsKey(field)) {
          dynamic fieldValue = data[field];

          // Check if the field value is a DocumentReference
          if (fieldValue is DocumentReference) {
            return fieldValue;
          } else {
            print('Field $field does not contain a DocumentReference.');
            return null;
          }
        } else {
          print('Field $field not found in the document.');
          return null;
        }
      } else {
        print('Document does not exist getDocumentReferenceFieldValue.');
        return null;
      }
    } catch (e) {
      utils.exceptions(e, 'getDocumentReferenceFieldValue');
      return null;
    }
  }

  Future<void> deleteFieldInCollection(CollectionReference collectionReference, String field) async {
    try {
      // Get all documents in the collection
      QuerySnapshot querySnapshot = await collectionReference.get();

      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        // Delete the specified field in each document
        await documentSnapshot.reference.update({
          field: FieldValue.delete(),
        });

        print('Field $field deleted successfully in document ${documentSnapshot.id}');
      }

      print('Field $field deleted in all documents in the collection.');
    } catch (e) {
      print('Error deleting field: $e');
    }
  }

  Future<Map<String, dynamic>?> getValuesFromDocRef(DocumentReference documentReference, List<String> requiredFieldNames) async {
    try {
      // Get the document snapshot
      DocumentSnapshot snapshot = await documentReference.get();

      // Check if the document exists
      if (snapshot.exists) {
        // Cast snapshot.data() to Map<String, dynamic>
        Map<String, dynamic>? documentData =
        snapshot.data() as Map<String, dynamic>?;

        // Create a map to store field names and values
        Map<String, dynamic> fieldValues = {};

        // Check each required field
        for (String field in requiredFieldNames) {
          // Check if the field exists in the document data
          if (documentData != null && documentData.containsKey(field)) {
            // Retrieve the value of the specified field
            dynamic fieldValue = snapshot.get(FieldPath([field]));
            // Add the field name and value to the map
            fieldValues[field] = fieldValue;
          } else {
            // Field doesn't exist in the document
            fieldValues[field] = null;
          }
        }

        return fieldValues;
      } else {
        // Document doesn't exist
        return null;
      }
    } catch (e) {
      // Handle any errors that may occur during the process
      print("Error: $e");
      return null;
    }
  }


  Future<bool> isDocumentExists(CollectionReference collectionReference, String documentName) async {
    try {
      DocumentSnapshot documentSnapshot = await collectionReference.doc(documentName).get();
      return documentSnapshot.exists;
    } catch (e) {
      print("Error checking document existence: $e");
      return false;
    }
  }

  Future<void> storeKeyMapInDocument(DocumentReference documentReference, String key, Map<String,dynamic> value) async {
    try {
      // Use set with SetOptions(merge: true) to update or create fields
      await documentReference.set({key: value}, SetOptions(merge: true));

      print('Key-value pair stored successfully!');
    } catch (e) {
      print('Error storing key-value pair: $e');
      // Handle the error as needed
    }
  }

  Future<void> uploadDataToCollection(CollectionReference collectionReference, String documentName, Map<String, dynamic> data) async {
    try {
      // Reference to the specific document
      DocumentReference documentReference = collectionReference.doc(documentName);

      // Check if the document already exists
      bool documentExists = (await documentReference.get()).exists;

      if (documentExists) {
        // If the document exists, update it
        await documentReference.set(data, SetOptions(merge: true));
        print('Data updated successfully in ${collectionReference.path}/$documentName');
      } else {
        // If the document doesn't exist, create it
        await documentReference.set(data);
        print('Data uploaded successfully to ${collectionReference.path}/$documentName');
      }
    } catch (error) {
      print('Error uploading data: $error');
      // Handle the error as needed
    }
  }
  Future<void> deleteDocument(DocumentReference documentReference) async {
    try {
      // Delete the document
      await documentReference.delete();

      print('Document deleted successfully');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> updateBooleanField(DocumentReference documentReference, String fieldName, bool value) async {
    try {
      await documentReference.update({
        fieldName: value,
      });
      print('Document field updated successfully.');
    } catch (error) {
      print('Error updating document field: $error');
      // Handle the error as needed
    }
  }

  Future<dynamic> getSpecificFieldValue(DocumentReference documentReference, String field) async {
    try {
      // Get the document snapshot
      DocumentSnapshot snapshot = await documentReference.get();

      // Check if the document exists
      if (snapshot.exists) {
        // Replace "your_field" with the actual field name
        dynamic fieldValue = snapshot.get(field);

        // Return the field value
        return fieldValue;
      } else {
        print("Document does not exist");
        return null; // or throw an exception, depending on your use case
      }
    } catch (e) {
      print("Error getting document: $e");
      return null; // or throw an exception, depending on your use case
    }
  }


}
