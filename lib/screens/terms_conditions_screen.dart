import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  Future<void> _acceptTerms(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50), // Decreased height of the AppBar
        child: AppBar(
          title: const Center(child: Text('Terms and Conditions')), // Centered app bar content
        ),
      ),
      backgroundColor: Colors.grey[200], // Light minimal background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'General Terms:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. This app is used to generate QR codes for personal and commercial use.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '2. The QR codes generated are for informational purposes only and should not be used for sensitive information.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '3. User data will not be stored or shared with third parties without consent.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                const Text(
                  'User Responsibilities:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. Users are responsible for the content and usage of the generated QR codes.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '2. Users must comply with all applicable laws and regulations regarding QR code usage.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '3. Users should not use the app for illegal or malicious activities.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Disclaimer:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. The app developers are not liable for any misuse or damages resulting from the use of generated QR codes.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '2. The app may collect anonymized usage data for analytics purposes.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Additional Terms:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. Users must be at least 18 years old to use this app.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '2. The app reserves the right to modify these terms at any time without prior notice.',
                  style: TextStyle(fontSize: 17),
                ),
                const Text(
                  '3. Continued use of the app after modifications constitutes acceptance of the new terms.',
                  style: TextStyle(fontSize: 17),
                ),
                // Add more sections and terms as needed
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _acceptTerms(context),
                  child: const Text('Accept and Continue'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
