import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRequestPage extends StatelessWidget {
  final TextEditingController rollNoController = TextEditingController();

  // Function to fetch session ID from Active_Session collection
  Future<String?> fetchSessionId() async {
    try {
      DocumentSnapshot activeSessionSnapshot = await FirebaseFirestore.instance
          .collection('Active_Session')
          .doc('activeSessionId') // Assuming the document ID is 'activeSessionId'
          .get();

      if (activeSessionSnapshot.exists) {
        // Retrieve the sessionId field
        return activeSessionSnapshot.get('sessionId');
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching session ID: $e');
      return null;
    }
  }

  // Function to handle attendance request
  void requestAttendance(BuildContext context) async {
    String rollNo = rollNoController.text;

    // Fetch the session ID
    String? sessionId = await fetchSessionId();

    if (sessionId != null) {
      // Add the attendance request with the fetched session ID
      await FirebaseFirestore.instance.collection('attendance_requests').add({
        'roll_no': rollNo,
        'session_id': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Initialize status as 'pending'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance request sent for roll no $rollNo')),
      );

      rollNoController.clear(); // Clear the input field after submission
    } else {
      // If session ID is not found, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active session found!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: rollNoController,
              decoration: const InputDecoration(labelText: 'Enter Roll No'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => requestAttendance(context),
              child: const Text('Request Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
