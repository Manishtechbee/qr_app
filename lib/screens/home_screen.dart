import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';






void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class QrCodeData {
  final String link;
  final DateTime createdAt;
  Uint8List? logoImageBytes;

  QrCodeData({
    required this.link,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'link': link,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QrCodeData.fromJson(Map<String, dynamic> json) => QrCodeData(
    link: json['link'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class _HomeScreenState extends State<HomeScreen> {
  bool _appDisabled = false;
  List<QrCodeData> qrCodes = [];
  TextEditingController linkController = TextEditingController();
  File? _logo;
 


  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }






  @override


  Future<void> _loadQRCodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? qrCodesJson = prefs.getStringList('qrCodes');
    if (qrCodesJson != null) {
      List<QrCodeData> loadedQRCodes = qrCodesJson
          .map((json) => QrCodeData.fromJson(jsonDecode(json)))
          .toList();

      // Filter out QR codes older than 2 days
      List<QrCodeData> filteredQRCodes = loadedQRCodes.where((element) {
        return DateTime.now().difference(element.createdAt).inHours < 240;
      }).toList();

      setState(() {
        qrCodes = filteredQRCodes;
      });
    }
  }
  // Function to resize/compress image bytes

  Future<Uint8List> resizeImage(Uint8List bytes, {int width = 208, int height = 258}) async {
    try {
      // Decode the image
      img.Image? image = img.decodeImage(bytes);

      // Resize the image if it's not null
      if (image != null) {
        // Resize the image with a high-quality interpolation method
        img.Image resizedImage = img.copyResize(
          image,
          width: width,
          height: height,
          interpolation: img.Interpolation.cubic,
        );

        // Debug: Print original and resized image dimensions
        print('Original dimensions: ${image.width}x${image.height}');
        print('Resized dimensions: ${resizedImage.width}x${resizedImage.height}');

        // Encode the resized image to PNG and return as Uint8List
        Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage, level: 5)); // level 6 is a balance between quality and compression

        // Debug: Decode the resized image to verify dimensions
        img.Image? verifyImage = img.decodeImage(resizedBytes);
        if (verifyImage != null) {
          print('Verified resized dimensions: ${verifyImage.width}x${verifyImage.height}');
        }

        return resizedBytes;
      } else {
        throw Exception('Failed to decode image.');
      }
    } catch (e) {
      print('Error resizing image: $e');
      throw Exception('Failed to resize image.');
    }
  }


  void showQRCodePopup(BuildContext context, QrCodeData qrCode) {
    GlobalKey _globalKey = GlobalKey();
    TextEditingController _textController = TextEditingController();

    // Initial text to overlay on QR code
    String qrCodeText = '';
    // Initial color for QR code
    Color qrCodeColor =  Colors.black;

    List<Color> colorOptions = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];




    // Method to show image picker dialog
    void _showImagePicker() async {
      final picker = ImagePicker();
      final pickedFile = await picker.getImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        // Example of resizing/compressing image (you need to implement this function)
        final resizedBytes = await resizeImage(bytes);

        // Update QR code data with selected image bytes
        setState(() {
          qrCode.logoImageBytes = resizedBytes;
        });
      }
    }

    // Method to show color options dialog
    void _showColorOptionsDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select QR Code Color'),
            content: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: colorOptions
                  .map((color) => GestureDetector(
                onTap: () {
                  // Update QR code color
                  setState(() {
                    qrCodeColor = color;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ))
                  .toList(),
            ),
          );
        },
      );
    }

    // Method to capture and save QR code image with text overlay
    Future<void> _captureAndSaveImage(String qrCodeText) async {
      try {
        // Set the pixel ratio to a higher value for better quality
        double pixelRatio = 5.0; // Adjust as needed
        RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();


          // Save the image for mobile/desktop
          final directory = await getTemporaryDirectory();
          String filePath =
              '${directory.path}/qrcode_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);

          // Use gal to save the image
          await Gal.putImage(filePath, album: 'QR Codes');

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Download Successful'),
                content: Text('The QR code image with text has been saved to:\n$filePath'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );

      } catch (e) {
        print('Error saving QR code image: $e');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to save QR code image.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }


    // Method to print QR code image
    Future<void> _printQRCode(String qrCodeText) async {
      try {
        RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 5.0); // Increase pixelRatio for higher quality
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();


        // For mobile/desktop, use the Printing package
          await Printing.layoutPdf(onLayout: (format) async {
            final doc = pw.Document();

            // Calculate the dimensions of the QR code image
            double qrCodeSize = 300.0; // Adjust as needed

            doc.addPage(
              pw.Page(
                build: (context) {
                  return pw.Center(
                    child: pw.Container(
                      width: qrCodeSize,
                      height: qrCodeSize,
                      child: pw.Image(
                        pw.MemoryImage(pngBytes),
                        fit: pw.BoxFit.cover, // Ensure the image fills the specified dimensions
                      ),
                    ),
                  );
                },
              ),
            );

            return doc.save();
          });

      } catch (e) {
        print('Error printing QR code image: $e');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to print QR code image.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }


    void showPrinterSelectionDialog(BuildContext context, String qrCodeText) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Printer Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Normal Printer'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _printQRCode(qrCodeText); // Call your existing print function for normal printer
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bluetooth),
                  title: Text('Bluetooth Printer'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _printQRCode(qrCodeText); // Call your existing print function for normal printer
                  },
                ),

              ],
            ),
          );
        },
      );
    }

    // Method to show add text dialog
    Future<void> _showAddTextDialog(BuildContext context) async {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Text'),
            content: TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: "Enter the text"),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  // Update QR code text
                  setState(() {
                    qrCodeText = _textController.text;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    // Show the main QR code popup dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // List of color options for the dropdown
        List<Color> _colorOptions = [
          Colors.black,
          Colors.white,
          Colors.yellowAccent,
          Colors.purple,
          Colors.pinkAccent,
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange
        ];

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0.6, // No shadow
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of screen width
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          PopupMenuButton<Color>(
                            icon: Icon(
                              Icons.color_lens,
                              color: qrCodeColor,
                              size: 30.0,
                            ),
                            onSelected: (Color selectedColor) {
                              // Update QR code color
                              setState(() {
                                qrCodeColor = selectedColor;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return _colorOptions.map((Color color) {
                                return PopupMenuItem<Color>(
                                  value: color,
                                  child: Container(
                                    width: 24.0,
                                    height: 24.0,
                                    color: color,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),


                      SizedBox(height: 20.0),
                      RepaintBoundary(
                        key: _globalKey,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 15,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Container(
                                width: 208, // Adjusted size for QR code display
                                height: 258.0,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    QrImageView(
                                      data: qrCode.link,
                                      version: QrVersions.auto,
                                      size: 208.0, // QR code size
                                      backgroundColor: Colors.white,
                                      foregroundColor: qrCodeColor, // Set QR code color
                                      embeddedImage: qrCode.logoImageBytes != null
                                          ? MemoryImage(qrCode.logoImageBytes!)
                                          : AssetImage(
                                          'assets/images/qremb_logo.png'),
                                      embeddedImageStyle: QrEmbeddedImageStyle(
                                        size: Size(50, 50),
                                      ),
                                      errorCorrectionLevel: QrErrorCorrectLevel.H, // Highest error correction level
                                    ),
                                    if (qrCodeText.isNotEmpty)
                                      Positioned(
                                        bottom: -4.0,
                                        child: Text(
                                          qrCodeText,
                                          style: TextStyle(
                                            color: Colors.black, // Text color
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),

                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showImagePicker();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: Size(160.0, 40.0),
                          ),

                          child: Stack(
                            children: [
                              Positioned(
                                left: 10.0,
                                child:
                                Icon(
                                  Icons.image,
                                  color: Colors.lightBlue,
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Add Logo',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showAddTextDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: Size(160.0, 40.0),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10.0,
                                child:
                                Icon(Icons.text_fields, color: Colors.orange),
                              ),
                              Center(
                                child: Text(
                                  'Add Text',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showPrinterSelectionDialog(context, qrCodeText);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: Size(160.0, 40.0),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10.0,
                                child: Icon(Icons.print, color: Colors.green),
                              ),
                              Center(
                                child: Text(
                                  'Print',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _captureAndSaveImage(qrCodeText);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: Size(160.0, 40.0),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10.0,
                                child: Icon(Icons.save, color: Colors.blueAccent),
                              ),
                              Center(
                                child: Text(
                                  'Save To Gallery',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void toggleAppDisabledState() {
    setState(() {
      _appDisabled = !_appDisabled; // Toggle the app disabled state
    });
  }

  Future<void> _saveQRCodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> qrCodesJson = qrCodes.map((qr) => jsonEncode(qr.toJson())).toList();
    await prefs.setStringList('qrCodes', qrCodesJson);
  }

  Future<void> addLink() async {
    String link = linkController.text.trim();
    if (link.isEmpty) return;
    else
      _saveQRCodes();
    // Create a new QrCodeData object with the link and current timestamp
    QrCodeData newQrCode = QrCodeData(
      link: link,
      createdAt: DateTime.now(),

    );

    // Update the QR codes list
    setState(() {
      qrCodes.insert(0, newQrCode); // Add to the start of the list for recent display
    });

    // Save the updated QR codes list to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> qrCodesJson = qrCodes.map((qrCode) => jsonEncode(qrCode.toJson())).toList();
    await prefs.setStringList('qrCodes', qrCodesJson);

    // Clear the text field after adding the link
    linkController.clear();

    // Open the showQRCodePopup for the newly generated QR code
    showQRCodePopup(context, newQrCode);
  }

  void showPrivacyPolicyPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(
                'Privacy Policy\n\n'
                    '1. Introduction\n'
                    'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our mobile application (the "App"). '
                    'Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the App.\n\n'
                    '2. Collection of Your Information\n'
                    'We may collect information about you in a variety of ways. The information we may collect via the App depends on the content and materials you use, and includes:\n'
                    '    a. Personal Data\n'
                    '        - Demographic and other personally identifiable information (such as your name and email address) that you voluntarily give to us when choosing to participate in various activities related to the App, such as generating QR codes, sending feedback, and responding to surveys.\n'
                    '    b. Derivative Data\n'
                    '        - Information our servers automatically collect when you access the App, such as your IP address, your browser type, your operating system, your access times, and the pages you have viewed directly before and after accessing the App.\n'
                    '    c. Mobile Device Data\n'
                    '        - Device information such as your mobile device ID, model, and manufacturer, and information about the location of your device, if you access the App from a mobile device.\n\n'
                    '3. Use of Your Information\n'
                    'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the App to:\n'
                    '    - Create and manage your account.\n'
                    '    - Generate personalized QR codes.\n'
                    '    - Email you regarding your account or order.\n'
                    '    - Enable user-to-user communications.\n'
                    '    - Fulfill and manage purchases, orders, payments, and other transactions related to the App.\n'
                    '    - Increase the efficiency and operation of the App.\n'
                    '    - Monitor and analyze usage and trends to improve your experience with the App.\n\n'
                    '4. Disclosure of Your Information\n'
                    'We may share information we have collected about you in certain situations. Your information may be disclosed as follows:\n'
                    '    a. By Law or to Protect Rights\n'
                    '        - If we believe the release of information about you is necessary to respond to legal process, to investigate or remedy potential violations of our policies, or to protect the rights, property, and safety of others, we may share your information as permitted or required by any applicable law, rule, or regulation.\n'
                    '    b. Business Transfers\n'
                    '        - We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.\n\n'
                    '5. Security of Your Information\n'
                    'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.\n\n'
                    '6. Policy for Children\n'
                    'We do not knowingly solicit information from or market to children under the age of 13. If we learn that we have collected personal information from a child under age 13 without verification of parental consent, we will delete that information as quickly as possible. If you become aware of any data we have collected from children under age 13, please contact us at our contact email.\n\n'
                    '7. Changes to This Privacy Policy\n'
                    'We may update this Privacy Policy from time to time in order to reflect, for example, changes to our practices or for other operational, legal, or regulatory reasons.\n\n'
                    '8. Contact Us\n'
                    'If you have questions or comments about this Privacy Policy, please contact us at:\n'
                    '    Email: support@qrgeneratorapp.com\n\n'
                    'By using the App, you agree to be bound by this Privacy Policy. If you do not agree to this Privacy Policy, please do not use the App.'
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showTermsOfServicePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: SingleChildScrollView(
            child: Text(
                'Terms of Service\n\n'
                    '1. Introduction\n'
                    'These Terms of Service govern your use of the QR Generator mobile application (the "App") operated by QR Generator Inc. ("we," "us," or "our"). '
                    'By accessing and using the App, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these Terms of Service or our Privacy Policy, '
                    'please do not access or use the App.\n\n'
                    '2. Use of the App\n'
                    'You must be at least 13 years of age to use this App. By using the App and agreeing to these Terms of Service, you warrant and represent that you are at least 13 years of age.\n\n'
                    '3. Intellectual Property Rights\n'
                    'Unless otherwise indicated, the App and all content and other materials therein, including, without limitation, the QR codes generated, are the proprietary property of QR Generator Inc. and its licensors, if any, '
                    'and are protected by intellectual property laws.\n\n'
                    '4. User-Generated Content\n'
                    'By using the App, you grant us a perpetual, irrevocable, worldwide, non-exclusive, royalty-free, transferable license to use, reproduce, distribute, modify, adapt, '
                    'create derivative works of, publicly perform, publicly display, digitally perform, make, have made, sell, offer for sale and import your User Content in any media format and through any media channel.\n\n'
                    '5. Limitation of Liability\n'
                    'In no event shall QR Generator Inc., nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, '
                    'consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access to or use of or inability to access or use the App; '
                    '(ii) any conduct or content of any third party on the App; (iii) any content obtained from the App; and (iv) unauthorized access, use or alteration of your transmissions or content, '
                    'whether based on warranty, contract, tort (including negligence) or any other legal theory, whether or not we have been informed of the possibility of such damage, and even if a remedy set forth herein is found to have failed of its essential purpose.\n\n'
                    '6. Governing Law\n'
                    'These Terms of Service shall be governed by and construed in accordance with the laws of the State of California, United States, without regard to its conflict of law provisions.\n\n'
                    '7. Changes to These Terms of Service\n'
                    'We reserve the right, at our sole discretion, to modify or replace these Terms of Service at any time. If a revision is material we will provide at least 30 days notice prior to any new terms taking effect. '
                    'What constitutes a material change will be determined at our sole discretion.\n\n'
                    '8. Contact Us\n'
                    'If you have questions or comments about these Terms of Service, please contact us at:\n'
                    '    Email: support@qrgeneratorapp.com\n\n'
                    'By using the App, you agree to be bound by these Terms of Service. If you do not agree to these Terms of Service, please do not use the App.'
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showAccountSettingsPopup(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 8.0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10.0,
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      ListTile(
                        title: Text('Change Username'),
                        leading: Icon(Icons.person_outline),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Change Username'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: usernameController,
                                      decoration: InputDecoration(labelText: 'New Username'),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      // Save username functionality
                                      String newUsername = usernameController.text.trim();
                                      // Implement logic to save the new username
                                      print('New Username: $newUsername');
                                      Navigator.of(context).pop();
                                      // Close the username dialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      Divider(color: Colors.grey),
                      ListTile(
                        title: Text('Change Email'),
                        leading: Icon(Icons.email_outlined),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Change Email'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: emailController,
                                      decoration: InputDecoration(labelText: 'New Email'),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      // Save email functionality
                                      String newEmail = emailController.text.trim();
                                      // Implement logic to save the new email
                                      print('New Email: $newEmail');
                                      Navigator.of(context).pop();
                                      // Close the email dialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      Divider(color: Colors.grey),
                      ListTile(
                        title: Text('Change Password'),
                        leading: Icon(Icons.lock_outline),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Change Password'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(labelText: 'New Password'),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      // Save password functionality
                                      String newPassword = passwordController.text.trim();
                                      // Implement logic to save the new password
                                      print('New Password: $newPassword');
                                      Navigator.of(context).pop();
                                      // Close the password dialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  void showProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            File? _profileImage;
            final ImagePicker _picker = ImagePicker();

            final _nameController = TextEditingController();
            final _emailController = TextEditingController();
            final _phoneController = TextEditingController();
            final _addressController = TextEditingController();

            // Load saved data from SharedPreferences
            Future<void> _loadProfileData() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              setState(() {
                _nameController.text = prefs.getString('name') ?? '';
                _emailController.text = prefs.getString('email') ?? '';
                _phoneController.text = prefs.getString('phone') ?? '';
                _addressController.text = prefs.getString('address') ?? '';
                String? imagePath = prefs.getString('profileImage');
                if (imagePath != null && File(imagePath).existsSync()) {
                  _profileImage = File(imagePath);
                }
              });
            }

            Future<void> _pickImage() async {
              final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  _profileImage = File(pickedFile.path);
                });
              }
            }

            Future<void> _saveProfileImage() async {
              if (_profileImage == null) return;

              final directory = await getExternalStorageDirectory();
              String filePath =
                  '${directory?.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png';
              final file = File(filePath);
              await file.writeAsBytes(await _profileImage!.readAsBytes());
              await GallerySaver.saveImage(file.path);

              // Save the image path to SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('profileImage', file.path);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile picture saved successfully')),
              );
            }

            Future<void> _saveProfileData() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('name', _nameController.text);
              prefs.setString('email', _emailController.text);
              prefs.setString('phone', _phoneController.text);
              prefs.setString('address', _addressController.text);

              if (_profileImage != null) {
                await _saveProfileImage();
              }

              Navigator.of(context).pop();
            }

            @override
            void initState() {
              super.initState();
              _loadProfileData();
            }

            // Load the profile data when the dialog is first built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfileData();
            });

            return AlertDialog(
              title: Center(child: Text('Profile')),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : AssetImage('assets/default_profile.png') as ImageProvider,
                            ),
                            Positioned(
                              bottom: -5, // Adjust this value to overlap as desired
                              right: -2, // Adjust this value to overlap as desired
                              child: Icon(
                                Icons.add_a_photo,
                                size: 40, // Adjust size as needed
                                color: Colors.purple, // Optional: change color as per your design
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save Profile Pic'),
                  onPressed: _saveProfileImage,
                ),
                ElevatedButton(
                  child: Text('Save'),
                  onPressed: _saveProfileData,
                ),
              ],
            );
          },
        );
      },
    );
  }


  void showSettingsPopup(BuildContext context) {
    File _logoImage; // State variable to hold the selected logo image
    bool _appDisabled = false; // Example app disable state (replace with your logic)

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 8.0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                ListTile(
                  title: Text('Account Settings'),
                  leading: Icon(Icons.account_circle),
                  onTap: _appDisabled
                      ? null
                      : () {
                    Navigator.of(context).pop();
                    showAccountSettingsPopup(context);
                  },
                ),
                Divider(color: Colors.grey),
                ListTile(
                  title: Text('Privacy Policy'),
                  leading: Icon(Icons.privacy_tip),
                  onTap: () {
                    Navigator.of(context).pop();
                    showPrivacyPolicyPopup(context);
                  },
                ),
                Divider(color: Colors.grey),
                ListTile(
                  title: Text('Terms of Service'),
                  leading: Icon(Icons.description),
                  onTap: () {
                    Navigator.of(context).pop();
                    showTermsOfServicePopup(context);
                  },
                ),
                Divider(color: Colors.grey),
                ListTile(
                  title: Text('Disable App'),
                  leading: Icon(Icons.block),
                  trailing: Switch(
                    value: _appDisabled,
                    onChanged: (value) {
                      setState(() {
                        _appDisabled = value;
                      });
                      if (_appDisabled) {
                        showDisableAppConfirmation(context);
                      }
                      // Implement your logic to disable/enable app functionality here
                      // For example, you could set a flag and conditionally render components based on this flag.
                    },
                  ),
                ),
                Divider(color: Colors.grey),
                ListTile(
                  title: Text('Feedback'),
                  leading: Icon(Icons.feedback),
                  onTap: () {
                    Navigator.of(context).pop();
                    _submitFeedback(context);
                  },
                ),
                const SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitFeedback(BuildContext context) {
    // Implement your logic to handle feedback submission
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String feedbackText = '';

        return AlertDialog(
          title: Text('Provide Feedback'),
          content: TextField(
            onChanged: (value) {
              feedbackText = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter your feedback here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                // Handle submitting feedback (e.g., saving locally, sending to server)
                // Here you can decide what to do with feedbackText
                // For demonstration, we just print it
                print('Feedback submitted: $feedbackText');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Feedback submitted!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showDisableAppConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disable App'),
          content: Text('Are you sure you want to disable the app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Disable the app and show disabled message
                setState(() {
                  _appDisabled = true;
                });
                Navigator.of(context).pop();
                showAppDisabledMessage(context);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void showAppDisabledMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App Disabled'),
          content: Text(
              'The app has been disabled. Please uninstall it manually from your device settings.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            height: 125.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.9),
                  Colors.lightGreen.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 15.0),
                    child: Image.asset(
                      'assets/qr_logo.png',
                      width: 50.0,
                      height: 50.0,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: Text(
                      'QR Generator',
                      style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0, top: 22.0),
                      child: IconButton(
                        icon: const Icon(Icons.account_circle, size: 40.0, color: Colors.white),
                        onPressed: () {
                          showProfilePopup(context);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned(
            left: 12.0,
            top: 120.0,
            child: Container(
              width: 400.0,
              height: 400.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: _logo == null
                    ? Image.asset(
                  'assets/logo.png',
                  width: 350.0,
                  height:350.0,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  _logo!,
                  width:350.0,
                  height: 350.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height:18.0),
                const Text(
                  'Recent',
                  style: TextStyle(fontSize:25.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                SizedBox(
                  height: 200.0,
                  child: qrCodes.isEmpty
                      ? Center(
                    child: Text(
                      'No QR codes generated yet.',
                      style: TextStyle(fontSize: 17.0),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: qrCodes.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          showQRCodePopup(context, qrCodes[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width:150.0,
                            height: 150.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(17.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.25),
                                  spreadRadius: 2,
                                  blurRadius: 15,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.black.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                QrImageView(
                                  data: qrCodes[index].link,
                                  version: QrVersions.auto,
                                  size:130.0,
                                  embeddedImage: AssetImage('assets/images/qremb_logo.png'),
                                  embeddedImageStyle: QrEmbeddedImageStyle(
                                    size:Size(40, 40),
                                  ),
                                  errorCorrectionLevel: QrErrorCorrectLevel.H, // Highest error correction level
                                ),
                                SizedBox(height: 10.0),
                                Text(
                                  'Generated on:',
                                  style: TextStyle(fontSize:12.0, color: Colors.black54),
                                ),
                                Text(
                                  '${qrCodes[index].createdAt.toLocal().day}/${qrCodes[index].createdAt.toLocal().month}/${qrCodes[index].createdAt.toLocal().year}',
                                  style: TextStyle(fontSize:12.0, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
               SizedBox(height:100.0),
                const SizedBox(height: 5.0),
                Expanded(
                  child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'QR Code Generator',
                          style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 18.0),
                        Container(
                          width:350.0,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: linkController,
                            decoration: InputDecoration(
                              labelText: 'Copy your link here',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100.0),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: addLink,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        SizedBox(
                          width:150.0,
                          child: ElevatedButton(
                            onPressed: addLink,
                            style: ButtonStyle(
                              elevation: WidgetStateProperty.all(8.0),
                              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.lightGreen.withOpacity(0.9);
                                  }
                                  return Colors.green;
                                },
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                              ),
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.all(16.0),
                              ),
                            ),
                            child: const Text(
                              'Generate',
                              style: TextStyle(fontSize: 18.0, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                )],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            showSettingsPopup(context);
          }
        },
      ),
    );
  }


}