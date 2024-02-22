import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/readers.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/storage.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/utils.dart';

class UpdateDetails extends StatefulWidget {
  @override
  _UpdateDetailsState createState() => _UpdateDetailsState();
}

class _UpdateDetailsState extends State<UpdateDetails> {
  List<String> yearList = [];
  String? branch = '',privilege='',staffID='';

  Utils utils=Utils();
  Storage storage = Storage();
  FirebaseService firebaseService=FirebaseService();
  SharedPreferences sharedPreferences=SharedPreferences();
  Reader reader= Reader();

  @override
  void initState() {
    // TODO: implement initState
    getData();

    super.initState();
  }

  Future<void> getData() async{
    print('getData started');
   String? year=await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
   branch= await sharedPreferences.getSecurePrefsValue('BRANCH');
   yearList=year!.split(',');
   privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
   staffID=await sharedPreferences.getSecurePrefsValue('STAFF ID');
   print('getData :${staffID}');
   setState(() {

   });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: yearList.length,
              itemBuilder: (context, index) {
                final year = yearList[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20), // Add spacing between sections
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$year $branch FA DETAILS', // Add Faculty Advisor Details section
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh), // Add the upload file icon
                            onPressed: () {
                              updateDetails('$year $branch');
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _pickFile('$year $branch FA DETAILS'); // Pass year and branch information to _pickFile
                        },
                        child: Text('Upload Files for Faculty Advisor'),
                      ),
                      SizedBox(height: 20), // Add spacing between sections
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20), // Add spacing between sections
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADMINS DETAILS', // Additional text widget
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10), // Add spacing between text and button
              ElevatedButton(
                onPressed: () {
                  _pickFile('Admins Details'); // Pass year and branch information to _pickFile
                },
                child: Text('Upload Files for Admins'),
              ),
              SizedBox(height: 20), // Add spacing between sections
            ],
          ),
        ],
      ),
    );
  }

  Future<void> updateDetails(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    print('tempDir path: ${tempDir.path}');

    String directoryPath = '${tempDir.path}/file_picker';
    await Directory(directoryPath).create(recursive: true);

    String studentFileName = '$fileName STUDENT DETAILS.xlsx';
    String faFileName = '$fileName FA DETAILS.xlsx';
    String adminsFileName = 'ADMINS.xlsx';

    String studentFilePath = '$directoryPath/$studentFileName';
    String faFilePath = '$directoryPath/$faFileName';
    String adminsFilePath = '$directoryPath/$adminsFileName';

    print('Student file path: $studentFilePath');
    print('FA file path: $faFilePath');
    print('Admins file path: $adminsFilePath');

    // Read files
    File studentFile = File(studentFilePath);
    File faFile = File(faFilePath);
    File adminsFile = File(adminsFilePath);

    try {
      // Check if files exist
      if (await studentFile.exists()) {
        // Process student file
        print('Student file exists.');
      } else {
        print('Student file does not exist.');
        return;
      }

      if (await faFile.exists()) {
        // Process FA file
        print('FA file exists.');
      } else {
        print('FA file does not exist.');
        return;
      }

      if (await adminsFile.exists()) {
        // Process admins file
        print('Admins file exists.');
      } else {
        print('Admins file does not exist.');
        return;
      }


      Map<String,Map<String, String>> faTotalDetails={};
      Map<String, String> faDetails = {};
      List<String> faStaffID = await reader.getColumnValues(faFilePath, 'STAFF ID');
      print('faStaffIdList: ${faStaffID.toString()}');

      for(String entry in faStaffID){

        faDetails = await reader.readExcelFile(faFilePath, {'STAFF ID': entry.trim()});
        //print('faStaffID: ${faDetails.toString()} ');
        if (faDetails.isEmpty) {
          print('No details found for staff with staffID: $entry');
          continue;
        }

        faTotalDetails.addAll({entry:faDetails});
      }

      Map<String,Map<String, String>> adminsTotalDetails={};
      Map<String, String> adminDetails = {};
      List<String> adminStaffID = await reader.getColumnValues(adminsFilePath, 'STAFF ID');

      for(String entry in adminStaffID){

        adminDetails = await reader.readExcelFile(adminsFilePath, {'STAFF ID': entry.trim()});
        //print('adminStaffID: ${adminDetails.toString()} ');

        adminsTotalDetails.addAll({entry:adminDetails});

        if (adminDetails.isEmpty) {
          print('No details found for staff with staffID: $entry');
          continue;
        }
      }

      Map<String, Map<String, String>> commonValues = {};

      faTotalDetails.forEach((key, value) {
        if (adminsTotalDetails.containsKey(key)) {
          // If the key exists in both faTotalDetails and adminsTotalDetails
          // Merge the values
          Map<String, String> mergedValues = {};
          mergedValues.addAll(value); // Add all values from faTotalDetails
          mergedValues.addAll(adminsTotalDetails[key]!); // Add all values from adminsTotalDetails

          // Add the merged values to commonValues
          commonValues[key] = mergedValues;
        }
      });

      commonValues.keys.forEach((key) {
        faTotalDetails.remove(key);
        adminsTotalDetails.remove(key);
      });


      for (MapEntry<String, Map<String, String>> entry in commonValues.entries) {
        String key = entry.key;
        Map<String, String> value = entry.value;

        value['PRIVILEGE'] = 'FACULTY ADVISOR AND YEAR COORDINATOR';
      }

      Map<String, Map<String, String>> combinedMap = {};

      combinedMap.addAll(commonValues);
      print('Common Values: ${commonValues.toString()}');
      combinedMap.addAll(faTotalDetails);
      combinedMap.addAll(adminsTotalDetails);

      for (String key in combinedMap.keys) {
        Map<String, String> value = combinedMap[key]!;
        Map<String, String> updatedValue = {};

        // Process the values in 'value' map
        for (String rkey in value.keys) {
          String rvalue = value[rkey]!;
          List<String> parts = rvalue.split(',');

          List<String> updatedParts = [];
          for (String part in parts) {
            if (utils.isRomanNumeral(part)) {
              updatedParts.add(utils.romanToInteger(part).toString());
            } else {
              updatedParts.add(part);
            }
          }
          if(value['YEAR COORDINATOR STREAM']=='ALL STREAMS'){
            updatedValue['YEAR COORDINATOR STREAM'] = 'AIML,CS,IOT,DS';
          }


          updatedValue[rkey] = updatedParts.join(',');
        }

        // Check if staffID and privilege are not null before adding them
        if (staffID != null && privilege != null) {
          updatedValue[privilege!] = staffID!;
        } else {
          // Handle the case if staffID or privilege is null
          print('Staff ID or Privilege is null');
        }

        print('key: $key  mapValues: ${updatedValue.toString()}');

        // Update the document in Firestore with the updatedValue
        DocumentReference staffDetailsRef = FirebaseFirestore.instance.doc('/KLU/STAFFDETAILS/LECTURERS/$key');
        print('LecturerDocumentReference: ${staffDetailsRef.path}');
        await firebaseService.uploadMapDetailsToDoc(staffDetailsRef, updatedValue,staffID!);
      }

    } catch (e) {
      utils.showToastMessage('Error Occured: ${e}', context);
      print('Error: $e');
    }
  }

  Future<void> _pickFile(String fileName) async {
    try {

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['xlsx']
      );

    } catch (e) {
      print('Failed to save file: $e');
    }
  }

}
