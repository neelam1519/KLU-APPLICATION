import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/leaveapply/leavedetailsview.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/RealtimeDatabase.dart';
import 'package:klu_flutter/utils/utils.dart';
import '../utils/shraredprefs.dart';

class LecturerLeaveFormsView extends StatefulWidget {
  final String? privilege;

  LecturerLeaveFormsView({required this.privilege});

  @override
  _LecturerDataState createState() => _LecturerDataState();
}

class _LecturerDataState extends State<LecturerLeaveFormsView> {
  int selectedIndex = 0;
  late String leaveFormType = 'PENDING';

  late Utils utils=Utils();
  late FirebaseService firebaseService=FirebaseService();
  late SharedPreferences sharedPreferences=SharedPreferences();
  RealtimeDatabase realtimeDatabase=RealtimeDatabase();

  late List<String> yearList = [];
  late List<String> streamList = [];
  late final Map<dynamic,List<Map<dynamic, dynamic>>> dataList={};
  List<String> oneWeekDates=[];

  late String textAboveTable='';
  late DocumentReference? detailsRetrievingRef=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
  late String? faSection, branch='', year, stream, staffID,hodYear;
  late String? yearCoordinatorStream='', faYear='', faStream='',yearCoordinatorYear='',hostelName='', hostelFloor='',hostelType='';
  DocumentReference studentLeaveForms = FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

