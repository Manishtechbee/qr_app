import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'terms_conditions_screen.dart';


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {


    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasAcceptedTerms = prefs.getBool('termsAccepted') ?? false;

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => hasAcceptedTerms ? const HomeScreen() : const TermsConditionsScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[600],
      body: Stack(
        children: [
          // Move the image upwards slightly
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1, // Adjust this value to move the image up or down
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/App_loading.png',
                width: 520,
                height: 520,
              ),
            ),
          ),
          // Position the text separately
          Positioned(
            top: MediaQuery.of(context).size.height * 0.6, // Adjust this value to move the text up or down
            left: 0,
            right: 0,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FCI QR Generator',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Change loader color here
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
