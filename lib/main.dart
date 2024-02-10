import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:klu_flutter/utils/readers.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/storage.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'home.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaveDataProvider()),
      ],
      child: MyApp(),
    ),
  );
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
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60.0,
              width: 250.0,
              child: SignInButton(
                Buttons.google,
                onPressed: () {
                  checkInternetAndSignIn(context);
                },
              ),
            ),
          ],
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
    utils.showDefaultLoading();
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
          String? imageUrl=user.photoURL;

          Map<String,String> data={};

          FirebaseService firebaseService = FirebaseService();
          SharedPreferences sharedPreferences=SharedPreferences();

          await utils.getImageBytesFromUrl(imageUrl);


          String? lecturerOrStudent=await utils.lecturerORStudent(regNo);

          //lecturerOrStudent=='STAFF';

          if(lecturerOrStudent =='STUDENT'){
            DocumentReference studentRef=FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/$year/$regNo');

            studentRef.get().then((DocumentSnapshot snapshot) async {
              if (snapshot.exists) {
                print('Document exists!');

                data.addAll({'UID': userId, 'FCMTOKEN': fcmToken!});
                await firebaseService.uploadMapDetailsToDoc(studentRef, data);

                sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', 'STUDENT');
                sharedPreferences.storeValueInSecurePrefs('REGISTRATION NUMBER', regNo);
                sharedPreferences.storeValueInSecurePrefs('EMAIL ID', email);

                print('Data: ${data.toString()}');

                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => Home()),);

                utils.showToastMessage('SUCCESSFULLY LOGGED IN $regNo', context);
                // Do something if the document exists
              } else {
                utils.showToastMessage('$regNo DETAILS NOT FOUND CONTACT FACULTY ADVISOR', context);
                print('Document does not exist.');
                EasyLoading.dismiss();
                GoogleSignIn().disconnect();
                FirebaseAuth.instance.signOut();
                return;
                // Do something if the document does not exist
              }
            }).catchError((error) {
              utils.showToastMessage('ERROR WHILE CHECKING THE $regNo DETAILS TRY AFTER SOME TIME', context);
              print('Error checking document existence: $error');
              EasyLoading.dismiss();
              GoogleSignIn().disconnect();
              FirebaseAuth.instance.signOut();
              return;
              // Handle any errors that occur while checking document existence
            });

          }else if(lecturerOrStudent=='STAFF'){

          }


        }else{
          EasyLoading.dismiss();
          GoogleSignIn().disconnect();
          FirebaseAuth.instance.signOut();
          utils.showToastMessage('LOGIN WITH UNIVERSITY MAIL ID ONLY', context);
          return;
        }
      }
    } catch (error) {
      EasyLoading.dismiss();
      utils.showToastMessage('Unknown Error Occured during login', context);
      print("Error signing in with Google: $error");
      EasyLoading.dismiss();
      return;
    }
  }

}
