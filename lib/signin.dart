import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async'; // Required for delay functionality
import 'login_page.dart'; // Import your existing login page
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // To track the loading state

  @override
  void initState() {
    super.initState();
  }

  // Function to create a user by sending data to the server
  Future<void> createuser(
      String name, String phone, String email, String password) async {
    setState(() {
      _isLoading = true; // Show the loading spinner when the request is made
    });

    try {
      final response = await http.post(
        Uri.parse(
            "http://35.244.43.79:8080/create/user"),
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "email": email,
          "password": password,
        }),
        headers: {
          'Content-Type': 'application/json', // Ensure content type is JSON
        },
      );

      setState(() {
        _isLoading =
            false; // Hide the loading spinner when response is received
      });

      if (response.statusCode == 200) {
        // Registration successful
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("🎉 Thank You!"),
            content: const Text("Your registration is successful."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        // If server responds with a non-200 status code
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error!"),
            content: const Text("Failed to create the user. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide the spinner in case of error
      });

      // Error handling if the request fails
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error!"),
          content: const Text("An error occurred. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _onSubmit() {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      // Show a message if any field is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("😅 Oops!"),
          content: const Text("Please fill all the required details."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // Call the createuser function if all fields are filled
      createuser(
        _nameController.text,
        _phoneController.text,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE1BEE7),
                  Color(0xFF00BCD4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Spinner
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    // Welcome Text with Gradient Effect
                    if (!_isLoading)
                      ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            colors: [Colors.purple, Colors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect);
                        },
                        child: const Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (!_isLoading) const SizedBox(height: 5),
                    if (!_isLoading)
                      ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            colors: [Colors.purple, Colors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect);
                        },
                        child: const Text(
                          'Smart Car Assist',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                    if (!_isLoading)
                      Image.asset(
                        'images/bhushan.png',
                        height: 250,
                        width: 250,
                      ),
                    const SizedBox(height: 20),
                    if (!_isLoading)
                      _buildTextField(
                        controller: _nameController,
                        label: "Full Name",
                      ),
                    const SizedBox(height: 27),
                    if (!_isLoading)
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        keyboardType: TextInputType.phone,
                      ),
                    const SizedBox(height: 27),
                    if (!_isLoading)
                      _buildTextField(
                        controller: _emailController,
                        label: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                      ),
                    const SizedBox(height: 27),
                    if (!_isLoading)
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        obscureText: true,
                      ),
                    const SizedBox(height: 27),
                    if (!_isLoading)
                      GestureDetector(
                        onTap: _onSubmit,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(239, 240, 241, 1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(8, 0, 0, 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
