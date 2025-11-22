import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/main_app_screen.dart';
import 'utils/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    Stripe.publishableKey = ApiKeys.stripePublicKey; // Only set on mobile
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supply Chain System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen();
        } else if (!user.emailVerified) {
          return EmailVerificationScreen();
        } else {
          // OTP verification is temporarily bypassed for testing.
          // To re-enable, uncomment the FutureBuilder and remove the direct return of MainAppScreen().
          return MainAppScreen();

          /*
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('otp_codes').doc(user.uid).get(),
            builder: (context, otpSnapshot) {
              if (otpSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final otpData = otpSnapshot.data?.data() as Map<String, dynamic>?;
              if (otpData == null || otpData['otp_verified'] != true) {
                return OTPVerificationScreen(userId: user.uid, email: user.email ?? '');
              } else {
                return MainAppScreen();
              }
            },
          );
          */
        }
      },
    );
  }
}
