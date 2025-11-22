import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lets_see_what_happens/services/email_service.dart';
import 'package:lets_see_what_happens/screens/home_screen.dart';
import 'package:lets_see_what_happens/screens/main_app_screen.dart';
import '../main.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String userId;
  final String email;
  const OTPVerificationScreen({super.key, required this.userId, required this.email});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _sentMessage;

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _sentMessage = null; });
    try {
      // Generate a random OTP
      final otp = (100000 + (999999 - 100000) * (DateTime.now().millisecondsSinceEpoch % 1000) ~/ 1000).toString();
      // Store OTP in Firestore
      await FirebaseFirestore.instance.collection('otp_codes').doc(widget.userId).set({
        'otp': otp,
        'email': widget.email,
        'otp_verified': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Send OTP via email
      final sent = await EmailService.sendOtpEmail(widget.email, otp);
      setState(() {
        _sentMessage = sent ? 'OTP sent to your email.' : 'Failed to send OTP email.';
      });
    } catch (e) {
      setState(() { _sentMessage = 'Error: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() { _loading = true; _error = null; });
    try {
      final otpDoc = await FirebaseFirestore.instance
        .collection('otp_codes')
        .doc(widget.userId)
        .get();
      if (!otpDoc.exists) {
        setState(() { _error = 'OTP not found or expired.'; });
        return;
      }
      final data = otpDoc.data()!;
      if (data['otp'] == _otpController.text.trim()) {
        // OTP is correct, grant access
        await FirebaseFirestore.instance.collection('otp_codes').doc(widget.userId).update({'otp_verified': true});
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainAppScreen()),
        );
      } else {
        setState(() { _error = 'Invalid OTP.'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter the OTP sent to ${widget.email}'),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            if (_sentMessage != null)
              Text(_sentMessage!, style: TextStyle(color: Colors.green)),
            SizedBox(height: 8),
            _loading
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _verifyOTP,
                        child: Text('Verify'),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _sendOtp,
                        child: Text('Send OTP'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
