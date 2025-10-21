import 'package:firebase_auth/firebase_auth.dart' hide  EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class Authentication extends StatelessWidget{
  const Authentication({super.key, required this.clientId});

  final String clientId;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(!snapshot.hasData){
            return Scaffold(
              body: Card(
                color: Colors.amber,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
                margin: const EdgeInsets.all(10),
                child: SignInScreen(
                  providers: [EmailAuthProvider()],
                  subtitleBuilder: (context, action){
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                    child: action == AuthAction.signIn
                        ? const Text("Welcome to the System, Sign in")
                        : const Text("Welcome to the system, Sign up"),
                    );
                  },
                  footerBuilder: (context, action){
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text("By signing in, you agree to our terms and conditions.",
                      style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                )
            ),
            );

          }
          return Homepage();
        });
  }
}