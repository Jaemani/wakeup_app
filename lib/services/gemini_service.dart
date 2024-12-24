import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  // Endpoint for the Node.js API deployed on Google Cloud Platform
  final String apiEndpoint =
      'https://my-gcp-nodejs-app-1037534072794.asia-east1.run.app/hashApiKey'; // Replace with your Node.js server URL
  // Secure storage to store the API key on the device
  final storage = const FlutterSecureStorage();

  // Function to login with the Gemini API key using the Node.js backend
  Future<Map<String, dynamic>?> loginWithGeminiApiKey(String apiKey) async {
    try {
      // Send a POST request to the GCP Node.js server with the API key
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'apiKey': apiKey}),
      );

      // If the request is successful, check the status code
      if (response.statusCode == 200) {
        // Parse the response data
        final data = jsonDecode(response.body);

        if (data != null &&
            data['userId'] != null &&
            data['hashedApiKey'] != null) {
          // Store the API key securely in local storage
          await storage.write(key: 'apiKey', value: apiKey);

          // Return the userId and hashedApiKey for further processing
          return {
            'userId': data['userId'],
            'hashedApiKey': data['hashedApiKey']
          };
        } else {
          // If the response doesn't contain the necessary data
          print('Invalid response from server: ${response.body}');
          return null;
        }
      } else {
        // If the server returned an error (non-200 status code)
        print('Failed to log in: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      // Catch any errors that occur during the HTTP request
      print('Error during Gemini API login: $e');
      return null;
    }
  }

  // Function to check if the user is already logged in
  Future<bool> isLoggedIn() async {
    final apiKey = await storage.read(key: 'apiKey');
    return apiKey != null;
  }

  // Function to log out by clearing the stored API key
  Future<void> logout() async {
    await storage.delete(key: 'apiKey');
    print('User logged out.');
  }

  // Function to retrieve the stored API key (if needed)
  Future<String?> getStoredApiKey() async {
    return await storage.read(key: 'apiKey');
  }
}
