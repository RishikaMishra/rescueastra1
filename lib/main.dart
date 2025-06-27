import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rescueastra/screen/Login.dart';
import 'package:rescueastra/services/sos_emergency_service.dart';
import 'firebase_options.dart'; // Ensure you have this file configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensures Firebase is set up for web
  );

  // Initialize SOS Emergency Service
  final sosService = SOSEmergencyService();
  await sosService.initialize();

  runApp(const RescueAstraApp());
}

class RescueAstraApp extends StatelessWidget {
  const RescueAstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartingPage(),
    );
  }
}

class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D2495),
      body: Column( 
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          Center(
            child: Image.asset(
              'assets/logo.png',
              width: 350,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 90,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/icon.png',
                  fit: BoxFit.cover,
                  width: 350,
                  height: 350,
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA82B66),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                  );// Implement Firebase authentication or navigation here
                },
                child: const Text(
                  "Go & Take a step ahead to Safe World",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
