import 'package:flutter/material.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';

class FacultyDetails extends StatefulWidget {
  @override
  _FacultyDetailsState createState() => _FacultyDetailsState();
}

class _FacultyDetailsState extends State<FacultyDetails> {
  final SharedPreferences sharedPreferences = SharedPreferences();
  String? privilege;
  List<String> data = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    data = [];
    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');

    if (privilege == 'STUDENT') {
      data = ['FACULTY ADVISOR NAME', 'FACULTY ADVISOR STAFF ID', 'YEAR COORDINATOR NAME', 'YEAR COORDINATOR STAFF ID'];
    } else if (privilege == 'LECTURERS' || privilege == 'YEAR COORDINATOR' || privilege == 'HOD' || privilege == 'FACULTY ADVISOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      data = ['NAME', 'STAFF ID', 'YEAR', 'BRANCH'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty Details'),
      ),
      body: Center(
        child: FutureBuilder(
          future: initializeData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      '${data[index]} : ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: FutureBuilder<String?>(
                      future: getPersonalDetail(data[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(fontSize: 16),
                          );
                        } else {
                          return Text(
                            'N/A',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<String?> getPersonalDetail(String key) async {
    String? detail = await sharedPreferences.getSecurePrefsValue(key);
    return detail;
  }
}
