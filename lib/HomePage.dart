import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_generator/addUser.dart';
import 'package:qr_code_generator/attManagement.dart';
import 'package:qr_code_generator/attRequestPage.dart';
import 'package:qr_code_generator/fingerprint.dart';
import 'addSession.dart';
import 'scan_code_page.dart';
import 'qrGenerator.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance System'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0575E6), // RGB(5, 117, 230)
                    Color(0xFF021B79), // RGB(2, 27, 121)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRCodeGeneratorScreen(),
                  ),
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.qr_code_scanner),
            //   title: const Text('Scan QR'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const FingerprintAuth(),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddUserPage (),
                  ),
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.people),
            //   title: const Text('AttendanceRequest'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AttendanceRequestPage (),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('AttendanceManagement'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceManagementPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('Add new Session'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SessionManager(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: AttendanceList(),
    );
  }
}

class AttendanceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user email from Firebase Authentication
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userEmail = currentUser?.email;

    // If there's no logged-in user, return an error message
    if (userEmail == null) {
      return const Center(child: Text('No user logged in.'));
    }

    // Query Firestore to fetch records only for the logged-in user's email
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentMail', isEqualTo: userEmail) // Query filter
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No attendance records found.'));
        }

        // Prepare the data for the table
        List<DataRow> rows = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return DataRow(
            cells: [
              DataCell(Text(
                data['sessionId'] ?? '',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(Text(
                data['studentMail'] ?? '',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(const Text(
                'Present',
                style: TextStyle(fontSize: 12),
              )), // Assuming all records are 'Present'
              DataCell(Text(
                DateTime.parse(data['scanTime'])
                    .toLocal()
                    .toString()
                    .split(' ')[0],
                style: const TextStyle(fontSize: 12),
              )), // Extract the day from scanTime
            ],
          );
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10.0, // Reduce the spacing between columns
            columns: const [
              DataColumn(
                label: Text(
                  'Session ID',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Student ID (Email)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Attendance',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Day',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            rows: rows,
          ),
        );
      },
    );
  }
}
