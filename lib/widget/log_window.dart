import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wakeup/services/auth_service.dart';
import 'package:wakeup/services/gemini_service.dart';

class LogWindow extends StatefulWidget {
  final Function(String) onApiKeySubmitted;

  const LogWindow({Key? key, required this.onApiKeySubmitted})
      : super(key: key);

  @override
  LogWindowState createState() => LogWindowState();
}

class LogWindowState extends State<LogWindow> {
  final List<String> _logs = [];
  final TextEditingController _apiKeyController =
      TextEditingController(); // Controller for the input field
  bool isLoggedIn = false;
  final GeminiService geminiService = GeminiService();
  String? userId; // Variable to store the userId

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if the user is already logged in
  Future<void> _checkLoginStatus() async {
    bool loggedIn = await geminiService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  // Handle the submission of the API key
  Future<void> _submitApiKey() async {
    String apiKey = _apiKeyController.text;
    if (apiKey.isNotEmpty) {
      // Login using Cloud Function
      final result = await geminiService.loginWithGeminiApiKey(apiKey);
      if (result != null && result['success'] == true) {
        setState(() {
          isLoggedIn = true;
          userId = result['userId']; // Store userId for future use
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Logged in successfully!"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid API key, please try again."),
        ));
      }
    }
  }

  // Handle the logout action
  Future<void> _logout() async {
    await geminiService.logout();
    setState(() {
      isLoggedIn = false; // Reset login state
      userId = null; // Clear the userId
    });
  }

  void addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  // Function to detect drowsy warning and log it in Firestore
  void _onDrowsyWarningDetected(double closedEyeDuration) async {
    if (isLoggedIn && userId != null) {
      // Store logs in Firestore
      await FirebaseFirestore.instance
          .collection('WarnLogs')
          .doc(userId) // Use the stored userId
          .collection('Logs')
          .add({
        'duration': closedEyeDuration,
        'time': FieldValue.serverTimestamp(),
      });

      // Generate and store chat message (if any suggestion is generated)
      await FirebaseFirestore.instance
          .collection('ChatLogs')
          .doc(userId) // Use the stored userId
          .collection('Logs')
          .add({
        'message':
            "Take a break! You've been drowsy for too long.", // Example message
        'time': FieldValue.serverTimestamp(),
      });
    } else {
      // If the user is not logged in, show a warning notice
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "Warn logs might not be saved if you don't log in with Gemini API."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height, // Full screen
        color: Colors.grey[850], // Solid gray background theme
        child: Column(
          children: [
            AppBar(
              title: const Text(
                'Log Window',
                style: TextStyle(
                  color: Color.fromARGB(255, 209, 209, 209),
                ),
              ),
              backgroundColor: Colors.grey[900], // Darker gray app bar
            ),
            if (!isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _apiKeyController,
                  style: const TextStyle(
                    color: Colors.white, // White text when typing
                  ),
                  cursorColor: Colors.white, // White cursor
                  decoration: InputDecoration(
                    labelText: 'Enter Gemini API Key',
                    labelStyle: const TextStyle(
                        color: Colors.white70), // White label text
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed:
                          _submitApiKey, // Trigger login when API key is entered
                    ),
                  ),
                ),
              ),
            if (isLoggedIn)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout, // Log out the user
                ),
              ),
            ElevatedButton(
              onPressed: _submitApiKey,
              child: const Text('Submit API Key'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[700], // Gray card background
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _logs[index],
                        style:
                            const TextStyle(color: Colors.white), // White text
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
