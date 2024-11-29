import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async'; // Import the dart:async library for Timer
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

// Function to generate a unique token
String generateToken() {
  final random = Random();
  final bytes = List<int>.generate(10, (index) => random.nextInt(256));
  return base64Url.encode(bytes);
}

// Function to generate the QR code data
String generateQRCodeContent(String sessionId, DateTime timestamp) {
  final token = generateToken();
  return jsonEncode({
    'session_id': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'token': token,
    'token': token,
  });
}

// Function to update the active session in Firestore
Future<void> updateActiveSession(String sessionId) async {
  try {
    CollectionReference activeSessions = FirebaseFirestore.instance.collection('Active_Session');

    // Update active session ID
    await activeSessions.doc('activeSessionId').set({'sessionId': sessionId});
    print('Active session updated with sessionId: $sessionId');
  } catch (e) {
    print('Error updating active session: $e');
  }
}

// Function to get the next available session from Firestore and update QR code
Future<String> getNextAvailableSessionAndUpdateQRCode(String day) async {
  try {
    // Fetch sessions for the given day from Firestore
    CollectionReference sessions = FirebaseFirestore.instance.collection('sessions');

    // Query Firestore for sessions of the given day
    QuerySnapshot querySnapshot = await sessions.where('day', isEqualTo: day).get();

    print('Number of sessions found for $day: ${querySnapshot.docs.length}');
    if (querySnapshot.docs.isNotEmpty) {
      // Get the current time
      DateTime now = DateTime.now();

      // Initialize variables to track the valid session
      String validSessionId = "";
      String qrData = "";

      // Loop through all sessions for the given day
      for (var doc in querySnapshot.docs) {
        DateTime startTime = (doc['startTime'] as Timestamp).toDate().toLocal();
        DateTime endTime = (doc['endTime'] as Timestamp).toDate().toLocal();

        print('Checking session with ID: ${doc['sessionId']}');
        print('Session Start Time: $startTime');
        print('Session End Time: $endTime');
        print('Current Time: $now');

        // Check if the current time is within the session's time range
        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          validSessionId = doc['sessionId'];

          // Generate QR code content for the valid session
          qrData = generateQRCodeContent(validSessionId, now);
          await doc.reference.update({'currentQRCode': qrData});

          // Update the active session in Firestore's Active_Session collection
          await updateActiveSession(validSessionId);

          print('Generated QR Data for session: $validSessionId');
          break; // Once a valid session is found, break out of the loop
        }
      }

      // Return the QR data if a valid session was found
      if (qrData.isNotEmpty) {
        return qrData;
      } else {
        print('No active sessions found within the current time.');
        return ""; // No active sessions match the current time
      }
    } else {
      print('No sessions available for $day.');
      return ""; // No sessions available for today
    }
  } catch (e) {
    print('Error fetching session: $e');
    return "";
  }
}

// Main QR Code Generator screen
class QRCodeGeneratorScreen extends StatefulWidget {
  const QRCodeGeneratorScreen({super.key});

  @override
  _QRCodeGeneratorScreenState createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  late String _qrData;
  late Timer _timer; // Declare a Timer variable

  @override
  void initState() {
    super.initState();
    _qrData = "";
    _fetchQRCode(); // Fetch the initial QR code
    _timer = Timer.periodic(const Duration(seconds:10 ), (timer) {
      _fetchQRCode(); // Fetch QR code every 10 seconds
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Fetch QR code data and update the state
  void _fetchQRCode() async {
    String today = DateFormat('EEEE').format(DateTime.now());
    print('Fetching QR code for day: $today');
    String qrData = await getNextAvailableSessionAndUpdateQRCode(today);

    setState(() {
      _qrData = qrData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
      ),
      body: Center(
        child: _qrData.isEmpty
            ? const Text("No active sessions available today.")
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Today's QR Code:"),
            const SizedBox(height: 20),
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
      ),
    );
  }
}
