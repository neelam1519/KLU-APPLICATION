import 'package:flutter/material.dart';

class UserAccount extends StatefulWidget {
  @override
  _UserAccountState createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  // Variables to store user details
  String name = "John Doe";
  String email = "john.doe@example.com";
  String regNo = "ABC123";
  String mobileNumber = ""; // To store user's mobile number
  String otp = ""; // To store user's entered OTP
  bool showOtpField = false; // Flag to show/hide OTP field

  // Method to handle image upload
  void handleImageUpload() {
    // Implement image upload logic here
    // This could involve showing a file picker or launching the camera, depending on your requirements
  }

  // Method to initiate OTP verification
  void initiateOtpVerification() {
    // Implement OTP verification logic here
    // This could involve sending an OTP to the entered mobile number

    // Set the flag to show the OTP field
    setState(() {
      showOtpField = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Account'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back when the back button is pressed
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image at the top and center
            Container(
              width: double.infinity,
              height: 200.0,
              color: Colors.grey, // Placeholder color
              child: Center(
                child: Text(
                  'User Image', // Replace with your image widget or logic
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // SizedBox to create space between image and button
            SizedBox(height: 16),

            // Button to upload image
            ElevatedButton(
              onPressed: handleImageUpload,
              child: Text('Upload Image'),
            ),

            // SizedBox to create space between button and TextViews
            SizedBox(height: 16),

            // TextViews with user details
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Increase the size of TextViews and set them to match the width
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Name: $name',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Email: $email',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Registration Number: $regNo',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // SizedBox to create space between TextViews and MobileNumber/OTP row
            SizedBox(height: 16),

            // MobileNumber/OTP row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Expanded widget makes sure MobileNumber takes the whole width when OTP is not visible
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        // Update mobileNumber variable when user enters mobile number
                        setState(() {
                          mobileNumber = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // SizedBox to create space between MobileNumber and OTP
                  SizedBox(width: 16),

                  // Conditional rendering of OTP TextField
                  showOtpField
                      ? Expanded(
                    child: TextField(
                      onChanged: (value) {
                        // Update otp variable when user enters OTP
                        setState(() {
                          otp = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                      : SizedBox.shrink(),

                  // SizedBox to create space between OTP TextField and Verify OTP button
                  SizedBox(width: 16),

                  // Button to initiate OTP verification or get OTP
                  ElevatedButton(
                    onPressed: showOtpField ? initiateOtpVerification : () {},
                    child: Text(showOtpField ? 'Verify OTP' : 'Get OTP'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: UserAccount(),
  ));
}