  //Spinner list and selected values
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
    data().then((_) {
      initializeSpinners();
      setState(() {

      });
    });
  }

  Future<void> initializeSpinners() async {
    if (widget.privilege == 'HOD') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      yearList = hodYear!.split(',');

      spinnerOptions1 = ['CS','AIML','DS','IOT'];
      spinnerOptions2 = yearList;
      selectedSpinnerOption1 = 'CS';
      selectedSpinnerOption2 = yearList.isNotEmpty ? yearList[0] : '';

    } else if(widget.privilege == 'FACULTY ADVISOR' || widget.privilege=='HOSTEL WARDEN'){
      //No spinners will be seen
    } else if(widget.privilege == 'YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      yearList = yearCoordinatorYear!.split(',');
      streamList = yearCoordinatorStream!.split(',');

      spinnerOptions1 = streamList;
      spinnerOptions2 = yearList;
      selectedSpinnerOption1 = streamList.isNotEmpty ? streamList[0] : '';
      selectedSpinnerOption2 = yearList.isNotEmpty ? yearList[0] : '';

    } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      spinnerOptions1 = ['SECTION', 'YEAR COORDINATOR'];
      selectedSpinnerOption1 = 'SECTION';
      spinnerOptions2 = [faSection ?? 'SECTION NOT FOUND'];
      selectedSpinnerOption2 = spinnerOptions2[0];

      print('initializeData ${faSection.toString()}  ${yearCoordinatorYear.toString()}');
    } else {
      utils.showToastMessage('UNABLE TO GET THE SPINNER DETAILS ${widget.privilege}', context);
    }
  }

  Future<void> data() async{
    print('Retrieving the data');

    hodYear = await sharedPreferences.getSecurePrefsValue('YEAR');
    yearCoordinatorStream =await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
    branch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    yearCoordinatorYear = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
    faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
    faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
    faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');
    hostelName = await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
    hostelFloor = await sharedPreferences.getSecurePrefsValue('HOSTEL FLOOR');
    hostelType = await sharedPreferences.getSecurePrefsValue('HOSTEL TYPE');
    faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');


    print('YEAR COORDINATOR STREAM: $yearCoordinatorStream');
    print('BRANCH: $branch');
    print('YEAR COORDINATOR YEAR: $yearCoordinatorYear');
    print('FACULTY ADVISOR YEAR: $faYear');
    print('FACULTY ADVISOR STREAM: $faStream');
    print('FACULTY ADVISOR SECTION: $faSection');
    print('HOSTEL NAME: $hostelName');
    print('HOSTEL FLOOR: $hostelFloor');
    print('HOSTEL TYPE: $hostelType');
  }

  void updateRef() {
    try {
      print('updateRef');
      if(widget.privilege != null){
        switch(widget.privilege){
          case 'HOD':

            detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$branch/YEARCOORDINATOR/$selectedSpinnerOption1/LEAVEFORMS/$leaveFormType');
            break;

          case 'FACULTY ADVISOR':

            print('entered faculty advisor :${detailsRetrievingRef!.path}');
            print('$faYear  $branch  $faStream  $faSection  $leaveFormType');
            detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASSROOMDETAILS/$faYear/$branch/$faStream/$faSection/LEAVEFORMS/$leaveFormType');
            print('detailRetrievingRef test: ${detailsRetrievingRef!.path}');
            break;

          case 'HOSTEL WARDEN':

            detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/$hostelFloor/$leaveFormType');
            break;

          case 'YEAR COORDINATOR':

            detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$branch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');
            break;

          case 'FACULTY ADVISOR AND YEAR COORDINATOR':

            if (selectedSpinnerOption1 == 'SECTION') {
              detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$branch/$faStream/$selectedSpinnerOption2/LEAVE FORMS/$leaveFormType');
            } else if (selectedSpinnerOption1 == 'YEAR COORDINATOR') {
              detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/${branch ?? 'branch'}/YEAR COORDINATOR/${yearCoordinatorStream ?? 'stream'}/LEAVE FORMS/$leaveFormType');
            }
            break;

          default:
            utils.showToastMessage('UNABLE TO GET THE REFERENCE DETAILS', context);
        }
      } else {
        utils.showToastMessage('Widget privilege is null', context);
      }
      setState(() {

      });
      print('detailsRetrievingRef: ${detailsRetrievingRef!.path}');
    } catch (e) {
      // Handle the exception as per your application's requirements
      print('Error constructing detailsRetrievingRef: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle='';
    if(widget.privilege=='FACULTY ADVISOR' || widget.privilege=='HOSTEL WARDEN'){
      appBarTitle = 'Leave Forms';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // First Spinner
          Visibility(
            visible: isSpinner1Visible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedSpinnerOption1,
                onChanged: (String? newValue) {
                  if(selectedSpinnerOption1==newValue){
                    return;
                  }
                  updateRef();
                  setState(() {
                    onSpinner1Changed(newValue);
                    selectedSpinnerOption1 = newValue!;
                      buildTab();

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

                  if(selectedSpinnerOption2==newValue){
                    return;
                  }

                  print('isSpinner2Visible: ${spinnerOptions2.toString()}');
                  setState(() {
                    updateRef();
                    buildTab();
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
                if(leaveFormType=='PENDING'){
                  showAlertDialog(context);
                }else{
                  utils.showToastMessage('option is disabled here', context);
                }
              },
            ),
          ),
        ],
      ),
      body: _buildBody() ,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'REPORT',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> getData() async {
    await data();
    await initializeSpinners();
  }

  void _onItemTapped(int index) {
    setState(() {
      print('onItemTapped');
      selectedIndex = index;
    });
  }

  Widget _buildBody() {
    print('Build body');
    if (selectedIndex == 3) {
      return FutureBuilder<void>(
        future: showReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show a loading indicator while data is being fetched
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            print('datalist: ${dataList.toString()}');
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10), // Add some spacing between the text field and the table
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildTableRows(),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      leaveFormType = selectedIndex == 0 ? 'PENDING' : (selectedIndex == 1 ? 'ACCEPTED' : 'REJECTED');
      updateRef();
      return buildTab();
    }
  }

  Future<void> showReport() async{
    oneWeekDates=utils.getOneWeekDates();
    List<String> formTypes=['APPLIED','ACCEPTED','REJECTED'];
    int count=0;
    dataList.clear();
    switch(widget.privilege){
      case 'FACULTY ADVISOR':

          String key = 'SECTION $faSection';
          //print('key: ${key.toString()}');
          for (int i = 0; i < oneWeekDates.length; i++) {
            //print(oneWeekDates[i]);
            Map<dynamic, dynamic> rowData = {'Date': oneWeekDates[i]};
            // Iterate through form types to get leave counts for each type
            for (int j = 0; j < formTypes.length; j++) {
              String path = '/KLU/${oneWeekDates[i]}/$faYear/$branch/$faStream/$faSection/${formTypes[j]}';
              //print('path: ${path.toString()}');
              count = await realtimeDatabase.getLeaveCount(path); // Accumulate counts from each section
              //print('count: ${count}');
              rowData[formTypes[j]] = count; // Assign the total count for the form type to the row data
            }
            //print('rowData: ${rowData.toString()}');

            if (dataList.containsKey(key)) {
              // If the key already exists, add the row data to the existing list
              dataList[key]!.add(rowData);
            } else {
              // If the key doesn't exist, create a new list with the row data
              dataList[key] = [rowData];
            }
          }

        print('datalist: ${dataList.toString()}');
        break;
        
      case 'YEAR COORDINATOR':

        for (String yearEntry in yearList) {
          String key = '$yearCoordinatorStream $yearEntry';
          //print('key: ${key.toString()}');
          for (int i = 0; i < oneWeekDates.length; i++) {
            print(oneWeekDates[i]);
            Map<dynamic, dynamic> rowData = {'Date': oneWeekDates[i]};
            // Iterate through form types to get leave counts for each type
            for (int j = 0; j < formTypes.length; j++) {
              int count = 0; // Reset the count for each form type
              String path = '/KLU/${oneWeekDates[i]}/$yearEntry/$branch/$yearCoordinatorStream/';
              List<String> sectionList = await realtimeDatabase.getKeyNamesInsideKeys(path);
              for (String sectionEntry in sectionList) {
                String sectionPath = '$path$sectionEntry/${formTypes[j]}';
                count += await realtimeDatabase.getLeaveCount(sectionPath); // Accumulate counts from each section
              }
              rowData[formTypes[j]] = count; // Assign the total count for the form type to the row data
            }
            print('rowData: ${rowData.toString()}');

            if (dataList.containsKey(key)) {
              // If the key already exists, add the row data to the existing list
              dataList[key]!.add(rowData);
            } else {
              // If the key doesn't exist, create a new list with the row data
              dataList[key] = [rowData];
            }
          }
        }
        //print('dataList: :${dataList.toString()}');

        break;
      case 'FACULTY ADVISOR AND YEAR COORDINATOR':

        if(selectedSpinnerOption1=='SECTION'){
          String key = 'SECTION $faSection';
          //print('key: ${key.toString()}');
          for (int i = 0; i < oneWeekDates.length; i++) {
            //print(oneWeekDates[i]);
            Map<dynamic, dynamic> rowData = {'Date': oneWeekDates[i]};
            // Iterate through form types to get leave counts for each type
            for (int j = 0; j < formTypes.length; j++) {
              String path = '/KLU/${oneWeekDates[i]}/$faYear/$branch/$faStream/$faSection/${formTypes[j]}';
              //print('path: ${path.toString()}');
              count = await realtimeDatabase.getLeaveCount(path); // Accumulate counts from each section
              //print('count: ${count}');
              rowData[formTypes[j]] = count; // Assign the total count for the form type to the row data
            }
            //print('rowData: ${rowData.toString()}');

            if (dataList.containsKey(key)) {
              // If the key already exists, add the row data to the existing list
              dataList[key]!.add(rowData);
            } else {
              // If the key doesn't exist, create a new list with the row data
              dataList[key] = [rowData];
            }
          }
        }else if(selectedSpinnerOption1=='YEAR COORDINATOR'){

          for (String yearEntry in yearList) {
            String key = '$yearCoordinatorStream $yearEntry';
            //print('key: ${key.toString()}');
            for (int i = 0; i < oneWeekDates.length; i++) {
              print(oneWeekDates[i]);
              Map<dynamic, dynamic> rowData = {'Date': oneWeekDates[i]};
              // Iterate through form types to get leave counts for each type
              for (int j = 0; j < formTypes.length; j++) {
                int count = 0; // Reset the count for each form type
                String path = '/KLU/${oneWeekDates[i]}/$yearEntry/$branch/$yearCoordinatorStream/';
                List<String> sectionList = await realtimeDatabase.getKeyNamesInsideKeys(path);
                for (String sectionEntry in sectionList) {
                  String sectionPath = '$path$sectionEntry/${formTypes[j]}';
                  count += await realtimeDatabase.getLeaveCount(sectionPath); // Accumulate counts from each section
                }
                rowData[formTypes[j]] = count; // Assign the total count for the form type to the row data
              }
              //print('rowData: ${rowData.toString()}');

              if (dataList.containsKey(key)) {
                // If the key already exists, add the row data to the existing list
                dataList[key]!.add(rowData);
              } else {
                // If the key doesn't exist, create a new list with the row data
                dataList[key] = [rowData];
              }
            }
          }
        }
        print('datalist: ${dataList.toString()}');
        break;
      case 'HOD':
        List<String> streamList=['CS','AIML','DS','IOT'];
        for (String yearEntry in yearList) {
          //print('key: ${key.toString()}');
          for(String streams in streamList) {
            String key = '$streams $yearEntry';

            for (int i = 0; i < oneWeekDates.length; i++) {
              print(oneWeekDates[i]);
              Map<dynamic, dynamic> rowData = {'Date': oneWeekDates[i]};
              // Iterate through form types to get leave counts for each type
              for (int j = 0; j < formTypes.length; j++) {
                int count = 0; // Reset the count for each form type
                String path = '/KLU/${oneWeekDates[i]}/$yearEntry/$branch/$streams/';
                List<String> sectionList = await realtimeDatabase
                    .getKeyNamesInsideKeys(path);
                for (String sectionEntry in sectionList) {
                  String sectionPath = '$path$sectionEntry/${formTypes[j]}';
                  count += await realtimeDatabase.getLeaveCount(
                      sectionPath); // Accumulate counts from each section
                }
                rowData[formTypes[j]] =
                    count; // Assign the total count for the form type to the row data
              }
              //print('rowData: ${rowData.toString()}');

              if (dataList.containsKey(key)) {
                // If the key already exists, add the row data to the existing list
                dataList[key]!.add(rowData);
              } else {
                // If the key doesn't exist, create a new list with the row data
                dataList[key] = [rowData];
              }
            }
          }
        }

        break;
      default:

        utils.showDefaultLoading();
        return;
    }
  }

  List<Widget> _buildTableRows() {
    print('Build table rows started');
    List<Widget> tables = [];
    for (var entry in dataList.entries) {
      print('dataEntries: ${entry.toString()}');
      textAboveTable = entry.key;
      List<Map<dynamic, dynamic>> tableData = entry.value;
      List<TableRow> rows = [];

      // Add the additional header row
      List<Widget> headerCells = [];
      for (String header in ['DATE', 'APPLIED', 'ACCEPTED', 'REJECTED']) {
        headerCells.add(
          TableCell(
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: Text(header),
            ),
          ),
        );
      }
      rows.add(TableRow(children: headerCells));

      // Use a Set to store unique dates
      Set<String> uniqueDates = Set();

      // Add data rows
      for (int i = 0; i < tableData.length; i++) {
        Map<dynamic, dynamic> rowData = tableData[i];
        String date = rowData['Date'].toString();
        if (!uniqueDates.contains(date)) {
          List<Widget> cells = [];
          rowData.forEach((key, value) {
            cells.add(
              TableCell(
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(value.toString()),
                ),
              ),
            );
          });
          rows.add(TableRow(children: cells));
          uniqueDates.add(date); // Add the date to the set to avoid duplicates
        }
      }

      tables.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                textAboveTable,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Table(
              border: TableBorder.all(),
              defaultColumnWidth: IntrinsicColumnWidth(),
              children: rows,
            ),
          ],
        ),
      );
    }
    EasyLoading.dismiss();
    return tables;
  }

  Future<void> onSpinner1Changed(String? newValue) async {
    spinnerOptions2.clear();
    if (newValue != null && newValue.isNotEmpty) {
      if (widget.privilege == 'HOD') {
        if (newValue == 'AIML' || newValue == 'CS' || newValue == 'DS' || newValue == 'IOT') {
          yearList = hodYear!.split(',');
          print('hod year list: ${yearList}');
          spinnerOptions2.addAll(yearList);

        }
      } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
        if (newValue == 'SECTION') {
          isButtonVisible=false;
          spinnerOptions2.add(faSection ?? 'SECTION NOT FOUND');
        } else if (newValue == 'YEAR COORDINATOR') {
          isButtonVisible=true;
          yearList = yearCoordinatorYear!.split(',');
          yearList.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          spinnerOptions2.addAll(yearList);
        }
      } else if (widget.privilege == 'YEAR COORDINATOR') {
        yearList = yearCoordinatorYear!.split(',');
        spinnerOptions2.addAll(yearList);
      } else {
        utils.showToastMessage('You are not authorized to change', context);
      }
    } else {
      // Handle case where newValue is null or empty
      print('Invalid or empty newValue');
    }

    selectedSpinnerOption2 = spinnerOptions2.isNotEmpty ? spinnerOptions2[0] : '';
    print('spinner2values: ${spinnerOptions2.toString()}');
  }


  Widget buildTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: detailsRetrievingRef!.snapshots(),
      builder: (context, snapshot) {
        print('buildTab snapshot: ${snapshot.toString()}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[200],
              ),
              child: Text(
                'No $leaveFormType Forms Available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Customize the color
                ),
              ),
            ),
          );
        } else {
          Map<String, dynamic> leaveCardData = snapshot.data!.data() as Map<String, dynamic>;
          print('LEAVECARD DATA: ${leaveCardData.toString()}');

          return FutureBuilder<Map<String, dynamic>>(
            future: retrieveData(leaveCardData),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (dataSnapshot.hasError) {
                return Center(child: Text('Error: ${dataSnapshot.error}'));
              }  else if (!dataSnapshot.hasData || dataSnapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
                    ),
                    child: Text(
                      'No $leaveFormType Forms Available',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.red, // Customize the color
                      ),
                    ),
                  ),
                );
              } else {
                Map<String, dynamic> data = dataSnapshot.data!;
                print('buildTab: ${data.toString()}');

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    String key = data.keys.elementAt(index);
                    print('ListView.builder  key=$key');
                    Map<String, dynamic> value = data[key];

                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start: ${value['START DATE']}'),
                                Text(" TO "),
                                Text('Return: ${value['RETURN DATE']}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: ${value['LEAVE ID']}'),
                                Text('Status: ${value['VERIFICATION']}'),
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
                                leaveid: value['LEAVE ID'],
                                leaveformtype: leaveFormType,
                                lecturerRef: detailsRetrievingRef!.path,
                                type: selectedSpinnerOption1,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> retrieveData(Map<String, dynamic> leaveCardData) async {
    List<String> dataRequired = ['START DATE', 'RETURN DATE', 'LEAVE ID','VERIFICATION'];
    // Map to store retrieved data
    Map<String, dynamic> retrievedDataMap = {};
    print('leaveCardData:${leaveCardData.toString()}');

    for (MapEntry<String, dynamic> entry in leaveCardData.entries) {
      String key = entry.key;
      DocumentReference value = entry.value;
      studentLeaveForms = value.collection('LEAVE FORMS').doc(key);

      // Retrieve data for the current entry
      Map<String, dynamic>? retrievedData = await firebaseService.getValuesFromDocRef(studentLeaveForms, dataRequired);
      retrievedDataMap[key] = retrievedData;
    }

    for (MapEntry<String, dynamic> entry in retrievedDataMap.entries) {
      String key = entry.key;
      dynamic value = entry.value;
      print('retrievedDataMap: $key : $value');
    }
    // Return the map containing all retrieved data
    return retrievedDataMap;
  }

  Future<void> showAlertDialog(BuildContext context) async{
    // Show the alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('You want to accept all forms'),
          actions: [
            TextButton(
              onPressed: () async {
                // Handle the "OK" button press
                await acceptAllForms();
                Navigator.of(context).pop(); // Close the dialog
                // Add your logic for the "OK" action here
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Handle the "Cancel" button press
                Navigator.of(context).pop(); // Close the dialog
                // Add your logic for the "Cancel" action here
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> acceptAllForms() async {
    try {
      if (widget.privilege == 'YEAR COORDINATOR' || widget.privilege == 'HOD' || widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
        utils.showDefaultLoading();
        // Assuming detailsRetrievingRef is a DocumentReference
        CollectionReference collectionReference = await utils.DocumentToCollection(detailsRetrievingRef!);

        // Get the pending forms
        Map<String, dynamic> formRef = await firebaseService.getMapDetailsFromDoc(collectionReference.doc('PENDING'));

        // Loop through each form
        for (MapEntry<String, dynamic> entry in formRef.entries) {
          String key = entry.key;
          DocumentReference value = entry.value;

          Map<String,dynamic> data={};
          data.addAll({'YEAR COORDINATOR APPROVAL':true});

          // Update YEAR COORDINATOR APPROVAL to true
          await firebaseService.uploadMapDetailsToDoc(value.collection('LEAVEFORMS').doc(key),data,staffID! );

          data.clear();
          data.addAll({key:value});
          // Move the form to ACCEPTED collection
          await firebaseService.uploadMapDetailsToDoc(collectionReference.doc('ACCEPTED'), data,staffID!);

          // Get required fields
          List<String> requiredFieldNames = [
            'HOSTEL NAME',
            'HOSTEL ROOM NUMBER',
            'HOSTEL TYPE'
          ];
          Map<String, dynamic>? userDetails = await firebaseService.getValuesFromDocRef(value, requiredFieldNames);

          // Extract required fields
          String hostelName = userDetails!['HOSTEL NAME'];
          String hostelType = userDetails['HOSTEL TYPE'];
          String hostelFloor = userDetails['HOSTEL ROOM NUMBER'];

          // Move the form to HOSTEL PENDING collection
          DocumentReference hostelRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/${hostelFloor.substring(0, 1)}/PENDING');

          await firebaseService.uploadMapDetailsToDoc(hostelRef, data,staffID!);

          // Delete the form from the original collection
          await firebaseService.deleteField(detailsRetrievingRef!, key);
        }
      } else {
        utils.showToastMessage('You are not authorized to accept all', context);
      }
    } catch (e) {
      print('Accepting allForms Error: $e');
      utils.showToastMessage('Error occurred while accepting. Contact developer.', context);
    }
    EasyLoading.dismiss();
  }

}
