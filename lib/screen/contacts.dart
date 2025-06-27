import 'package:flutter/material.dart';
import 'Addcontacts.dart'; // Make sure to import the AddContactPage

class TrustedContactsPage extends StatefulWidget {
  const TrustedContactsPage({super.key});

  @override
  TrustedContactsPageState createState() => TrustedContactsPageState();
}

class TrustedContactsPageState extends State<TrustedContactsPage> {
  List<Map<String, String>> contacts = [
    {"name": "Rahi", "number": "+91 8245612213"},
    {"name": "Alex", "number": "+91 4632532313"},
    {"name": "Rohit", "number": "+91 4656532313"},
    {"name": "Amitabh", "number": "+91 9556532313"},
    {"name": "Ashmita", "number": "+91 5656532313"},
  ];

  void _navigateToAddContact() async {
    final newContact = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddContactPage()),
    );

    if (newContact != null && newContact is Map<String, String>) {
      setState(() {
        contacts.add(newContact);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Trusted Contacts",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Text(
              "Here are the contact numbers of your trusted contacts:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA82B66),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToAddContact,
                child: const Text(
                  "Add Contact",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Contact person ${index + 1}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contacts[index]["name"]!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            contacts[index]["number"]!,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                      const Divider(
                          color: Colors.grey, thickness: 0.5, height: 20),
                    ],
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

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TrustedContactsPage(),
  ));
}