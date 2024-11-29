import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionManager extends StatefulWidget {
  @override
  _SessionManagerState createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedDay;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  String? sessionId;

  List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Convert TimeOfDay to DateTime for comparison
  DateTime convertToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // Function to check if session time conflicts with an existing one
  Future<bool> checkSessionConflict(String day, TimeOfDay start, TimeOfDay end) async {
    QuerySnapshot sessionsSnapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .where('day', isEqualTo: day)
        .get();

    for (var doc in sessionsSnapshot.docs) {
      DateTime existingStart = (doc['startTime'] as Timestamp).toDate();
      DateTime existingEnd = (doc['endTime'] as Timestamp).toDate();

      TimeOfDay existingStartTime = TimeOfDay.fromDateTime(existingStart);
      TimeOfDay existingEndTime = TimeOfDay.fromDateTime(existingEnd);

      DateTime newStartDateTime = convertToDateTime(start);
      DateTime newEndDateTime = convertToDateTime(end);
      DateTime existingStartDateTime = convertToDateTime(existingStartTime);
      DateTime existingEndDateTime = convertToDateTime(existingEndTime);

      // If new session overlaps with any existing session
      if (!(newEndDateTime.isBefore(existingStartDateTime) || newStartDateTime.isAfter(existingEndDateTime))) {
        return true;
      }
    }

    return false;
  }

  // Function to add a new session
  Future<void> addSession() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (selectedStartTime != null && selectedEndTime != null) {
        bool hasConflict = await checkSessionConflict(selectedDay!, selectedStartTime!, selectedEndTime!);

        if (hasConflict) {
          // Show conflict popup
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Conflict Detected'),
                content: const Text('The session time conflicts with an existing session.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ));
        } else {
          // Add session to Firestore
          FirebaseFirestore.instance.collection('sessions').add({
            'day': selectedDay,
            'startTime': Timestamp.fromDate(convertToDateTime(selectedStartTime!)),
            'endTime': Timestamp.fromDate(convertToDateTime(selectedEndTime!)),
            'sessionId': sessionId,
          });

          // Clear form after successful submission
          _formKey.currentState!.reset();
          setState(() {
            selectedDay = null;
            selectedStartTime = null;
            selectedEndTime = null;
            sessionId = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session added successfully')));
        }
      }
    }
  }

  // Function to delete a session
  Future<void> deleteSession(String docId) async {
    await FirebaseFirestore.instance.collection('sessions').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted successfully')));
  }

  // Helper functions for picking time
  Future<void> selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && picked != selectedStartTime) {
      setState(() {
        selectedStartTime = picked;
      });
    }
  }

  Future<void> selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && picked != selectedEndTime) {
      setState(() {
        selectedEndTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Session Manager'),
            centerTitle: true,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Day'),
                value: selectedDay,
                items: days.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDay = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a day';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Session ID'),
                onSaved: (value) {
                  sessionId = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter session ID';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Text('Start Time: ${selectedStartTime != null ? selectedStartTime!.format(context) : 'Not selected'}'),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => selectStartTime(context),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('End Time: ${selectedEndTime != null ? selectedEndTime!.format(context) : 'Not selected'}'),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => selectEndTime(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addSession,
                child: const Text('Add Session'),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .orderBy('startTime') // Order sessions by startTime
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final sessions = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        var session = sessions[index];
                        return ListTile(
                          title: Text(session['sessionId']),
                          subtitle: Text('${session['day']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteSession(session.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
