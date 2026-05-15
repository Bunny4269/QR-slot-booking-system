import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

const String baseUrl = "http://192.168.6.10:5000";

String loggedInEmail = "";
bool isAdmin = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget startScreen = const SplashScreen();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    bool logged = prefs.getBool("logged") ?? false;

    loggedInEmail = prefs.getString("email") ?? "";

    isAdmin =
        loggedInEmail ==
            "srikanthgangishetty5355@gmail.com";

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      startScreen =
      logged
          ? const HomeScreen()
          : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor:
        const Color(0xFF0F172A),
      ),

      home: startScreen,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/app_logo.jpeg",
              height: 130,
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  Future<void> login() async {
    if (emailController.text
        .trim()
        .isEmpty ||
        passwordController.text
            .trim()
            .isEmpty) {
      return;
    }

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool("logged", true);

    await prefs.setString(
      "email",
      emailController.text.trim(),
    );

    loggedInEmail =
        emailController.text.trim();

    isAdmin =
        loggedInEmail ==
            "srikanthgangishetty5355@gmail.com";

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const HomeScreen(),
      ),
    );
  }

  Widget field(
      TextEditingController controller,
      String hint,
      ) {
    return TextField(
      controller: controller,

      obscureText: hint == "Password",

      decoration: InputDecoration(
        hintText: hint,
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  "assets/app_logo.jpeg",
                  height: 120,
                ),

                const SizedBox(height: 20),

                const Text(
                  "QR Slot Booking",

                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                field(
                  emailController,
                  "Email",
                ),

                const SizedBox(height: 20),

                field(
                  passwordController,
                  "Password",
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: login,

                    child: const Text(
                      "LOGIN",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int index = 0;

  late List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens =
    isAdmin
        ? [
      const GeneratorScreen(),
      const BookingHistoryScreen(),
      const ScannerScreen(),
    ]
        : [
      const GeneratorScreen(),
      const BookingHistoryScreen(),
    ];
  }

  Future<void> logout() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> clearAllSlots() async {
    await http.post(
      Uri.parse("$baseUrl/clear"),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "All slots cleared",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin
              ? "Admin Panel"
              : "User Panel",
        ),

        actions: [

          if (isAdmin)
            IconButton(
              onPressed:
              clearAllSlots,

              icon: const Icon(
                Icons.delete,
              ),
            ),

          IconButton(
            onPressed: logout,

            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: screens[index],

      bottomNavigationBar:
      BottomNavigationBar(
        currentIndex: index,

        onTap: (value) {
          setState(() {
            index = value;
          });
        },

        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: "Generate",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),

          if (isAdmin)
            const BottomNavigationBarItem(
              icon:
              Icon(Icons.qr_code_scanner),
              label: "Verify",
            ),
        ],
      ),
    );
  }
}

class GeneratorScreen
    extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen>
  createState() =>
      _GeneratorScreenState();
}

class _GeneratorScreenState
    extends State<GeneratorScreen> {
  String qrData = "";

  final nameController =
  TextEditingController();

  Set<String> bookedSlots = {};
  Set<String> verifiedSlots = {};
  Set<String> selectedSlots = {};

  @override
  void initState() {
    super.initState();
    loadSlots();
  }

  Future<void> loadSlots() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/slots"),
      );

      final data =
      jsonDecode(response.body);

      bookedSlots =
      Set<String>.from(
        data["booked_slots"],
      );

      verifiedSlots =
      Set<String>.from(
        data["verified_slots"],
      );

      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Color getColor(String slot) {
    if (verifiedSlots.contains(slot)) {
      return Colors.green;
    }

    if (bookedSlots.contains(slot)) {
      return Colors.grey;
    }

    if (selectedSlots.contains(slot)) {
      return Colors.blue;
    }

    return Colors.white;
  }

  Future<void> generateQR() async {
    if (nameController.text.isEmpty ||
        selectedSlots.isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/book"),

      headers: {
        "Content-Type":
        "application/json",
      },

      body: jsonEncode({
        "name":
        nameController.text,

        "slots":
        selectedSlots.toList(),
      }),
    );

    final responseData =
    jsonDecode(response.body);

    if (!responseData["success"]) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            responseData["message"],
          ),
        ),
      );

      return;
    }

    final payload = {
      "name": nameController.text,
      "slots":
      selectedSlots.toList(),
    };

    qrData = jsonEncode(payload);

    final prefs =
    await SharedPreferences.getInstance();

    List<String> history =
        prefs.getStringList(
          "history",
        ) ??
            [];

    history.add(qrData);

    await prefs.setStringList(
      "history",
      history,
    );

    await loadSlots();

    setState(() {});
  }

  Widget buildLegend() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceEvenly,

      children: [

        buildLegendItem(
          Colors.white,
          "Available",
          Colors.black,
        ),

        buildLegendItem(
          Colors.blue,
          "Selected",
          Colors.white,
        ),

        buildLegendItem(
          Colors.grey,
          "Booked",
          Colors.white,
        ),

        buildLegendItem(
          Colors.green,
          "Verified",
          Colors.white,
        ),
      ],
    );
  }

  Widget buildLegendItem(
      Color color,
      String text,
      Color textColor,
      ) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,

          color: color,
        ),

        const SizedBox(width: 5),

        Text(
          text,

          style: TextStyle(
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      shrinkWrap: true,

      physics:
      const NeverScrollableScrollPhysics(),

      itemCount: 81,

      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),

      itemBuilder:
          (context, index) {
        int row = index ~/ 9;
        int col = index % 9;

        String slot =
            "R${row + 1}C${col + 1}";

        return GestureDetector(
          onTap: () {
            if (bookedSlots.contains(
                slot) ||
                verifiedSlots.contains(
                    slot)) {
              return;
            }

            setState(() {
              if (selectedSlots
                  .contains(slot)) {
                selectedSlots
                    .remove(slot);
              } else {
                selectedSlots
                    .add(slot);
              }
            });
          },

          child: Container(
            margin:
            const EdgeInsets.all(1),

            color: getColor(slot),

            child: Center(
              child: Text(
                "${row + 1}-${col + 1}",

                style: TextStyle(
                  fontSize: 8,

                  color:
                  getColor(slot) ==
                      Colors.white
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (qrData.isNotEmpty) {

      final decoded =
      jsonDecode(qrData);

      return SingleChildScrollView(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          children: [

            const Text(
              "BOOKING CONFIRMED",

              style: TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            QrImageView(
              data: qrData,
              size: 250,
              backgroundColor:
              Colors.white,
            ),

            const SizedBox(height: 20),

            Text(
              decoded["name"],

              style: const TextStyle(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,

              children:
              (decoded["slots"]
              as List)
                  .map(
                    (e) => Chip(
                  label:
                  Text(
                    e.toString(),
                  ),
                ),
              )
                  .toList(),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  qrData = "";
                  selectedSlots
                      .clear();
                });

                loadSlots();
              },

              child: const Text(
                "NEW BOOKING",
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(20),

      child: Column(
        children: [

          TextField(
            controller:
            nameController,

            decoration:
            const InputDecoration(
              hintText:
              "Enter Name",
            ),
          ),

          const SizedBox(height: 20),

          buildLegend(),

          const SizedBox(height: 20),

          buildGrid(),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,

            child: ElevatedButton(
              onPressed: generateQR,

              child: const Text(
                "Generate QR",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingHistoryScreen
    extends StatefulWidget {
  const BookingHistoryScreen({
    super.key,
  });

  @override
  State<BookingHistoryScreen>
  createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState
    extends State<
        BookingHistoryScreen> {

  List<String> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs =
    await SharedPreferences.getInstance();

    history =
        prefs.getStringList(
          "history",
        ) ??
            [];

    setState(() {});
  }

  Future<void> clearHistory() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove("history");

    history.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (history.isEmpty) {
      return const Center(
        child: Text(
          "No Booking History",
        ),
      );
    }

    return Column(
      children: [

        Padding(
          padding:
          const EdgeInsets.all(15),

          child: SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed:
              clearHistory,

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),

              child: const Text(
                "CLEAR HISTORY",
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding:
            const EdgeInsets.all(20),

            itemCount: history.length,

            itemBuilder:
                (context, index) {

              final data =
              jsonDecode(
                history[index],
              );

              return Card(
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                      20),

                  child: Column(
                    children: [

                      Text(
                        data["name"],

                        style:
                        const TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      QrImageView(
                        data:
                        history[index],

                        size: 180,

                        backgroundColor:
                        Colors.white,
                      ),

                      const SizedBox(
                          height: 20),

                      Wrap(
                        spacing: 10,

                        children:
                        (data["slots"]
                        as List)
                            .map(
                              (e) => Chip(
                            label:
                            Text(
                              e.toString(),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScannerScreen
    extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen>
  createState() =>
      _ScannerScreenState();
}

class _ScannerScreenState
    extends State<ScannerScreen> {

  String name = "";

  List slots = [];

  bool scanned = false;

  Future<void> verifySlots() async {

    if (slots.isEmpty) {
      return;
    }

    await http.post(
      Uri.parse("$baseUrl/verify"),

      headers: {
        "Content-Type":
        "application/json",
      },

      body: jsonEncode({
        "slots": slots,
      }),
    );

    setState(() {
      scanned = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Slots Verified",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        MobileScanner(
          onDetect: (capture) {

            if (scanned) return;

            try {

              final raw =
                  capture
                      .barcodes
                      .first
                      .rawValue;

              if (raw == null) return;

              final data =
              jsonDecode(raw);

              setState(() {
                name = data["name"];
                slots = data["slots"];
              });

            } catch (_) {}
          },
        ),

        Positioned(
          bottom: 20,
          left: 20,
          right: 20,

          child: Column(
            children: [

              if (name.isNotEmpty)

                Container(
                  width: double.infinity,

                  padding:
                  const EdgeInsets.all(
                      20),

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.black87,

                    borderRadius:
                    BorderRadius.circular(
                        20),
                  ),

                  child: Column(
                    children: [

                      Text(
                        name,

                        style:
                        const TextStyle(
                          fontSize: 24,
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      Wrap(
                        spacing: 10,

                        children:
                        slots
                            .map(
                              (e) => Chip(
                            label:
                            Text(
                              e.toString(),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(
                  onPressed:
                  verifySlots,

                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.green,
                  ),

                  child: const Text(
                    "VERIFY BOOKED SLOTS",
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      scanned = false;
                      name = "";
                      slots = [];
                    });
                  },

                  child: const Text(
                    "SCAN NEXT QR",
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}