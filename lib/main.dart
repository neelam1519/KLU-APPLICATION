import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:klu_flutter/provider.dart';
import 'package:klu_flutter/services/pushnotificationservice.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/loadingdialog.dart';
import 'package:klu_flutter/utils/readers.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'home.dart';

void main() async {

  await _initializeFlutterFire();
  //FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaveDataProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _initializeFlutterFire() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  if (message.notification != null) {
    String title = message.notification!.title ?? 'Default Title';
    String body = message.notification!.body ?? 'Default Body';
    PushNotificationService().showLocalNotification(title, body);
    print("data $title  $body");
  }

  print("Handling a background message: ${message.messageId}");
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyAuthenticationCheck(),
      builder: EasyLoading.init(), // Use EasyLoading.init() directly here
    );
  }
}

class MyAuthenticationCheck extends StatelessWidget {
  final PushNotificationService _notificationService = PushNotificationService();

  @override
  Widget build(BuildContext context) {
    _notificationService.initialize();

    return FutureBuilder(
      // Check the authentication state
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error checking authentication state'),
            ),
          );
        } else {
          // If the user is already signed in, redirect to the Home page
          if (snapshot.data != null) {
            print('AUTHENTICATION USER IS NOT NULL  ${snapshot.data.toString()}');
            return Home();
          } else {
            print('AUTHENTICATION: USER IS NULL');
            // If the user is null, show the login page
            return MyHomePage(title: 'Flutter Demo Home Page');
          }
        }
      },
    );
  }

}

class MyHomePage extends StatelessWidget {

