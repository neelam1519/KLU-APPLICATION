import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:klu_flutter/provider.dart';
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
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaveDataProvider()),
      ],
      child: MyApp(),
    ),
  );
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

  @override
  Widget build(BuildContext context) {
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
            return Home(loggedUser: 'STUDENT');
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
        if (user.email != null && user.email!.endsWith("@klu.ac.in")) {
          final String email = googleSignInAccount.email ?? "";
          String? userId = user.uid;
          String? token = await user.getIdToken();

          Map<String,String> data={};
          String id=removeDomainFromEmail(email);
          String? lecturerorstudent=await LecturerORStudent(id);
          DocumentReference documentReference=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
          String? imageurl=user.photoURL;
          String branch='',year='',stream='',privilege='',name='',staffID='',section,faname,fastaffid,famailid,slot,mobilenumber;

          await getImageBytesFromUrl(imageurl);

          SharedPreferences sharedPreferences=SharedPreferences();
          FirebaseService firebaseService=FirebaseService();

          //lecturerorstudent='STAFF';

          if(lecturerorstudent=='STUDENT'){
            try {
              privilege = 'STUDENT';
              print('STUDENT LOGIN SUCCESSFUL');
              sharedPreferences.storeValueInSecurePrefs('PRIVILEGE', privilege);

              List<String> listOfBranches = ['ECE', 'CSE', 'MECHANICAL ENGINEERING', 'CIVIL ENGINEERING'];

              Map<String, String> details = {};
              year = getYearFromRegNo(id);
              branch = getBranchFromRegNo(id);
              String file = '$year $branch STUDENTS';
              String encodedYear = Uri.encodeComponent(year);
              String encodedFile = Uri.encodeComponent(file);
              Map<String, String> searchData = {};

              listOfBranches = await utils.moveStringToFirstPlace(listOfBranches, branch);

              for (String string in listOfBranches) {
                String encodedBranch = Uri.encodeComponent(string);
                String location = '$encodedYear%2F$encodedBranch%2F$encodedFile';
                print('Location: ${location.toString()}');
                searchData.addAll({'REG NO': id.trim()});
                details = await downloadedDetail(location, 'STUDENTS LIST', searchData);
                searchData.clear();
                if (details.isNotEmpty) {
                  branch = string;
                  break;
                }
              }

              print('STUDENT EXITED FOR LOOP');

              if (details.isEmpty) {
                utils.showToastMessage('STUDENT DETAILS NOT FOUND', context);
                print('DETAILS ARE EMPTY');
                FirebaseAuth.instance.signOut();
                GoogleSignIn().disconnect();
                EasyLoading.dismiss();
                return;
              }

              name = details['NAME']!;
              section = details['SECTION']!;
              print('student: $name  $section');

              searchData.addAll({'SECTION': section.trim(), 'YEAR': year.trim()});
              print('data: ${searchData.toString()}');
              details = await downloadedDetail('FA DETAILS', 'FACULTY ADVISORS', searchData);
              searchData.clear();

              if(details.isEmpty){
                utils.showToastMessage('FACULTY ADVISOR DETAILS NOT FOUND', context);
                print('DETAILS ARE EMPTY');
                FirebaseAuth.instance.signOut();
                GoogleSignIn().disconnect();
                EasyLoading.dismiss();
                return;
              }

              faname = details['NAME']!;
              famailid = details['MAIL ID']!;
              fastaffid = details['STAFF ID']!;
              String slot = details['SLOT']!;
              stream = details['STREAM']!;

              year=utils.romanToInteger(year).toString();
              slot=utils.romanToInteger(slot).toString();

              documentReference = FirebaseFirestore.instance.doc('KLU/STUDENT DETAILS/$year/$branch/$stream/$id');
              data.addAll({
                'UID': userId.trim(),
                'TOKEN': token ?? '',
                'BRANCH': branch.trim(),
                'STREAM': stream.trim(),
                'NAME': name.trim(),
                'REGISTRATION NUMBER': id,
                'YEAR': year.trim(),
                'SECTION': section.trim(),
                'MAIL ID': email,
                'FACULTY ADVISOR NAME': faname.trim(),
                'FACULTY ADVISOR MAIL ID': famailid.trim(),
                'FACULTY ADVISOR STAFF ID': fastaffid.trim(),
                'SLOT': slot.trim(),
                'HOSTEL NAME': 'BHARATHI MENS HOSTEL',
                'HOSTEL TYPE': 'NORMAL',
                'HOSTEL ROOM NUMBER': '215'
              });

            }catch(e){
              utils.showToastMessage('ERROR OCCURED CONTACT DEVELOPER', context);
              print('STUDENT: ${e.toString()}');
              utils.exceptions(e, 'STUDENT');
              GoogleSignIn().disconnect();
              FirebaseAuth.instance.signOut();
              EasyLoading.dismiss();
              return;
            }

          }else if(lecturerorstudent=='STAFF'){
            try {
              print('STAFF LOGGING IN');
              String name='', staffID='', branch='', mobileNumber='', yearCoordinatorStream='',
                  yearCoordinatorYear='', facultyAdvisorStream='',
                  facultyAdvisorSection='', facultyAdvisorYear='', slot='';

              Map<String, String> adminDetails = {};
              Map<String, String> faDetails = {};
              Map<String, String> hostelWardenDetails = {};

              Map<String, String> searchData = {};

              searchData.addAll({'MAIL ID': email.trim()});
              adminDetails =
              await downloadedDetail('ADMINS', 'ADMINS', searchData);

              faDetails = await downloadedDetail('FA DETAILS', 'FA DETAILS', searchData);
              searchData.clear();

              if (adminDetails.isNotEmpty && faDetails.isNotEmpty) {
                print('FACULTY ADVISOR AND YEAR COORDINATOR');
                privilege = 'FACULTY ADVISOR AND YEAR COORDINATOR';
                name = adminDetails['NAME'] ?? 'N/A';
                staffID = adminDetails['STAFF ID'] ?? 'N/A';
                branch = adminDetails['BRANCH'] ?? 'N/A';
                mobileNumber = faDetails['MOBILE NUMBER'] ?? 'N/A';
                yearCoordinatorStream = adminDetails['STREAM'] ?? 'N/A';
                yearCoordinatorYear = adminDetails['YEAR'] ?? 'N/A';
                facultyAdvisorStream = faDetails['STREAM'] ?? 'N/A';
                facultyAdvisorSection = faDetails['SECTION'] ?? 'N/A';
                facultyAdvisorYear = faDetails['YEAR'] ?? 'N/A';

                if (utils.isRomanNumeral(facultyAdvisorYear)) {
                  facultyAdvisorYear = utils.romanToInteger(facultyAdvisorYear).toString();
                }

                List<String> yearCoordinatorYearList = yearCoordinatorYear.split(',');
                List<String> updatedYearList = [];

                for (String year in yearCoordinatorYearList) {
                  if (utils.isRomanNumeral(year)) {
                    String str = utils.romanToInteger(year).toString();
                    updatedYearList.add(str);
                  } else {
                    updatedYearList.add(year);
                  }
                }

                yearCoordinatorYear = updatedYearList.join(',');
                print('yearCoordinatorYear: $yearCoordinatorYear');

                data.addAll({'UID': userId.trim(), 'TOKEN': token ?? '', 'PRIVILEGE': privilege, 'NAME': name, 'BRANCH': branch.trim(), 'MOBILE NUMBER': mobileNumber.trim(),
                  'STAFF ID': staffID.trim(), 'MAIL ID': email, 'YEAR COORDINATOR YEAR': yearCoordinatorYear.trim(), 'YEAR COORDINATOR STREAM': yearCoordinatorStream.trim(),
                  'FACULTY ADVISOR STREAM': facultyAdvisorStream.trim(), 'FACULTY ADVISOR YEAR': facultyAdvisorYear.trim(), 'FACULTY ADVISOR SECTION': facultyAdvisorSection.trim()});

              } else if (faDetails.isNotEmpty) {
                print('FACULTY ADVISOR');
                privilege = 'FACULTY ADVISOR';
                name = faDetails['NAME'] ?? 'N/A';
                staffID = faDetails['STAFF ID'] ?? 'N/A';
                branch = faDetails['BRANCH'] ?? 'N/A';
                mobileNumber = faDetails['MOBILE NUMBER'] ?? 'N/A';
                facultyAdvisorStream = faDetails['STREAM'] ?? 'N/A';
                facultyAdvisorSection = faDetails['SECTION'] ?? 'N/A';
                slot = faDetails['SLOT'] ?? 'N/A';
                facultyAdvisorYear = faDetails['YEAR'] ?? 'N/A';

                if (utils.isRomanNumeral(facultyAdvisorYear)) {
                  facultyAdvisorYear = utils.romanToInteger(facultyAdvisorYear).toString();
                }
                slot=utils.romanToInteger(slot).toString();

                data.addAll({'UID': userId.trim(), 'TOKEN': token ?? '', 'PRIVILEGE': privilege.trim(), 'NAME': name, 'BRANCH': branch.trim(), 'MOBILE NUMBER': mobileNumber,
                  'STAFF ID': staffID, 'MAIL ID': email.trim(), 'FACULTY ADVISOR STREAM': facultyAdvisorStream.trim(), 'FACULTY ADVISOR SECTION': facultyAdvisorSection.trim(),
                  'FACULTY ADVISOR YEAR': facultyAdvisorYear.trim(), 'SLOT': slot.trim()
                });
              } else if (adminDetails.isNotEmpty) {
                privilege = adminDetails['PRIVILEGE'] ?? 'N/A';
                print(privilege);
                name = adminDetails['NAME'] ?? 'N/A';
                staffID = adminDetails['STAFF ID'] ?? 'N/A';
                branch = adminDetails['BRANCH'] ?? 'N/A';
                stream = adminDetails['STREAM'] ?? 'N/A';
                year = adminDetails['YEAR'] ?? 'N/A';

                List<String> yearCoordinatorYearList = year.split(',');
                List<String> updatedYearList = [];

                for (String year in yearCoordinatorYearList) {
                  if (utils.isRomanNumeral(year)) {
                    String str = utils.romanToInteger(year).toString();
                    updatedYearList.add(str);
                  } else {
                    updatedYearList.add(year);
                  }
                }

                year = updatedYearList.join(',');
                print('year: $year');
                print('branch: $branch');

                if (privilege == 'YEAR COORDINATOR') {
                  data.addAll({
                    'UID': userId.trim(),
                    'TOKEN': token ?? '',
                    'PRIVILEGE': privilege.trim(),
                    'NAME': name.trim(),
                    'BRANCH': branch.trim(),
                    'STAFF ID': staffID.trim(),
                    'MAIL ID': email.trim(),
                    'YEAR COORDINATOR YEAR': year.trim(),
                    'YEAR COORDINATOR STREAM': stream.trim(),
                  });
                } else if (privilege == 'HOD') {
                  data.addAll({
                    'UID': userId,
                    'TOKEN': token ?? '',
                    'PRIVILEGE': privilege.trim(),
                    'NAME': name.trim(),
                    'BRANCH': branch.trim(),
                    'STAFF ID': staffID.trim(),
                    'MAIL ID': email.trim(),
                    'HOD YEAR': year.trim(),
                    'HOD STREAM': stream.trim(),
                  });
                }
              }

              if(adminDetails.isEmpty && faDetails.isEmpty){
                searchData.addAll({'MAIL ID': email});
                print('Email : $email');
                hostelWardenDetails = await downloadedDetail('HOSTEL WARDENS', 'HOSTEL WARDENS', searchData);
                searchData.clear();

                if(hostelWardenDetails.isNotEmpty){
                  print('HOSTEL WARDEN');
                  privilege='HOSTEL WARDEN';
                  String hostelName=hostelWardenDetails['HOSTEL NAME']!;
                  String hostelFloorNumber=hostelWardenDetails['FLOOR']!;
                  String wardenName=hostelWardenDetails['NAME']!;
                  String hostelType=hostelWardenDetails['TYPE']!;
                  data.addAll({'NAME':wardenName.trim(),'HOSTEL NAME':hostelName.trim(),'HOSTEL FLOOR':hostelFloorNumber.trim(),'PRIVILEGE':privilege,
                    'HOSTEL TYPE': hostelType,'MAIL ID': email});

                  documentReference=FirebaseFirestore.instance.doc('KLU/HOSTELS STAFF DETAILS/$hostelName/$hostelFloorNumber');
                  print('Hostel warden details: ${documentReference.path}');
                }else{
                  utils.showToastMessage('Your details not found contact ADMINISTRATOR', context);
                  GoogleSignIn().disconnect();
                  FirebaseAuth.instance.signOut();
                  EasyLoading.dismiss();
                  return;
                }
              }else if(adminDetails.isNotEmpty || faDetails.isNotEmpty){
                documentReference = FirebaseFirestore.instance.doc('KLU/STAFF DETAILS/$branch/$staffID');
              }
              
            }catch(e){
              utils.showToastMessage('ERROR OCCURED CONTACT DEVELOPER', context);
              utils.exceptions(e, 'STUDENT');
              GoogleSignIn().disconnect();
              FirebaseAuth.instance.signOut();
              EasyLoading.dismiss();
              return;
            }

          }else{
            utils.showToastMessage('Unknown Login', context);
            GoogleSignIn().disconnect();
            FirebaseAuth.instance.signOut();
            EasyLoading.dismiss();
            return;
          }
          if(user!=null) {
            print(data);

            await firebaseService.uploadMapDetailsToDoc(
                documentReference, data);
            await sharedPreferences.storeMapValuesInSecureStorage(data);
            await utils.clearTemporaryDirectory();

            EasyLoading.dismiss();
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => Home(loggedUser: privilege)));
          }else{
            utils.showToastMessage('DISCONNECTED', context);
          }

          print("Redirecting to home page");
        } else {
          GoogleSignIn().disconnect();
          FirebaseAuth.instance.signOut();
          EasyLoading.dismiss();
          utils.showToastMessage("Login with KLU mail only", context);
        }
      }
    } catch (error) {
      EasyLoading.dismiss();
      print("Error signing in with Google: $error");
      EasyLoading.dismiss();
      return;
    }
  }

  Future<Map<String, String>> downloadedDetail(String encodedPath, String filename, Map<String, String> data) async {
    Storage storage = Storage();
    Reader reader = Reader();
    String fileUrl = 'https://firebasestorage.googleapis.com/v0/b/klu_details/o/$encodedPath.xlsx?alt=media';
    print("downloadedDetail: ${fileUrl.toString()}");

    String filePath = await storage.downloadFileInCache(fileUrl, '$filename.xlsx');
    Map<String, String> details = await reader.readExcelFile(filePath, data);

    // Remove white spaces in map values and keys
    details = details.map((key, value) => MapEntry(key.trim(), value.trim()));

    print('downloadedDetail: ${details.toString()}');

    return details;
  }


  Future<String?> LecturerORStudent(String input) async {
    // Removes special characters
    String cleanedInput = input.replaceAll(RegExp(r'[^\w\s]'), '');

    RegExp digitRegex = RegExp(r'^[0-9]+$');
    RegExp letterRegex = RegExp(r'^[a-zA-Z]+$');

    bool containsNumbers = digitRegex.hasMatch(cleanedInput);
    bool containsLetters = letterRegex.hasMatch(cleanedInput);

    if (containsNumbers && !containsLetters) {
      // Only numbers
      return 'STUDENT';
    } else if (!containsNumbers && containsLetters) {
      // Only letters
      return 'STAFF';
    } else {
      // Both or neither
      return null;
    }
  }


  String getRegNo(String email) {
    // Split the email address using '@'
    List<String> parts = email.split('@');

    // Check if the email has the domain part
    if (parts.length == 2) {
      // Return the part before '@'
      return parts[0];
    } else {
      // Return the original email if it doesn't have the expected format
      return email;
    }
  }

  Future<void> getImageBytesFromUrl(String? imageUrl) async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences();

      if (imageUrl == null || imageUrl.isEmpty) {
        // Handle the case where the image URL is null or empty
        return null;
      }
      // Download the image using http
      http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Convert the response body to bytes
        Uint8List imageBytes = Uint8List.fromList(response.bodyBytes);

        // Encode the bytes to a base64 string and store in SharedPreferences
        sharedPreferences.storeValueInSecurePrefs('PROFILE IMAGE', base64.encode(imageBytes));

        print('Image bytes successfully fetched and stored in SharedPreferences.');
      } else {
        print('Failed to load image. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error loading image: $error');
      return null;
    }
  }

  String getYearFromRegNo(String regNo) {
    // Check if the registration number is not null and has a valid length
    if (regNo != null) {
      // Extract the character at the specified index
      String branchCode = regNo[3];
      print(branchCode);

      // Check the extracted character and return the corresponding branch
      switch (branchCode) {
        case '0':
          return 'IV';
        case '1':
          return 'III';
        case '2':
          return "II";
        case '3':
          return 'I';
        default:
          return 'Unknown Branch';
      }
    } else {
      // Return a default value for invalid registration numbers
      return 'Invalid Registration Number';
    }
  }

  String getBranchFromRegNo(String regNo) {
    // Check if the registration number is not null and has a valid length
    if (regNo != null) {
      // Extract the character at the specified index
      String branchCode = regNo[6];
      print(branchCode);

      // Check the extracted character and return the corresponding branch
      switch (branchCode) {
        case '4':
          return 'CSE';
        case '5':
          return 'ECE';
      // Add more cases for other branches if needed
        default:
          return 'Unknown Branch';
      }
    } else {
      // Return a default value for invalid registration numbers
      return 'Invalid Registration Number';
    }
  }
  String removeDomainFromEmail(String email) {
    // Find the position of the '@' symbol
    int atIndex = email.indexOf('@');

    // If '@' symbol is found, extract the username (part before '@')
    if (atIndex != -1) {
      String username = email.substring(0, atIndex);
      return username;
    } else {
      // If '@' symbol is not found, return the original email
      return email;
    }
  }
}
