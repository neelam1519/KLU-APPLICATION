import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:klu_flutter/accountdetails/personaldetails.dart';
import 'package:klu_flutter/accountdetails/updatedetails.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class UserAccount extends StatefulWidget {
  @override
  _UserAccountState createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  Utils utils = Utils();
  SharedPreferences sharedPreferences = SharedPreferences();
  FirebaseService firebaseService = FirebaseService();
  Uint8List? imageBytes;
  Map<String, dynamic> userDetails = {};
  bool showPersonalDetails = true;
  bool showAcademicDetails = true;
  bool showHostelDetails = true;
  bool showFacultyDetails = true;
  bool showUpgradeDetails = false;

  @override
  void initState() {
    super.initState();

    updateVisibility();
    loadProfileImageBytes().then((bytes) {
      setState(() {
        imageBytes = bytes;
      });
    });
    // Fetch user details when the widget is initialized
    fetchUserDetails();
  }
  Future<void> updateVisibility() async{
    String? privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    print('privilege $privilege');
    if(privilege =='HOD'){
      print('HOD LOGIN');
      setState(() {
        showUpgradeDetails = true;
      });
    }
  }

  Future<Uint8List?> loadProfileImageBytes() async {
    SharedPreferences secureStorage = await SharedPreferences();
    String? base64Image = await secureStorage.getSecurePrefsValue('PROFILE IMAGE');

    if (base64Image != null && base64Image.isNotEmpty) {
      return Uint8List.fromList(base64Decode(base64Image));
    }
    return null;
  }

  Future<void> fetchUserDetails() async {
    try {
      Map<String, dynamic> fetchedUserDetails = await getUserDetails();
      setState(() {
        userDetails = fetchedUserDetails;
      });
    } catch (e) {
      print("Error fetching user details: $e");
      // Handle the error accordingly
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Account'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display the image slightly above the app bar
          Container(
            margin: EdgeInsets.only(top: kToolbarHeight - 40),
            alignment: Alignment.center,
            child: imageBytes != null
                ? ClipOval(
              child: Container(
                width: 150, // Adjust width and height to set the size of the circular image
                height: 150,
                color: Colors.grey[200], // Placeholder color if imageBytes is null
                child: Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ) : Container(), // Or you can display a placeholder if imageBytes is null
          ),
          // Add other widgets below the image view as needed
          SizedBox(height: 20), // Add spacing between the image and text views
          Text(
            'First Name: John',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Last Name: Doe',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Email: john.doe@example.com',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20), // Add spacing between the text views and the line
          Divider(height: 1, color: Colors.black), // Add a line below the column
          SizedBox(height: 20), // Add spacing between the line and the buttons
          Column(
            children: [
              Visibility(
                visible: showAcademicDetails,
                  child: ListTile(
                    title: Text('Personal details'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PersonalDetails()),
                      );
                    },

                  )),
              Visibility(
                  visible: showFacultyDetails,
                  child: ListTile(
                    title: Text('Faculty details'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {},

                  )),
              Visibility(
                  visible: showPersonalDetails,
                  child: ListTile(
                    title: Text('Academic details'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {},

                  )),
              Visibility(
                  visible: showHostelDetails,
                  child: ListTile(
                    title: Text('Hostel details'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {},

                  )),
              Visibility(
                  visible: showUpgradeDetails,
                  child: ListTile(
                    title: Text('Update details'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UpdateDetails()),
                      );
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    String? branch, year, stream, staffID, regNo, privilege,hostelName,hostelType,hostelFloor;
    DocumentReference detailsRetrievingRef = FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

    year = await sharedPreferences.getSecurePrefsValue("YEAR");
    branch = await sharedPreferences.getSecurePrefsValue("BRANCH");
    regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
    staffID = await sharedPreferences.getSecurePrefsValue("STAFF ID");
    privilege = await sharedPreferences.getSecurePrefsValue("PRIVILEGE");
    stream = await sharedPreferences.getSecurePrefsValue("STREAM");
    hostelType = await sharedPreferences.getSecurePrefsValue("HOSTEL TYPE");
    hostelFloor = await sharedPreferences.getSecurePrefsValue("HOSTEL FLOOR");
    hostelName = await sharedPreferences.getSecurePrefsValue("HOSTEL NAME");

    if (privilege == 'STUDENT') {
      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo');

    } else if (privilege == 'FACULTY ADVISOR' ||
        privilege == 'YEAR COORDINATOR' ||
        privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR' ||
        privilege == 'HOD') {
      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/STAFF DETAILS/$branch/$staffID');
    } else if(privilege=='HOSTEL WARDEN'){
      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS STAFF DETAILS/$hostelName/$hostelFloor');
    }
    print('accountDocRef: ${detailsRetrievingRef.path}');

    Map<String, dynamic> userDetails = await firebaseService.getMapDetailsFromDoc(detailsRetrievingRef);
    userDetails.remove('FCM TOKEN');
    userDetails.remove('UID');

    return userDetails;
  }
}
