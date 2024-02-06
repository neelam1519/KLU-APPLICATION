import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Map<String, dynamic> userDetails = {};

  @override
  void initState() {
    super.initState();
    // Fetch user details when the widget is initialized
    fetchUserDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Account'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Details',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              // Loop through the map details and display each key-value pair
              for (var entry in userDetails.entries)
                Text(
                  '${entry.key}: ${entry.value ?? 'N/A'}',
                  style: TextStyle(fontSize: 16.0),
                ),
            ],
          ),
        ),
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
