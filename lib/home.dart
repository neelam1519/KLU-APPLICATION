import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:klu_flutter/account.dart';
import 'package:klu_flutter/leaveapply/lecturerleaveformsview.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/main.dart';
import 'package:klu_flutter/services/pushnotificationservice.dart';
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
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  String? fcmToken;

  String? fullname;
  String? email;
  Uint8List? imageBytes;
  Utils utils=Utils();

  @override
  void initState() {
    //utils.showToastMessage(widget.loggedUser, context);
    utils.showDefaultLoading();
    requestNotificationPermissions();
    loadProfileImageBytes().then((bytes) {
    storeFcmToken();
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
    fullname = await sharedPreferences.getSecurePrefsValue("NAME");
    email = await sharedPreferences.getSecurePrefsValue("MAIL ID");

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

  void requestNotificationPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permission granted: ${settings.authorizationStatus}');
    }
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

  Future<void> storeFcmToken() async {
    try {
      String? section, branch = '', year, stream, staffID, regNo;
      String? hostelName = '', hostelFloor = '';

      branch = await sharedPreferences.getSecurePrefsValue('BRANCH');
      hostelName = await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
      hostelFloor = await sharedPreferences.getSecurePrefsValue('HOSTEL FLOOR');
      staffID = await sharedPreferences.getSecurePrefsValue('STAFF ID');
      year = await sharedPreferences.getSecurePrefsValue("YEAR");
      regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
      stream = await sharedPreferences.getSecurePrefsValue("STREAM");

      String? privilege =
      await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
      DocumentReference documentReference =
      FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

      FirebaseMessaging.instance.onTokenRefresh.listen((String? newToken) async {
        print('FCM Token Refreshed: $newToken');
        // Update the token on your server or perform other necessary tasks

        if (privilege != null) {
          switch (privilege) {
            case 'HOD':
            case 'FACULTY ADVISOR':
            case 'YEAR COORDINATOR':
            case 'FACULTY ADVISOR AND YEAR COORDINATOR':
              documentReference =
                  FirebaseFirestore.instance.doc('KLU/STAFF DETAILS/$staffID');
              break;
            case 'STUDENT':
              documentReference = FirebaseFirestore.instance
                  .doc('KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo/');
              break;
            case 'HOSTEL WARDEN':
            // Handle HOSTEL WARDEN case
              break;
            default:
              utils.showToastMessage(
                  'UNABLE TO GET THE REFERENCE DETAILS', context);
          }

          Map<String, String> data = {'FCM TOKEN': newToken ?? ''};
          await firebaseService.uploadMapDetailsToDoc(documentReference, data);
          print('FCM TOKEN IS UPDATED SUCCESSFULLY');
        }
      });
    } catch (e) {
      // Handle any errors that occur during the execution
      print('Error in storeFcmToken: $e');
      // You may want to show a message or perform additional error handling here
    }
  }

}
