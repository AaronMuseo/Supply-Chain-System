import 'package:http/http.dart' as http;

class EmailService {
  static Future<bool> sendOtpEmail(String email, String otp) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/send_otp.php'), // Use your IP if not on same device
      body: {
        'email': email,
        'otp': otp,
      },
    );
    if (response.statusCode == 200) {
      return response.body.contains('"success":true');
    }
    return false;
  }
}

 
