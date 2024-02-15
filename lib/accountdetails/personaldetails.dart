import 'package:flutter/material.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class PersonalDetails extends StatefulWidget {
  @override
  _PersonalDetailsState createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils=Utils();
  String? privilege;
  List<String> data = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    if (privilege == 'STUDENT') {
      data = ['NAME', 'REGISTRATION NUMBER', 'YEAR', 'BRANCH', 'STREAM'];
    } else if (privilege == 'LECTURERS' || privilege == 'YEAR COORDINATOR' || privilege == 'HOD' || privilege == 'FACULTY ADVISOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      data = ['NAME', 'STAFF ID', 'BRANCH','PRIVILEGE'];
    }else{
      utils.showToastMessage('Unable to get teh details', context);
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Details'),
      ),
      body: Center(
        child: privilege != null
            ? ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                '${data[index]} : ' ,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // Increase font size to 18
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4), // Add spacing between the title and subtitle
                  FutureBuilder<String?>(
                    future: getPersonalDetail(data[index]), // Fetch the personal detail from SharedPreferences
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Show a loading indicator while fetching data
                      } else if (snapshot.hasData) {
                        return Text(
                          snapshot.data!,
                          style: TextStyle(fontSize: 16), // Increase font size to 16
                        );
                      } else {
                        return Text(
                          'N/A', // Display 'N/A' if data is not available
                          style: TextStyle(fontSize: 16), // Increase font size to 16
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        )
            : CircularProgressIndicator(), // Show a loading indicator until privilege data is fetched
      ),
    );
  }

  // Method to get personal detail from SharedPreferences
  Future<String?> getPersonalDetail(String key) async {
    String? detail = await sharedPreferences.getSecurePrefsValue(key);
    return detail;
  }
}
