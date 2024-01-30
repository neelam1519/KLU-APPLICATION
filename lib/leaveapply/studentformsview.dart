import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:klu_flutter/leaveapply/leaveform.dart';
import 'package:klu_flutter/model/model.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

import 'leavedetailsview.dart';

class StudentsLeaveFormsView extends StatefulWidget {
  @override
  _StudentsLeaveFormsViewState createState() => _StudentsLeaveFormsViewState();
}

class _StudentsLeaveFormsViewState extends State<StudentsLeaveFormsView> {
  SharedPreferences sharedPreferences=SharedPreferences();
  Utils utils = Utils();
  late DocumentReference studentLeaveFormRef;
  late CollectionReference studentLeaveRef=FirebaseFirestore.instance.collection('KLU');

  @override
  void initState() {
    super.initState();
    utils.showDefaultLoading();
    fetchLeaveCardData();
  }

  Future<void> fetchLeaveCardData() async {
    try {
      String? year = await sharedPreferences.getSecurePrefsValue("YEAR");
      String? branch = await sharedPreferences.getSecurePrefsValue("BRANCH");
      String? regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
      String? stream = await sharedPreferences.getSecurePrefsValue("STREAM");

      studentLeaveRef = FirebaseFirestore.instance.collection('/KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo/LEAVE FORMS/');

      setState(() {

        EasyLoading.dismiss();
      });
    } catch (error) {
      setState(() {
        EasyLoading.dismiss();
      });
      print("Error fetching data: $error");
      // Handle error gracefully
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Data'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentLeaveRef.snapshots(), // Listen to changes in the collection
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Loading indicator while data is being fetched
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Leave Data Available'));
          } else {
            List<DocumentSnapshot> data = snapshot.data!.docs;

            return Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final cardData = data[index].data() as Map<String, dynamic>;
                  // Assuming your document data is a Map<String, dynamic>
                  print('StreamBuilder: ${cardData.toString()}');
                  return Card(
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Start: ${cardData['START DATE']}'),
                              Text(" TO "),
                              Text('Return: ${cardData['RETURN DATE']}'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ID: ${cardData['LEAVE ID']}'),
                              Text('Status: ${cardData['STUDENT MOBILE NUMBER']}'),
                            ],
                          ),
                        ],
                      ),
                      onTap: () async {
                        final connectivityResult = await Connectivity().checkConnectivity();
                        if (connectivityResult == ConnectivityResult.none) {
                          utils.showToastMessage("Connect to Internet", context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveDetailsView(
                                leaveid: cardData['LEAVE ID'],
                                leaveformtype: '',
                                lecturerRef: studentLeaveRef.doc(cardData['LEAVE ID']).toString(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),


  floatingActionButton: FloatingActionButton(
        onPressed: () {
          showToast(
            "Apply For Leave",
            context: context,
            animation: StyledToastAnimation.slideFromBottom,
            reverseAnimation: StyledToastAnimation.slideToBottom,
            position: StyledToastPosition.bottom,
            animDuration: Duration(milliseconds: 400),
            duration: Duration(seconds: 2),
            curve: Curves.elasticOut,
            reverseCurve: Curves.elasticIn,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeaveForm(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<List<LeaveCardViewData?>> LeaveCardData() async {
    try {
      FirebaseService firebaseService = FirebaseService();
      SharedPreferences sharedPreferences = SharedPreferences();

      String? year = await sharedPreferences.getSecurePrefsValue("YEAR");
      String? branch = await sharedPreferences.getSecurePrefsValue("BRANCH");
      String? regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
      String? stream = await sharedPreferences.getSecurePrefsValue("STREAM");

      final List<LeaveCardViewData?> leaveCardData = [];

      List<String> documentNames = await firebaseService.getDocuments(studentLeaveRef);
      documentNames.sort((a, b) => b.compareTo(a));

      print("LeaveCardData documentNames: ${documentNames.toString()}");

      for (String document in documentNames) {
        studentLeaveFormRef = studentLeaveRef.doc(document);
        leaveCardData.add(await firebaseService.getSpecificLeaveData(studentLeaveFormRef));
      }

      print('LeaveCardData data: ${leaveCardData.toString()}');

      return leaveCardData;
    } catch (error) {
      print("Error fetching leave card data: $error");
      return [];
    }
  }

}
