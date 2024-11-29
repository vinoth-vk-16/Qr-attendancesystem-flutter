import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String? lastScannedQrData; // Variable to track the last scanned QR code
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance

  // Function to parse QR code data and validate it
  bool validateQRCode(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      if (data['session_id'] == null || data['timestamp'] == null || data['token'] == null) {
        print('Missing required fields in QR code data');
        return false;
      }

      final sessionId = data['session_id'];
      final timestamp = DateTime.parse(data['timestamp']);

      // Check if timestamp is within 20 seconds
      final currentTime = DateTime.now();
      if (currentTime.difference(timestamp).inSeconds > 20) {
        print('QR Code expired');
        return false;
      }

      print('Session ID: $sessionId');
      return true;
    } catch (e) {
      print('Invalid QR Code format: $e');
      return false;
    }
  }

// Function to check if the user already scanned the QR code for a specific session
  Future<bool> hasAlreadyScanned(String sessionId, String userEmail) async {
    QuerySnapshot existingScan = await FirebaseFirestore.instance
        .collection('attendance')
        .where('studentMail', isEqualTo: userEmail)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    return existingScan.docs.isNotEmpty; // Returns true if the user has already scanned this session
  }

// Function to log attendance in Firestore with duplicate scan check
  Future<void> logAttendance(String sessionId, String qrCode) async {
    try {
      // Get the current user
      User? user = _auth.currentUser;

      if (user != null) {
        // Check if the user has already scanned for this session
        bool alreadyScanned = await hasAlreadyScanned(sessionId, user.email!);

        if (alreadyScanned) {
          // Show an error dialog if the user has already scanned
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Duplicate Scan'),
                content: const Text('You have already scanned for this session.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Exit the function to prevent logging a duplicate entry
        }

        // Proceed with logging the attendance if it's not a duplicate
        CollectionReference attendance = FirebaseFirestore.instance.collection('attendance');

        await attendance.add({
          'attendanceId': 'Attendance${DateTime.now().millisecondsSinceEpoch}', // Unique ID for the attendance entry
          'studentMail': user.email, // Fetch the user's email from Firebase Auth
          'sessionId': sessionId, // Session in which the QR code was scanned
          'qrCode': qrCode, // The unique QR code value for the session
          'scanTime': DateTime.now().toUtc().toIso8601String(), // The time the student scanned the code in ISO 8601 format
        });

        print('Attendance logged successfully for ${user.email}');
      } else {
        print('No user is currently logged in');
      }
    } catch (e, stackTrace) {
      print('Error logging attendance: $e');
      print(stackTrace); // Print stack trace for more details
    }
  }


  // Function to show a dialog confirming the successful scan
  void _showConfirmationDialog(String sessionId, String qrData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Valid QR Code'),
          content: Text('QR Code Data: $qrData'),
          actions: [
            TextButton(
              onPressed: () {
                logAttendance(sessionId, qrData); // Log attendance in Firestore
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SCAN QR"),
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: true,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;

          for (final barcode in barcodes) {
            final qrData = barcode.rawValue ?? "";
            print('Barcode found: $qrData');

            // Check if this QR code is the same as the last scanned one
            if (lastScannedQrData == qrData) {
              print('This QR code has already been scanned.');
              return; // Ignore duplicate scans
            }

            if (validateQRCode(qrData)) {
              // Proceed with session verification
              final Map<String, dynamic> data = jsonDecode(qrData);
              final sessionId = data['session_id'];

              // Show confirmation dialog with QR code data
              _showConfirmationDialog(sessionId, qrData);

              setState(() {
                lastScannedQrData = qrData; // Update last scanned QR data
              });
            } else {
              print('Invalid or expired QR Code');
            }
          }
        },
      ),
    );
  }
}
