import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qr_code_generator/scan_code_page.dart';
import 'package:device_info_plus/device_info_plus.dart'; // For fetching IMEI
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication

class FingerprintAuth extends StatefulWidget {
  const FingerprintAuth({Key? key}) : super(key: key);

  @override
  _FingerprintAuthState createState() => _FingerprintAuthState();
}

class _FingerprintAuthState extends State<FingerprintAuth> {
  final auth = LocalAuthentication();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance; // Firebase Auth instance
  String authorized = "Not authorized";
  bool _canCheckBiometric = false;
  late List<BiometricType> _availableBiometric;
  String? currentImei; // To hold the device IMEI

  // Function to get the IMEI number (for Android devices)
  Future<void> _getImei() async {
    var deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      currentImei = androidInfo.id; // For IMEI, you can use androidInfo.id
    });
  }

  // Function to handle authentication
  Future<void> _authenticate() async {
    await _getImei(); // Ensure you fetch the IMEI first
    bool authenticated = false;

    try {
      // Fetch the current user's email
      String? userEmail = firebaseAuth.currentUser?.email;

      if (userEmail == null) {
        setState(() {
          authorized = "No user logged in.";
        });
        return; // Stop further processing if no user is logged in
      }

      DocumentSnapshot userDoc = await firestore
          .collection('User_Info')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get()
          .then((QuerySnapshot snapshot) => snapshot.docs.first);

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Check if IMEI_no exists in the document
      if (userData.containsKey('IMEI_no')) {
        // If it exists, compare it with the current device's IMEI
        if (userData['IMEI_no'] == currentImei) {
          // Proceed with biometric authentication
          authenticated = await auth.authenticate(
            localizedReason: "Scan your finger to authenticate",
            options: const AuthenticationOptions(
              biometricOnly: true, // Use only biometrics for authentication
            ),
          );
        } else {
          // IMEI doesn't match
          setState(() {
            authorized = "IMEI mismatch. Authentication failed.";
          });
          return; // Stop further processing
        }
      } else {
        // If IMEI_no doesn't exist, add the current IMEI to Firestore
        await firestore
            .collection('User_Info')
            .doc(userDoc.id)
            .update({'IMEI_no': currentImei});
        setState(() {
          authorized = "IMEI added successfully. Please authenticate.";
        });
      }

    } on PlatformException catch (e) {
      print(e);
    }

    setState(() {
      authorized = authenticated ? "Authorized success" : "Failed to authenticate";
      if (authenticated) {
        // Navigate to ScanCodePage after successful authentication
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanCodePage()),
        );
      }
    });
  }

  Future<void> _checkBiometric() async {
    bool canCheckBiometric = false;

    try {
      canCheckBiometric = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometric = canCheckBiometric;
    });
  }

  Future<void> _getAvailableBiometric() async {
    List<BiometricType> availableBiometric = [];

    try {
      availableBiometric = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }

    setState(() {
      _availableBiometric = availableBiometric;
    });
  }

  @override
  void initState() {
    _checkBiometric();
    _getAvailableBiometric();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: Scaffold(
        // Wrapping AppBar with a PreferredSize widget to apply a gradient to the whole AppBar
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), // Adjust the size as needed
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0575E6), // RGB(5, 117, 230)
                  Color(0xFF021B79), // RGB(2, 27, 121)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, // Make AppBar transparent to show gradient
              elevation: 0, // Remove shadow
              title: const Text('Fingerprint Auth'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // This navigates back to the previous screen
                },
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white, // Set the body background color to white
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: Text(
                  "Authentication",
                  style: TextStyle(
                    color: Colors.black, // Set text color to black to contrast with white background
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15.0),
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0575E6), // RGB(5, 117, 230)
                        Color(0xFF021B79), // RGB(2, 27, 121)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent, // Set background to transparent to apply gradient
                      shadowColor: Colors.transparent, // Remove shadow color to show gradient
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 14.0,
                      ),
                    ),
                    child: const Text(
                      "Authenticate",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Display authorization status
              Text(
                authorized,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
