import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:klu_flutter/security/EncryptionService.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class FirebaseService {

  SharedPreferences sharedPreferences=SharedPreferences();
  EncryptionService encryptionService =EncryptionService();
  Utils utils=Utils();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Key key;


  Future<void> uploadMapDetailsToDoc(DocumentReference documentReference, Map<String, dynamic> data, String ID,String keySalt) async {
    try {
      Map<String, dynamic> encryptedData={};
      if(ID!='review') {
        Map<String, dynamic> encryptedData = await encryptionService
            .encryptData(keySalt, data);
        print('Uploading Data: ${encryptedData.toString()}');
      }else{
        encryptedData=data;
      }

      await documentReference.set({
        ...encryptedData, // Include the document data
        'verificationID': ID, // Additional metadata
      }, SetOptions(merge: true)); // Use merge option to merge with existing document

      print('Map values uploaded successfully!');
    } catch (error) {
      print('Error uploading map values: $error');
      // Handle the error as needed
    }
  }

  Future<void> setMapDetailsToDoc(DocumentReference documentReference, Map<String, dynamic> data, String ID,String keysalt) async {
    try {
      Map<String, dynamic> encryptedData = await encryptionService.encryptData(keysalt, data);
      DocumentSnapshot documentSnapshot = await documentReference.get();
      if (documentSnapshot.exists) {
        await deleteDocument(documentReference); // Await the deletion
      }
      print('Uploading Data: ${encryptedData.toString()}');
      await documentReference.set({
        ...encryptedData,
        'verificationID': ID
      }); // Use merge option to merge with existing document

      print('Map values uploaded successfully!');
    } catch (error) {
      print('Error uploading map values: $error');
      // Handle the error as needed
    }
  }

  Future<Map<String, dynamic>> getMapDetailsFromDoc(DocumentReference documentReference,String salt) async {
    try {
      // Get the document snapshot
      DocumentSnapshot snapshot = await documentReference.get();

      // Check if the document exists
      if (snapshot.exists) {
        // Access the data from the snapshot
        Map<String, dynamic>? mapData = snapshot.data() as Map<String, dynamic>?;

        if(mapData!.containsKey('verificationID')){
          mapData.remove('verificationID');
        }

        mapData=await encryptionService.decryptData(salt, mapData);
        print('Retrieved Decrypted Data: ${mapData.toString()}');

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

  Future<Map<String, dynamic>?> getValuesFromDocRef(DocumentReference documentReference, List<String> requiredFieldNames,String salt) async {
    try {
      // Get the document snapshot
      DocumentSnapshot snapshot = await documentReference.get();

      // Check if the document exists
      if (snapshot.exists) {
        // Cast snapshot.data() to Map<String, dynamic>
        Map<String, dynamic>? documentData = snapshot.data() as Map<String, dynamic>?;

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
        fieldValues=await encryptionService.decryptData(salt, fieldValues);
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

  Future<bool> isDocumentExists(CollectionReference collectionReference, String documentName) async {
    try {
      DocumentSnapshot documentSnapshot = await collectionReference.doc(documentName).get();
      return documentSnapshot.exists;
    } catch (e) {
      print("Error checking document existence: $e");
      return false;
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
}
