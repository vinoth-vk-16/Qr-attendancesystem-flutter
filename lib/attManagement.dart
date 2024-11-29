import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Attendance Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              return ListTile(
                title: Text('Roll No: ${request['roll_no']}'),
                subtitle: Text('Status: ${request['status']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        // Accept attendance request and update the status
                        await FirebaseFirestore.instance
                            .collection('attendance_requests')
                            .doc(request.id)
                            .update({'status': 'accepted'});

                        // Fetch the current active session ID
                        DocumentSnapshot activeSessionSnapshot = await FirebaseFirestore.instance
                            .collection('Active_Session')
                            .doc('activeSessionId') // Assuming the document ID is 'activeSessionId'
                            .get();

                        String sessionId = '';
                        if (activeSessionSnapshot.exists) {
                          sessionId = activeSessionSnapshot['sessionId']; // Get the sessionId field
                        }

                        // Get the student email using roll number
                        var userSnapshot = await FirebaseFirestore.instance
                            .collection('User_Info')
                            .where('roll_no', isEqualTo: request['roll_no'])
                            .limit(1)
                            .get();

                        String studentEmail = '';
                        if (userSnapshot.docs.isNotEmpty) {
                          studentEmail = userSnapshot.docs.first['email']; // Get the student's email
                        }

                        // Get the current time as a string
                        String scanTime = DateTime.now().toString(); // Convert DateTime to String

                        // Log to attendance collection, adding 'scanTime' as String
                        await FirebaseFirestore.instance.collection('attendance').add({
                          'sessionId': sessionId, // Storing the session ID
                          'studentMail': studentEmail, // Storing the student email
                          'scanTime': scanTime, // Add scanTime as String
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        // Decline attendance request
                        await FirebaseFirestore.instance
                            .collection('attendance_requests')
                            .doc(request.id)
                            .update({'status': 'declined'});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
