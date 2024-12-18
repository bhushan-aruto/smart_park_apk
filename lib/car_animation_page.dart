import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import for SharedPreferences
import 'slot_page.dart'; // Ensure you import SlotPage

class CarAnimationPage extends StatefulWidget {
  const CarAnimationPage({super.key});

  @override
  CarAnimationPageState createState() => CarAnimationPageState();
}

class CarAnimationPageState extends State<CarAnimationPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoFuture;
  String userEmail = ''; // Variable to store the email

  @override
  void initState() {
    super.initState();
    // Initialize the video controller and store the future to preload the video
    _controller = VideoPlayerController.asset('images/videos/newvideo.mp4');
    _initializeVideoFuture = _controller.initialize();
    _controller.setVolume(0); // Mute the video

    // Retrieve the email from SharedPreferences
    _getEmailFromSharedPreferences();

    // Set up a listener to navigate to SlotPage when the video ends
    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                SlotPage(userEmail: userEmail), // Pass the email dynamically
          ),
        );
      }
    });
  }

  // Method to retrieve email from SharedPreferences
  _getEmailFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ??
          ''; // Retrieve the email or use an empty string
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeVideoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Once the video is ready, start playing
            _controller.play();

            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  const Positioned(
                    top: 60, // Adjusted the position of "Welcome"
                    child: Text(
                      "Welcome",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.blueAccent,
                            offset: Offset(0, 0),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    child: Text(
                      "Smart Park Assist",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.blueAccent,
                            offset: Offset(0, 0),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Show a loading indicator until the video is ready
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
