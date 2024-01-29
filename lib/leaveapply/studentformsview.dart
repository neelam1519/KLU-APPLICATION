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
  final List<LeaveCardViewData> data = [];
  Utils utils = Utils();

  @override
  void initState() {
    super.initState();
    utils.showDefaultLoading();
    fetchLeaveCardData();
  }

  Future<void> fetchLeaveCardData() async {
    try {
      final List<LeaveCardViewData?> fetchedData = await LeaveCardData();
      setState(() {
        data.clear();
        data.addAll(fetchedData.where((item) => item != null).cast<LeaveCardViewData>());
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
      body: Column(
        children: [
          Expanded(
            child: data.isEmpty
                ? Center(child: Text('No Leave Data Available'))  // Replace CircularProgressIndicator with a Text widget
                : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                final cardData = data[index];
                return Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Start: ${cardData.startdate}'),
                            Text(" TO "),
                            Text('Return: ${cardData.returndate}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ID: ${cardData.id}'),
                            Text('Status: ${cardData.verified}'),
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
                            builder: (context) => LeaveDetailsView(leaveid: cardData.id, leaveformtype: 'STUDENT',lecturerRef: ''),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

      CollectionReference studentLeaveRef =
      FirebaseFirestore.instance.collection('/KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo/LEAVE FORMS/');

      List<String> documentNames = await firebaseService.getDocuments(studentLeaveRef);
      documentNames.sort((a, b) => b.compareTo(a));

      print("LeaveCardData documentNames: ${documentNames.toString()}");

      for (String document in documentNames) {
        DocumentReference studentLeaveFormRef = studentLeaveRef.doc(document);
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
