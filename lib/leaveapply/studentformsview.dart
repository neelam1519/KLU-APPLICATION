import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/leaveapply/leaveform.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

import 'leavedetailsview.dart';

class StudentsLeaveFormsView extends StatefulWidget {
  @override
  _StudentsLeaveFormsViewState createState() => _StudentsLeaveFormsViewState();
}

class _StudentsLeaveFormsViewState extends State<StudentsLeaveFormsView> {
  SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils = Utils();
  late CollectionReference studentLeaveRef=FirebaseFirestore.instance.collection('KLU/STUDENTDETAILS/1');

  @override
  void initState() {
    super.initState();
    utils.showDefaultLoading();
    fetchLeaveCardData();
  }

  Future<void> fetchLeaveCardData() async {
    String? regNo = await sharedPreferences.getSecurePrefsValue("REGISTRATION NUMBER");
    String? year=utils.getYearFromRegNo(regNo!);

    setState(() {
      studentLeaveRef = FirebaseFirestore.instance.collection('/KLU/STUDENTDETAILS/$year/$regNo/LEAVEFORMS/');
      EasyLoading.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YOUR LEAVE APPLICATIONS'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentLeaveRef.orderBy('START DATE', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            EasyLoading.dismiss();
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            EasyLoading.dismiss();
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            EasyLoading.dismiss();
            return Center(child: Text('No Leave Data Available'));
          } else {
            List<DocumentSnapshot> leaveForms = snapshot.data!.docs;
            return ListView.builder(
              itemCount: leaveForms.length,
              itemBuilder: (context, index) {
                EasyLoading.dismiss();
                return buildLeaveCard(leaveForms[index]);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          utils.showToastMessage('Apply For leave', context);
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


  Widget buildLeaveCard(DocumentSnapshot leaveForm) {
    final cardData = leaveForm.data() as Map<String, dynamic>;
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
                Text('Status: ${cardData['VERIFICATION STATUS']}'),
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
                  type: '',
                ),
              ),
            );
          }
        },
      ),
    );
  }

}
