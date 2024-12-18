import 'package:flutter/material.dart';
import 'paymentpage.dart';
import 'dart:convert';
import 'm_cli.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SlotInfoPage extends StatefulWidget {
  final int slotNumber;
  final bool isEmpty;

  const SlotInfoPage({
    Key? key,
    required this.slotNumber,
    required this.isEmpty,
  }) : super(key: key);

  @override
  _SlotInfoPageState createState() => _SlotInfoPageState();
}

class _SlotInfoPageState extends State<SlotInfoPage> {
  final MqttClientManager mqttClientManager = MqttClientManager();
  static Map<int, Map<String, dynamic>> slotDataCache = {};

  String entryTime = 'Fetching...';
  String exitTime = 'Fetching...';
  String costText = '...';

  @override
  void initState() {
    super.initState();
    _loadSlotData();
    const uuid = Uuid();
    String clientId = uuid.v4();
    mqttClientManager.initilizeMqtt("app", clientId);
    onMessage(); // Handle incoming MQTT messages
  }

  // Load data from cache if it exists
  Future<void> _loadSlotData() async {
    if (slotDataCache.containsKey(widget.slotNumber)) {
      final cachedData = slotDataCache[widget.slotNumber]!;
      setState(() {
        entryTime = cachedData['entryTime'];
        exitTime = cachedData['exitTime'];
        costText = cachedData['costText'];
      });
    }
  }

  void onMessage() {
    mqttClientManager.onMessageReceived = (String topic, String message) {
      if (topic == 'app') {
        try {
          print('Received message: $message');
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(jsonDecode(message));

          // Validate required fields
          if (data['mty'] == 3 && data['sid'] != null) {
            // Extract slot number from 'sid' (e.g., 's4' -> 4)
            final int slotNumber =
                int.tryParse(data['sid'].replaceAll(RegExp(r'\D'), '')) ?? -1;

            if (slotNumber > 0) {
              // Extract and process times and cost
              final String inTime = (data['itm'] ?? 'N/A').split(' +')[0];
              final String outTime = (data['otm'] ?? 'N/A').split(' +')[0];
              final int cost = data['cost'] is int
                  ? data['cost']
                  : int.tryParse(data['cost']?.toString() ?? '0') ?? 0;

              // Update the cache with the new data
              slotDataCache[slotNumber] = {
                'entryTime': inTime,
                'exitTime': outTime,
                'costText': '₹ $cost',
              };

              // If we are viewing the updated slot, refresh the UI
              if (mounted && slotNumber == widget.slotNumber) {
                setState(() {
                  entryTime = inTime;
                  exitTime = outTime;
                  costText = '₹ $cost';
                });
              }

              print('Slot $slotNumber updated in cache.');
            }
          }
        } catch (e) {
          print('Error parsing MQTT message: $e');
        }
      }
    };
  }

  Future<void> openGate() async {
    final prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail != null) {
      final requestData = jsonEncode({'email': userEmail});

      mqttClientManager.publishMessage(
        topic: 'smart/mqtt/processor/4',
        message: requestData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gate is opening...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE1BEE7),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopRectangle(screenWidth),
            const SizedBox(height: 60),
            _buildMainInfoContainer(screenWidth, screenHeight),
            const SizedBox(height: 50),
            _buildControlGateSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRectangle(double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 166, 57, 234),
            Color(0xFFAB47BC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isEmpty ? Icons.indeterminate_check_box : Icons.car_rental,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 10),
          Text(
            'Slot ${widget.slotNumber} - Status: ${widget.isEmpty ? 'Empty' : 'Booked'}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoContainer(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.5,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE1BEE7),
            Colors.cyan,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildSlotInfo(screenWidth),
      ),
    );
  }

  Widget _buildSlotInfo(double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoBox('Entry Time: $entryTime', screenWidth),
        _buildInfoBox('Exit Time: $exitTime', screenWidth),
        _buildInfoBox('Cost in Rupees: $costText', screenWidth),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            backgroundColor: const Color.fromARGB(255, 177, 65, 247),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Pay Here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, double screenWidth) {
    return Container(
      width: screenWidth * 0.8,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildControlGateSection(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 221, 83, 245),
            Color.fromARGB(255, 88, 230, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Control Gate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              openGate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
            child: const Text('Open Gate'),
          ),
        ],
      ),
    );
  }
}
