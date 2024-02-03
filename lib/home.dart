import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:klu_flutter/account.dart';
import 'package:klu_flutter/leaveapply/lecturerleaveformsview.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/main.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  final String loggedUser;

  Home({required this.loggedUser});

  @override
  _HomeState createState() => _HomeState();
}


class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseService firebaseService = FirebaseService();
  SharedPreferences sharedPreferences = SharedPreferences();
  String? fullname;
  String? email;
  Uint8List? imageBytes;
  Utils utils=Utils();

  @override
  void initState() {
    //utils.showToastMessage(widget.loggedUser, context);
    utils.showDefaultLoading();
    requestPermissions();
    loadProfileImageBytes().then((bytes) {
      setState(() {
        imageBytes = bytes;
      });
    });
    getDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return true;
        },
    child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home Page'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          Utils utils=Utils();
                          final connectivityResult = await Connectivity().checkConnectivity();

                          if (connectivityResult == ConnectivityResult.none) {
                            utils.showToastMessage("Connect to the Internet", context);
                          } else {
                            String? privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');

                            if(privilege=='FACULTY ADVISOR' || privilege=='HOD' || privilege=='YEAR COORDINATOR' || privilege=='FACULTY ADVISOR AND YEAR COORDINATOR' || privilege=='HOSTEL WARDEN'){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerLeaveFormsView(privilege: privilege,)));

                            }else if(privilege=='STUDENT'){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsLeaveFormsView()));

                            }else{
                              utils.showToastMessage('unable to say your position', context);
                            }
                          }
                        },
                        child: Image.asset('assets/images/leaveicon.png', width: 130, height: 120, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 8),
                      Text('Apply Leave'),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          Utils utils=Utils();
                          final connectivityResult = await Connectivity().checkConnectivity();

                          if (connectivityResult == ConnectivityResult.none) {
                            utils.showToastMessage("Connect to the Internet", context);
                          } else {
                            utils.showToastMessage('UNDER DEVELOPMENT', context);
                            print('SOC tapped!');
                          }
                          // Handle the onPressed action for the second image
                        },
                        child: Image.asset('assets/images/KLU_LOGO.png', width: 130, height: 120, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 8),
                      Text('SOC'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Builder(
          builder: (context) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(fullname ?? 'Name not found'),
                  accountEmail: Text(email ?? 'Email not found'),
                  currentAccountPicture: Image.memory(
                    imageBytes ?? Uint8List(0),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Account'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserAccount()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                  onTap: () {
                    utils.showDefaultLoading();
                    signOut(context); // Implement this method to sign out
                  },
                ),
              ],
            );
          },
        ),
      ),
    )
    );
  }

  Future<void> getDetails() async {
    print("getDetails");

    String? year = await sharedPreferences.getSecurePrefsValue("YEAR");
    String? branch = await sharedPreferences.getSecurePrefsValue("BRANCH");
    String? regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
    String? staffId = await sharedPreferences.getSecurePrefsValue("STAFF ID");
    String? privilege = await sharedPreferences.getSecurePrefsValue("PRIVILEGE");
    fullname = await sharedPreferences.getSecurePrefsValue("NAME");
    email = await sharedPreferences.getSecurePrefsValue("MAIL ID");
    String? stream=await sharedPreferences.getSecurePrefsValue('STREAM');
    DocumentReference documentReference;

    print('User details retrieved and stored successfully!');
    EasyLoading.dismiss();
  }

  Future<Uint8List?> loadProfileImageBytes() async {
     SharedPreferences secureStorage = await SharedPreferences();
    String? base64Image = await secureStorage.getSecurePrefsValue('PROFILE IMAGE');

    if (base64Image != null && base64Image.isNotEmpty) {
      return Uint8List.fromList(base64Decode(base64Image));
    }
    return null;
  }

  Future<void> requestPermissions() async {
    // Check if camera permission is already granted
    var notificationStatus = await Permission.storage.status;

    if (notificationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    } else if (notificationStatus.isGranted) {
      // Camera permission is already granted
    }

    // Check if location permission is already granted
    var locationStatus = await Permission.locationWhenInUse.status;

    if (locationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    } else if (locationStatus.isGranted) {
      // Location permission is already granted
    }

    // Check if contacts permission is already granted
    var contactsStatus = await Permission.contacts.status;

    if (contactsStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    } else if (contactsStatus.isGranted) {
      // Contacts permission is already granted
    }
    print('Permisstions: ${notificationStatus}');
     utils.showToastMessage('Permission: ${notificationStatus}', context);
  }

  Future<void> signOut(BuildContext context) async {
    try {
      utils.clearSecureStorage();
      utils.clearTemporaryDirectory();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect(); // Disconnect Google Sign-In

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()),);
      EasyLoading.dismiss();
    } catch (error) {
      print("Error signing out: $error");
      EasyLoading.dismiss();
    }
  }
}
