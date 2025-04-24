import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_park_assist/car_animation_page.dart';
import 'package:http/http.dart' as http;
import 'package:smart_park_assist/signin.dart'; // Correct import for SignInPage
import 'package:shared_preferences/shared_preferences.dart'; // For storing email

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color myColor;
  late Size mediaSize;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool rememberUser = false;
  bool isPasswordVisible = false;
  bool isLoading = false; // Variable to track loading state

  Future<void> login(String email, String password) async {
    setState(() {
      isLoading = true; // Show loading spinner when login starts
    });

    try {
      final jsonResponse = await http.post(
        Uri.parse(
          "http://35.244.43.79:8080/login/user",
        ),
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (jsonResponse.statusCode == 200) {
        String userEmail =
            jsonResponse.body; // Directly use the response string

        // Store the email in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', userEmail);

        if (!mounted) return; // Ensure widget is still part of the tree
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CarAnimationPage()),
        );
      } else {
        // If login fails, display the error message in SnackBar
        String errorMessage = jsonResponse.body;
        if (!mounted) return; // Ensure widget is still part of the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return; // Ensure widget is still part of the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      setState(() {
        isLoading =
            false; // Hide loading spinner after the login process completes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    myColor = Colors.blue.shade800;
    mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: mediaSize.width,
        height: mediaSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              myColor,
              Colors.white.withOpacity(0.5),
              const Color.fromARGB(255, 231, 123, 250).withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: const AssetImage('images/parkinggg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.3), BlendMode.dstATop),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned(top: 35, child: _buildTop()),
              Positioned(bottom: 0, child: _buildBottom()),
              if (isLoading)
                _buildLoadingSpinner(), // Show loading spinner if isLoading is true
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
            Colors.blue), // Customize the color of the spinner
      ),
    );
  }

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_sharp,
            size: 100,
            color: Colors.white,
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Colors.black, // Start with black for maximum contrast
                Colors.blueAccent, // Vibrant blue
                Colors.purple, // Deep purple for gradient effect
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              "GO PARK",
              style: TextStyle(
                color: Colors.white, // Placeholder for ShaderMask
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [myColor, Colors.purple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "Welcome",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Placeholder color for ShaderMask
            ),
          ),
        ),
        _buildGreyText("Please enter your information"),
        const SizedBox(height: 60),
        _buildGreyText("Email address"),
        _buildInputField(emailcontroller),
        const SizedBox(height: 40),
        _buildGreyText("Password"),
        _buildInputField(passwordcontroller, isPassword: true),
        const SizedBox(height: 20),
        _buildRememberForgot(),
        const SizedBox(height: 20),
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildSignInButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 61, 57, 57),
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : const Icon(Icons.done),
      ),
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberUser,
              onChanged: (value) {
                setState(() {
                  rememberUser = value!;
                });
              },
            ),
            _buildGreyText("Remember me"),
          ],
        ),
        TextButton(
          onPressed: () {
            // Handle forgot password logic here
          },
          child: _buildGreyText("Forgot my password"),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        login(emailcontroller.text, passwordcontroller.text);
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 10,
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.white,
      ),
      child: const Text(
        "LOGIN",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignInPage(),
            ),
          );
        },
        child: const Text(
          "Sign In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                color: Colors.grey,
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
