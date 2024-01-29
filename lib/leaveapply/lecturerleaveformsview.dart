import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:klu_flutter/leaveapply/leavedetailsview.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/utils.dart';

import '../model/model.dart';
import '../utils/shraredprefs.dart';

class LecturerLeaveFormsView extends StatefulWidget {
  late String? privilege;
  LecturerLeaveFormsView({required this.privilege});
  @override
  _LecturerDataState createState() => _LecturerDataState();

}

class _LecturerDataState extends State<LecturerLeaveFormsView> {
  int selectedIndex = 0;
  late String leaveFormType;
  late LeaveCardViewData leaveCardViewData;
  FirebaseService firebaseService = FirebaseService();
  SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils=Utils();
  late List<String> yearList=[];
  late List<String> streamList=[];
  late DocumentReference? detailsRetrievingRef;
  late String? section='',branch,year,stream,staffID;

  List<String> spinnerOptions1 = [];
  List<String> spinnerOptions2 = [];
  String selectedSpinnerOption1 = '';
  String selectedSpinnerOption2 = '';

  // Boolean flags to control visibility for each spinner and button
  bool isSpinner1Visible = false;
  bool isSpinner2Visible = false;
  bool isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    if (widget.privilege == 'HOD') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      String? year = await sharedPreferences.getSecurePrefsValue('HOD YEAR');
      yearList = year!.split(',');
      String? stream = await sharedPreferences.getSecurePrefsValue('HOD STREAM');
      streamList = stream!.split(',');

      spinnerOptions1=streamList;
      spinnerOptions2=yearList;
      selectedSpinnerOption1=streamList[0];
      selectedSpinnerOption2=yearList[0];

