import 'package:api_project/Auth.dart';
import 'package:api_project/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


import 'firebase_options.dart';

const clientId = 'AIzaSyCQBumRFz5uG3U-YWnAPqoySDWqGLibUhA';

//async lets task run at the same time without waiting
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp(clientId: clientId));

}