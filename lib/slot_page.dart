import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http;
import 'slot_info.dart'; // Import SlotInfoPage
import 'm_cli.dart';
import 'package:uuid/uuid.dart'; // Import MQTT Client Manager

class SlotPage extends StatefulWidget {
  final String userEmail; // Email passed from LoginPage

  const SlotPage({super.key, required this.userEmail});

  @override
  State<SlotPage> createState() => _SlotPageState();
}

class _SlotPageState extends State<SlotPage> {
  final MqttClientManager mqttClientManager = MqttClientManager();
  List<int> slotStatuses = [
    0,
    0,
    0,
    0
  ]; // Real-time status: 0 -> Empty, 1 -> Full, 2 -> Booked
  List<String> imageUrls = [
    'images/neee.png',
    'images/neee.png',
    'images/neee.png',
    'images/neee.png',
  ];

  @override
  void initState() {
    super.initState();

    const uuid = Uuid();
    String clientId = uuid.v4();
    mqttClientManager.initilizeMqtt("app", clientId);
    onMessage();
  }

  void onMessage() {
    print("hello");
    mqttClientManager.onMessageReceived = (data, payload) {
      print("hiii");
      var jdata = jsonDecode(payload);
      setState(() {
        slotStatuses[0] = jdata["s1"];
        slotStatuses[1] = jdata["s2"];
        slotStatuses[2] = jdata["s3"];
        slotStatuses[3] = jdata["s4"];
      });
      print(payload);
    };
  }

  @override
  void dispose() {
    mqttClientManager.disconnect();
    super.dispose();
  }

  int getAvailableSlots() {
    return slotStatuses.where((status) => status == 0).length;
  }

  Future<bool> sendBookingRequest(
      String email, int arrivalTime, int slotIndex) async {
    print("Sending booking request...");
    final uri = Uri.parse(
        "https://smart-parking-system-http-server.onrender.com/user/book");
    final payload = {"email": email, "arrive_time": arrivalTime};

    try {
      print(payload);
      final response = await http.post(
        uri,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(response.body);
        return false;
      }
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  void showBookingConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Booking Confirmed"),
        content: const Text("Booking is successful. Thank you for booking."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _setArrivalTime(int index) async {
    if (slotStatuses[index] != 0) {
      showErrorDialog(
          slotStatuses[index] == 1 ? "This slot is full." : "Already booked.");
      return;
    }

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final currentSeconds = now.hour * 3600 + now.minute * 60 + now.second;
      final arrivalSeconds = pickedTime.hour * 3600 + pickedTime.minute * 60;
      final differenceInSeconds = arrivalSeconds - currentSeconds;

      if (differenceInSeconds <= 0) {
        showErrorDialog("Arrival time must be in the future.");
        return;
      }

      final success = await sendBookingRequest(
          widget.userEmail, differenceInSeconds, index);
      if (success) {
        setState(() {
          slotStatuses[index] = 2;
        });
        showBookingConfirmationDialog();
      } else {
        showErrorDialog("Failed to book slot. Please try again.");
      }
    }
  }

  void _navigateToSlotInfo(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlotInfoPage(
          slotNumber: index + 1, // Adjust the slot number (e.g., 1, 2, 3, etc.)
          isEmpty: slotStatuses[index] == 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double slotWidth = screenWidth * 0.5;
    double slotHeight = 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Available Slots: ${getAvailableSlots()} / 4',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Slot ${index + 1}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _navigateToSlotInfo(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: slotWidth,
                                height: slotHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: slotStatuses[index] != 0
                                        ? Colors.green
                                        : const Color(0xFF9E9E9E),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: slotStatuses[index] == 0
                                    ? const Text(
                                        'Empty',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Image.asset(
                                        imageUrls[index],
                                        fit: BoxFit.fitHeight,
                                        height: slotHeight * 0.85,
                                        alignment: Alignment.center,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            _setArrivalTime(index);
                          },
                          child: Container(
                            width: 120,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slotStatuses[index] == 0
                                  ? 'Book'
                                  : slotStatuses[index] == 1
                                      ? 'Full'
                                      : 'Booked',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
