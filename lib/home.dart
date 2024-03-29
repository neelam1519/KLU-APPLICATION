import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:klu_flutter/account.dart';
import 'package:klu_flutter/leaveapply/lecturerleaveformsview.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/main.dart';
import 'package:klu_flutter/review.dart';
import 'package:klu_flutter/security/EncryptionService.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseService firebaseService = FirebaseService();
  SharedPreferences sharedPreferences = SharedPreferences();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FirebaseFirestore firebaseFirestore=FirebaseFirestore.instance;
  EncryptionService encryptionService=EncryptionService();
  Utils utils=Utils();

  String? name,email,privilege,fcmToken,year,regNo,staffID,branch;
  Uint8List? imageBytes;
  late encrypt.Key key;
  late String userKey;

  @override
  void initState() {
    super.initState();
    utils.showDefaultLoading();

    initializeData();
    loadProfileImageBytes().then((bytes) {
      imageBytes = bytes;
    });
  }

  Future<void> initializeData()async{

    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE') ?? '';

    if(await utils.checkInternetConnectivity()){
      requestNotificationPermissions();
      getDetails().then((value) => storeFcmToken());

    }else{
      utils.showToastMessage('Check your internet connection', context);
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    String leaveForm='';

    if(privilege=='STUDENT'){
      leaveForm='Apply Leave';
    }else{
      leaveForm='Leave Forms';
    }

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
            child: Row(
              children: [
                SizedBox(width: 30),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          leaveFormClicked();
                        },
                        child: Image.asset('assets/images/leaveicon.png', width: 130, height: 120, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 8),
                      Text(leaveForm),
                    ],
                  ),
                ),
                SizedBox(width: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        // Handle onTap for the additional image

                      },
                      child: Column(
                        children: [
                          Image.asset('assets/images/materials.png', width: 130, height: 120, fit: BoxFit.cover),
                          SizedBox(height: 8),
                          Text('Materials'), // Text below the image
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
                  accountName: Text(name ?? 'Name not found'),
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
                  leading: Icon(Icons.rate_review),
                  title: Text('Review'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Review()),
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

  Future<void> leaveFormClicked() async{
    if(await utils.checkInternetConnectivity()){

      if(privilege=='FACULTY ADVISOR' || privilege=='HOD' || privilege=='YEAR COORDINATOR' || privilege=='FACULTY ADVISOR AND YEAR COORDINATOR' || privilege=='HOSTEL WARDEN'){
        Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerLeaveFormsView(privilege: privilege,)));

      }else if(privilege=='STUDENT'){
        Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsLeaveFormsView()));

      }else{
        //utils.showToastMessage('unable to say your position', context);
      }
    }else{
      utils.showToastMessage('Check your internet connection', context);
    }
  }

  Future<void> getDetails() async {
    utils.showDefaultLoading();
    try {
      DocumentReference detailsRef = FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
      if (privilege == 'STUDENT') {
        regNo = await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');
        year = await utils.getYearFromRegNo(regNo!);
        print('REGISTRATION NUMBER: $regNo');
        detailsRef = FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/$year/$regNo');
      } else if(privilege == 'YEAR COORDINATOR' || privilege=='HOD' || privilege=='FACULTY ADVISOR' || privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
        staffID = await sharedPreferences.getSecurePrefsValue('STAFF ID');
        branch = await sharedPreferences.getSecurePrefsValue('BRANCH');

        detailsRef = FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/$branch/$staffID');
      }else if(privilege=='WARDENS' || privilege =='HOSTEL WARDEN'){
        String? staffID=await sharedPreferences.getSecurePrefsValue('STAFF ID');
        String? hostelName=await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
        detailsRef=FirebaseFirestore.instance.doc('KLU/HOSTELWARDENDETAILS/$hostelName/$staffID');

      }else{
        utils.showToastMessage('NO DATA FOUND', context);
        EasyLoading.dismiss();
        return;
      }

      print('detailsRef: ${detailsRef.path}');

      Map<String, dynamic> details = await firebaseService.getMapDetailsFromDoc(detailsRef,utils.getEmail());
      details.remove('verificationID');

      for (MapEntry<String, dynamic> data in details.entries) {
        String key = data.key;
        String value = data.value;

        await sharedPreferences.storeValueInSecurePrefs(key, value);
      }

      privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE') ?? '';
      name = await sharedPreferences.getSecurePrefsValue('NAME');
      email = await sharedPreferences.getSecurePrefsValue('EMAIL ID');

      EasyLoading.dismiss();
    }catch(e){
      utils.exceptions(e, 'getDetails');
      utils.showToastMessage('Error occured while getting the data', context);
      EasyLoading.dismiss();
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
      String? branch, year, stream, staffID, regNo;
      String? hostelName, wardenID;

      // Retrieve user information from shared preferences
      branch = await sharedPreferences.getSecurePrefsValue('BRANCH');
      hostelName = await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
      staffID = await sharedPreferences.getSecurePrefsValue('STAFF ID');
      year = await sharedPreferences.getSecurePrefsValue("YEAR");
      regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
      stream = await sharedPreferences.getSecurePrefsValue("STREAM");
      wardenID = await sharedPreferences.getSecurePrefsValue('HOSTEL WARDEN ID');
      String? uid=await sharedPreferences.getSecurePrefsValue('UID');

      // Get the FCMtoken
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Failed to get fcmToken.');
        return;
      }
      // Determine the document reference based on user privilege
      DocumentReference documentReference;
      switch (privilege) {
        case 'HOD':
        case 'FACULTY ADVISOR':
        case 'YEAR COORDINATOR':
        case 'FACULTY ADVISOR AND YEAR COORDINATOR':
        documentReference = FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/$branch/$staffID');
          break;
        case 'STUDENT':
          documentReference = firebaseFirestore.doc('KLU/STUDENTDETAILS/$year/$regNo/');
          break;
        case 'HOSTEL WARDEN':
          documentReference = firebaseFirestore.doc('KLU/HOSTELS/$hostelName/$wardenID');
          break;
        default:
          print('Unknown privilege: $privilege');
          EasyLoading.dismiss();
          return;
      }

      print('fcmTokenRef: ${documentReference.toString()}');

      print('user UID: $uid');

      Map<String,String> data={'FCMTOKEN':token};
      await firebaseService.uploadMapDetailsToDoc(documentReference, data, uid!,utils.getEmail());
      print('FCMTOKEN is updated successfully.');
    } catch (e) {
      print('Error in storeFcmToken: $e');
      // Handle any errors that occur during the execution
    }
  }
}