      print('initializeData $yearList  $streamList');

    }else if (widget.privilege == 'YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible=true;

      String? year = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
      yearList = year!.split(',');
      String? stream = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
      streamList = stream!.split(',');

      spinnerOptions1=streamList;
      spinnerOptions2=yearList;
      selectedSpinnerOption1=streamList[0];
      selectedSpinnerOption2=yearList[0];
      print('initializeData $yearList  $selectedSpinnerOption1');

    } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      section = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

      spinnerOptions1 = ['SECTION', 'YEAR COORDINATOR'];
      selectedSpinnerOption1='SECTION';
      spinnerOptions2.add(section!);
      selectedSpinnerOption2 = section ?? 'SECTION NOT FOUND';
      String? year = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
      yearList = year!.split(',');
      print('initializeData: $section $selectedSpinnerOption1 $spinnerOptions1 $spinnerOptions2');
    } else {
      utils.showToastMessage('UNABLE TO GET THE DETAILS', context);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // First Spinner
          Visibility(
            visible: isSpinner1Visible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedSpinnerOption1,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSpinnerOption1 = newValue!;
                    //updateSpinner();
                    // Handle changes for the first spinner
                  });
                },
                items: spinnerOptions1.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),

          // Second Spinner
          Visibility(
            visible: isSpinner2Visible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedSpinnerOption2,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSpinnerOption2 = newValue!;
                  });
                },
                items: spinnerOptions2.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),

          // Check Button
          Visibility(
            visible: isButtonVisible,
            child: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                // Handle the check button press
                // You can access the selected values from the spinners here
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'PENDING',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'ACCEPTED',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear),
            label: 'REJECTED',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  void updateSpinner() {
    if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      if (selectedSpinnerOption1 == 'SECTION') {
        isButtonVisible = false;
        spinnerOptions2.clear();
        spinnerOptions2.add(section!);
        selectedSpinnerOption2 = section!;
      } else if (selectedSpinnerOption1 == 'YEAR COORDINATOR') {
        isButtonVisible = true;
        spinnerOptions2.clear();
        spinnerOptions2 = spinnerOptions2 + yearList;
        selectedSpinnerOption2 = yearList[0];
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (selectedIndex) {
      case 0:
        return _buildPendingTab();
      case 1:
        return _buildAcceptedTab();
      case 2:
        return _buildRejectedTab();
      default:
        return Container();
    }
  }

  Widget _buildPendingTab() {
    leaveFormType='PENDING';
    return FutureBuilder<List<LeaveCardViewData>>(
      future: _fetchLeaveData(leaveFormType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No $leaveFormType Forms',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return _displayLeaveData(snapshot.data!,leaveFormType);
        } else {
          return Center(
            child: Text('No Pending Forms'),
          );
        }
      },
    );
  }

  Widget _buildAcceptedTab() {
    leaveFormType = 'ACCEPTED';
    return FutureBuilder<List<LeaveCardViewData>>(
      future: _fetchLeaveData(leaveFormType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No $leaveFormType Forms',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return _displayLeaveData(snapshot.data!, leaveFormType);
        } else {
          return Center(
            child: Text('No Pending Forms'),
          );
        }
      },
    );
  }

  Widget _buildRejectedTab() {
    leaveFormType='REJECTED';
    return FutureBuilder<List<LeaveCardViewData>>(
      future: _fetchLeaveData(leaveFormType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No $leaveFormType Forms',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return _displayLeaveData(snapshot.data!,leaveFormType);
        } else {
          return Center(
            child: Text('No Pending Forms'),
          );
        }
      },
    );
  }

  Widget _displayLeaveData(List<LeaveCardViewData> leaveCardViewDataList, String leaveformtype) {
    return ListView.builder(
      itemCount: leaveCardViewDataList.length,
      itemBuilder: (context, index) {
        final leaveCardData = leaveCardViewDataList[index];
        return Card(
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${leaveCardData.startdate}'),
                    Text(" TO "),
                    Text('Return: ${leaveCardData.returndate}'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID: ${leaveCardData.id}'),
                    Text('Status: ${leaveCardData.verified}')
                  ],
                ),
              ],
            ),
            onTap: () async {
              // Navigate to leave data screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveDetailsView(
                    leaveid: leaveCardData.id,
                    leaveformtype: leaveformtype,
                    lecturerRef: detailsRetrievingRef!.path,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  Future<List<LeaveCardViewData>> _fetchLeaveData(String formType) async {
    print('fetchLeaveData started');
    String? yearCoordinatorStream=await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
    String? yearCoordinatorBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    String? hodBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    String? faYear=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
    String? faStream=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
    String? faBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    String? faSection=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

    if (widget.privilege == 'HOD') {
      // Handle HOD case
      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$hodBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$formType');
    } else if (widget.privilege == 'FACULTY ADVISOR') {

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$faSection/LEAVE FORMS/$formType');

    } else if (widget.privilege == 'YEAR COORDINATOR') {

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$formType');

    } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {

      if(selectedSpinnerOption1=='SECTION'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$selectedSpinnerOption2/LEAVE FORMS/$formType');
      }else if(selectedSpinnerOption1=='YEAR COORDINATOR'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$yearCoordinatorStream/LEAVE FORMS/$formType');
      }else{
        utils.showToastMessage('UNABLE TO GET THE SPINNER DETAILS', context);
      }

    } else {
      utils.showToastMessage('UNABLE TO GET THE DETAILS', context);
    }

    print('detailsRetrievingRef fetchLeaveData: ${detailsRetrievingRef.toString()}');

    DocumentReference studentLeaveForms;
    List<LeaveCardViewData> listLeaveCardViewData = [];

    Map<String, dynamic> getLeaveDetails = await firebaseService.getMapDetailsFromDoc(detailsRetrievingRef!);

    for (MapEntry<String, dynamic> data in getLeaveDetails.entries) {
      String key = data.key;
      DocumentReference value = data.value;
      studentLeaveForms = value;
      print('$key : $value');
      LeaveCardViewData? leaveCardViewData = await firebaseService.getSpecificLeaveData(studentLeaveForms.collection('LEAVE FORMS').doc(key));

      if (leaveCardViewData != null) {
        listLeaveCardViewData.add(leaveCardViewData);
      }
    }
    listLeaveCardViewData.sort((a, b) => a.id.compareTo(b.id));

    print('Lecturer LeaveCardViewData: ${listLeaveCardViewData.toString()}');
    return listLeaveCardViewData;
  }
}
