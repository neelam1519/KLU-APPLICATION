import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:klu_flutter/accountdetails/academicdetails.dart';
import 'package:klu_flutter/accountdetails/facultydetails.dart';
import 'package:klu_flutter/accountdetails/hosteldetails.dart';
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
  String? name, regNo, email, privilege;
  Map<String, dynamic> userDetails = {};

  bool showPersonalDetails = true;
  bool showAcademicDetails = true;
  bool showHostelDetails = false;
  bool showFacultyDetails = false;
  bool showUpgradeDetails = false;

  @override
  void initState() {
    super.initState();

    updateVisibility();
    loadProfileImageBytes().then((bytes) {
      setState(() {
        getUserDetails();
        imageBytes = bytes;
      });
    });
  }

  Future<void> updateVisibility() async {
    String? privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    print('privilege $privilege');
    if (privilege == 'HOD') {
      print('HOD LOGIN');
      setState(() {
        showUpgradeDetails = true;
      });
    }

    if (privilege == 'STUDENT') {
      print('STUDENT LOGIN');
      setState(() {
        showHostelDetails = true;
        showFacultyDetails = true;
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Account'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: EdgeInsets.only(top: kToolbarHeight - 40),
            alignment: Alignment.center,
            child: ClipOval(
              child: Container(
                width: 150,
                height: 150,
                color: Colors.grey[200],
                child: imageBytes != null
                    ? Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  'assets/images/profile_placeholder.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          FutureBuilder<void>(
            future: getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Column(
                  children: [
                    Text(
                      '$name',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$regNo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 20),
          Divider(height: 1, color: Colors.black),
          SizedBox(height: 20),
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
                ),
              ),
              Visibility(
                visible: showFacultyDetails,
                child: ListTile(
                  title: Text('Faculty details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FacultyDetails()),
                    );
                  },
                ),
              ),
              Visibility(
                visible: showPersonalDetails,
                child: ListTile(
                  title: Text('Academic details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AcademicDetails()),
                    );
                  },
                ),
              ),
              Visibility(
                visible: showHostelDetails,
                child: ListTile(
                  title: Text('Hostel details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HostelDetails()),
                    );
                  },
                ),
              ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> getUserDetails() async {
    name = await sharedPreferences.getSecurePrefsValue('NAME');
    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');

    if (privilege == 'STUDENT') {
      regNo = await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');
    } else if (privilege == 'FACULTY ADVISOR' || privilege == 'HOD' || privilege == 'YEAR COORDINATOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      regNo = await sharedPreferences.getSecurePrefsValue('STAFF ID');
    }
  }
}
