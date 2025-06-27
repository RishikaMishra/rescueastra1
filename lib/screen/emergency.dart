import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EmergencyPage(),
  ));
}

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  // Function to make a direct call
  void _makeCall(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Handle error silently or show user-friendly message
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> helplineNumbers = [
      {"name": "National Domestic Violence Hotline", "number": "1800 799 7233"},
      {"name": "National Sexual Assault Hotline", "number": "800 656 4673"},
      {"name": "Women's Crisis Centre", "number": "888 555 1212"},
    ];

    List<Map<String, String>> emergencyServices = [
      {"name": "Women Helpline", "number": "1091"},
      {"name": "Police", "number": "100"},
      {"name": "Ambulance", "number": "102"},
      {"name": "Fire", "number": "101"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Handle back navigation
          },
        ),
        title: const Text(
          "Emergency Helplines",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Text(
              "For immediate assistance, please contact the following helplines:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 10),

            // Helpline Numbers List
            Expanded(
              child: ListView(
                children: [
                  ...helplineNumbers.map((helpline) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      title: Text(
                        helpline["name"]!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        helpline["number"]!,
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _makeCall(helpline["number"]!),
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),

                  // Emergency Services List
                  const Text(
                    "Emergency Services",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF75134A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...emergencyServices.map((service) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      title: Text(
                        service["name"]!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _makeCall(service["number"]!),
                        icon: const Icon(Icons.call),
                        label: Text(service["number"]!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA82B66),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