  final String title;
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          alignment: Alignment.topCenter, // Align the container to the top center
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/signinimage.png', // Replace 'your_image.png' with your actual image asset path
                width: 400, // Adjust width as needed
                height: 400, // Adjust height as needed
              ),
              SizedBox(height: 0), // Add spacing below the image
              Text(
                'myUniv', // Replace with your desired text
                style: TextStyle(
                  fontSize: 60.0, // Adjust font size as needed
                  fontWeight: FontWeight.bold, // Set font weight to bold
                  fontStyle: FontStyle.normal, // Set font style to italic
                ),
              ),
              SizedBox(height: 40.0), // Add spacing below the text
              Container(
                child: SignInButton(
                  Buttons.googleDark,
                  onPressed: () {
                    checkInternetAndSignIn(context);
                  },
                ),
              ),
              SizedBox(height: 30.0), // Add spacing below the image
              Center(
                child: Text(
                  'Stay connected with your \n university', // Replace with your desired text
                  textAlign: TextAlign.center, // Center align the text horizontally
                  style: TextStyle(
                    fontSize: 15.0, // Adjust font size as needed
                    fontWeight: FontWeight.normal, // Set font weight to normal
                    fontStyle: FontStyle.normal, // Set font style to normal
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> checkInternetAndSignIn(BuildContext context) async {
    Utils utils=Utils();
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      utils.showToastMessage("Connect to the Internet", context);
    } else {
      _signInWithGoogle(context);
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    Utils utils=Utils();
    LoadingDialog loadingDialog=LoadingDialog();
    loadingDialog.showDefaultLoading('Getting details please wait');
    try {
      final GoogleSignInAccount? googleSignInAccount = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      if (user != null) {
        if (user.email!.endsWith("@klu.ac.in")) {

          final String email = googleSignInAccount.email ?? "";
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          String userId = user.uid;
          String regNo=utils.removeDomainFromEmail(email);
          String year=utils.getYearFromRegNo(regNo);
          String branch=utils.getBranchFromRegNo(regNo);
          String? imageUrl=user.photoURL;
          String privilege='';

          Map<String,String> data={};

          FirebaseService firebaseService = FirebaseService();
          SharedPreferences sharedPreferences=SharedPreferences();
          Reader reader=Reader();

          await utils.getImageBytesFromUrl(imageUrl);

          String? lecturerOrStudent=await utils.lecturerORStudent(regNo);

          //lecturerOrStudent='STAFF';
          print('SIGNED IN AS: $lecturerOrStudent');

          if(lecturerOrStudent == 'STUDENT'){

            try {
              String studentPathFileName = Uri.encodeComponent('$year/$branch/$year $branch STUDENT DETAILS');
              Map<String, String> data = {'REGISTRATION NUMBER': regNo};

              Map<String, dynamic> studentFileDetails = await reader.downloadedDetail(studentPathFileName, '$year $branch STUDENT DETAILS', data);

              if (studentFileDetails.isEmpty) {
                utils.clearTemporaryDirectory();
                utils.showToastMessage('STUDENT DETAILS NOT FOUND', context);
                signOutUser();
              }

              String faPathFileName = Uri.encodeComponent('$year/$branch/$year $branch FA DETAILS');
              data.clear();
              data = {'SECTION': studentFileDetails['SECTION']};
              Map<String, dynamic> faDetails = await reader.downloadedDetail(faPathFileName, '$year $branch FA DETAILS', data);

              if (faDetails.isEmpty) {
                utils.clearTemporaryDirectory();
                utils.showToastMessage('FACULTY ADVISOR DETAILS NOT FOUND', context);
                signOutUser();
              }

              String adminPathFileName = Uri.encodeComponent('$year/$branch/$year $branch ADMINS DETAILS');
              data.clear();
              data = {
                'BRANCH': faDetails['BRANCH'],
                'YEAR COORDINATOR STREAM': faDetails['FACULTY ADVISOR STREAM'],
                'YEAR COORDINATOR YEAR': faDetails['FACULTY ADVISOR YEAR']
              };
              Map<String, dynamic> adminDetails = await reader.downloadedDetail(adminPathFileName, '$year $branch ADMIN DETAILS', data);

              if (adminDetails.isEmpty) {
                utils.clearTemporaryDirectory();
                utils.showToastMessage('YEAR COORDINATOR DETAILS NOT FOUND', context);
                signOutUser();
              }

              Map<String, dynamic> studentTotalDetails = {};

              DocumentReference documentReference = FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/$year/$regNo');
              print('Total Student Details: ${studentTotalDetails.toString()}');

              await sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', 'STUDENT');
              await sharedPreferences.storeValueInSecurePrefs('REGISTRATION NUMBER', regNo);


              studentTotalDetails.addAll({'PRIVILEGE':'STUDENT','UID':userId,'FCMTOKEN':fcmToken,'EMAIL ID':email,'STREAM':faDetails['FACULTY ADVISOR STREAM'],'BRANCH':faDetails['BRANCH'],
              'NAME':studentFileDetails['NAME'],'SECTION':studentFileDetails['SECTION'],'YEAR':year,'SLOT':faDetails['SLOT'],'REGISTRATION NUMBER':regNo,'FACULTY ADVISOR NAME':faDetails['NAME'],
              'FACULTY ADVISOR STAFF ID':faDetails['STAFF ID'],'FACULTY ADVISOR EMAIL ID':faDetails['EMAIL ID'],'YEAR COORDINATOR EMAIL ID':adminDetails['EMAIL ID'],
                'YEAR COORDINATOR NAME':adminDetails['NAME'],'YEAR COORDINATOR STAFF ID':adminDetails['STAFF ID'],'HOSTEL NAME':'BHARATHI MENS HOSTEL','HOSTEL ROOM NUMBER':'215',
                'HOSTEL WARDEN NAME':'SIVA SAI','HOSTEL WARDEN EMAIL ID':'9921004531@klu.ac.in','HOSTEL TYPE':'NORMAL','HOSTEL FLOOR NUMBER':'2','HOSTEL WARDEN STAFF ID':'klu456'});

              await firebaseService.setMapDetailsToDoc(documentReference, studentTotalDetails,userId,utils.getEmail());

              EasyLoading.dismiss();
              redirectToHome(context);

            }catch(e){
              signOutUser();
              utils.showToastMessage('YOUR DETAILS NOT FOUND', context);
            }

          }else if(lecturerOrStudent=='STAFF') {

            if(email=='9921004531@klu.ac.in'){
              Map<String,String> data={'NAME':'SIVA SAI','HOSTEL NAME':'BHARATHI MENS HOSTEL','HOSTEL ROOM NUMBER':'215','HOSTEL WARDEN NAME':'SIVA SAI',
                'HOSTEL TYPE':'NORMAL','HOSTEL FLOOR NUMBERcd ':'2','STAFF ID':'klu456','EMAIL ID':email};
              DocumentReference documentReference=FirebaseFirestore.instance.doc('/KLU/HOSTELWARDENDETAILS/BHARATHI MENS HOSTEL/klu456');
              sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', 'HOSTEL WARDEN');
              sharedPreferences.storeValueInSecurePrefs('STAFF ID', 'klu456');
              sharedPreferences.storeValueInSecurePrefs('HOSTEL NAME', 'BHARATHI MENS HOSTEL');

              await firebaseService.uploadMapDetailsToDoc(documentReference, data, 'klu456', utils.getEmail());
              redirectToHome(context);
              return;
            }

            List<String> yearsList=['1','2','3','4'];
            List<String> branchList=['CSE','ECE'];
            data.clear();

            Map<String,String> faDetails={};
            Map<String,String> adminDetails={};
            Map<String,String> wardenDetails={};

            try {
              for (String year in yearsList) {
                for (String branch in branchList) {
                  String faFilePath = Uri.encodeComponent('$year/$branch/$year $branch FA DETAILS');
                  data = {'EMAIL ID': email};
                  faDetails = await reader.downloadedDetail(
                      faFilePath, '$year $branch FA DETAILS', data);

                  if (faDetails.isNotEmpty) {
                    break;
                  }
                }
                if (faDetails.isNotEmpty) {
                  break;
                }
              }

              for (String year in yearsList) {
                for (String branch in branchList) {
                  String adminFilePath = Uri.encodeComponent('$year/$branch/$year $branch ADMINS DETAILS');
                  data = {'EMAIL ID': email};
                  adminDetails = await reader.downloadedDetail(
                      adminFilePath, '$year $branch ADMINS DETAILS', data);

                  if (adminDetails.isNotEmpty) {
                    break;
                  }
                }
                if (adminDetails.isNotEmpty) {
                  break;
                }
              }

              DocumentReference docRef = FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

              if (faDetails.isNotEmpty && adminDetails.isEmpty) {
                privilege = 'FACULTY ADVISOR';

                docRef = FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${faDetails['BRANCH']}/${faDetails['STAFF ID']}');
                faDetails.addAll({'UID': userId, 'FCMTOKEN': fcmToken!,'PRIVILEGE':privilege,'EMAIL ID':email});
                await firebaseService.setMapDetailsToDoc(docRef, faDetails,userId,utils.getEmail());

                sharedPreferences.storeValueInSecurePrefs('BRANCH', faDetails['BRANCH']);
                sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', privilege);
                sharedPreferences.storeValueInSecurePrefs('STAFF ID', faDetails['STAFF ID']);
                redirectToHome(context);
              } else if (faDetails.isEmpty && adminDetails.isNotEmpty) {
                if (email == 'hodcse@klu.ac.in') {
                  privilege = 'HOD';
                } else {
                  privilege = 'YEAR COORDINATOR';
                }

                docRef = FirebaseFirestore.instance.doc(
                    'KLU/STAFFDETAILS/${adminDetails['BRANCH']}/${adminDetails['STAFF ID']}');
                adminDetails.addAll({'UID': userId, 'FCMTOKEN': fcmToken!,'PRIVILEGE':privilege,'EMAIL ID':email});
                await firebaseService.setMapDetailsToDoc(docRef, adminDetails,userId,utils.getEmail());

                sharedPreferences.storeValueInSecurePrefs('BRANCH', adminDetails['BRANCH']);
                sharedPreferences.storeValueInSecurePrefs('STAFF ID', adminDetails['STAFF ID']);
                sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', privilege);
                redirectToHome(context);
              } else if (faDetails.isNotEmpty && adminDetails.isNotEmpty) {
                privilege = 'FACULTY ADVISOR AND YEAR COORDINATOR';

                Map<String, dynamic> totalDetails = {};
                totalDetails.addAll(faDetails);
                totalDetails.addAll(adminDetails);

                docRef = FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${adminDetails['BRANCH']}/${adminDetails['STAFF ID']}');
                totalDetails.addAll({'UID': userId, 'FCMTOKEN': fcmToken!,'PRIVILEGE':privilege,'EMAIL ID':email});
                await firebaseService.setMapDetailsToDoc(docRef, totalDetails,userId,utils.getEmail());

                sharedPreferences.storeValueInSecurePrefs('BRANCH', adminDetails['BRANCH']);
                sharedPreferences.storeValueInSecurePrefs('STAFF ID', adminDetails['STAFF ID']);
                sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', privilege);
                redirectToHome(context);
              } else {
                utils.showToastMessage('YOUR DETAILS NOT FOUND CONTACT ADMINISTRATOR', context);
                signOutUser();
              }
            }catch(e){
              print("Error: $e");
              utils.clearTemporaryDirectory();
              utils.showToastMessage('DETAILS NOT FOUND CONTACT ADMINISTRATOR', context);
              signOutUser();
            }

          }
        }else{
          utils.clearTemporaryDirectory();
          utils.showToastMessage('LOGIN WITH UNIVERSITY MAIL ID ONLY', context);
          signOutUser();
        }
      }
    } catch (error) {
      utils.clearTemporaryDirectory();
      utils.showToastMessage('Error occurred during login', context);
      signOutUser();
    }

    utils.clearTemporaryDirectory();
  }

  void signOutUser(){
    EasyLoading.dismiss();
    GoogleSignIn().disconnect();
    FirebaseAuth.instance.signOut();
    return;
  }

  void redirectToHome(BuildContext context){

    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));

  }

}
