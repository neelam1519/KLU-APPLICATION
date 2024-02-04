import 'package:http/http.dart' as http;

void sendMessage(String recipientToken, String message) async {
  final url = 'http://your-server-url/send-message';
  final response = await http.post(
    Uri.parse(url),
    body: {
      'recipientToken': recipientToken,
      'message': message,
    },
  );

  if (response.statusCode == 200) {
    print('Message sent successfully');
  } else {
    print('Error sending message: ${response.body}');
  }
}
