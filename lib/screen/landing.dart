import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'profile.dart';
import 'Services.dart';
import 'contacts.dart';
import 'emergency.dart';
import '../widgets/global_sos_overlay.dart';
import '../widgets/sakhi_chatbot.dart';

void main() {
  runApp(WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueAstra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  int _selectedIndex = 0;

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomePage(),
    ServicesPage(),
    TrustedContactsPage(),
    EmergencyPage(),
    RescueAstraApp(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlobalSOSOverlay(
      showSettingsButton: true,
      sosButtonMargin: EdgeInsets.only(bottom: 80, right: 16), // Just above taskbar
      sosButtonSize: 60,
      child: Scaffold(
        body: Stack(
          children: [
            _pages[_selectedIndex],
            // Sakhi Chatbot Button
            Positioned(
              bottom: 30,
              left: 16,
              child: FloatingActionButton(
                onPressed: () => _showSakhiChatbot(context),
                backgroundColor:  const Color(0xFFA82B66),
                heroTag: "sakhi_chat",
                tooltip: 'Chat with Sakhi',
                child: Icon(Icons.chat, color: Colors.white),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTap,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.safety_check), label: 'Services'),
            BottomNavigationBarItem(icon: Icon(Icons.contact_emergency), label: 'Contacts'),
            BottomNavigationBarItem(icon: Icon(Icons.emergency), label: 'Emergency'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _showSakhiChatbot(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SakhiChatbot(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RescueAstra", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: LandingContent(onSakhiTap: () => _showSakhiChatbot(context)),
    );
  }

  void _showSakhiChatbot(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SakhiChatbot(),
        );
      },
    );
  }
}

class LandingContent extends StatelessWidget {
  final VoidCallback? onSakhiTap;
  const LandingContent({super.key, this.onSakhiTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroSection(),
          SizedBox(height: 20),
          _featureGrid(context),
          SizedBox(height: 20),
          _chartSection(),
        ],
      ),
    );
  }

  Widget _heroSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFA82B66),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Protecting Women from Safety Threats",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            "Welcome to RescueAstra — A smart and secure platform that uses real-time monitoring to detect potential threats, analyze safety trends, and ensure you're never alone. With our intelligent alerts and city-wide insights, we're here to empower and protect every woman, every moment.",style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final features = [
      ["Gender Detection", Icons.person],
      ["Emergency services locator", Icons.emergency],
      ["Sakhi Assistant", Icons.chat],
      ["SOS Gesture", Icons.warning],
      ["Hotspot Areas", Icons.map],
      ["Live Monitoring", Icons.videocam],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:  const Color(0xFFA82B66))),
        SizedBox(height: 10),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: features
              .map((f) => GestureDetector(
            onTap: () {
              if (f[0] == "Sakhi Assistant" && onSakhiTap != null) {
                onSakhiTap!();
              }
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(f[1] as IconData, size: 40, color: const Color(0xFFA82B66)),
                    SizedBox(height: 10),
                    Text(f[0] as String, textAlign: TextAlign.center),
                    if (f[0] == "Sakhi Assistant")
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "Tap to chat",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.deepPurple[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _chartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Analytics & Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:  const Color(0xFFA82B66))),
        SizedBox(height: 20),
        Text("👥 Gender Distribution", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
        SizedBox(height: 200, child: _genderPieChart()),
        SizedBox(height: 20),
        Text("📅 Incidents by Time", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
        SizedBox(height: 200, child: _incidentBarChart()),
      ],
    );
  }

  Widget _genderPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.deepPurple,
            value: 60,
            title: 'Women\n60%',
            radius: 60,
            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.deepPurple[100],
            value: 40,
            title: 'Men\n40%',
            radius: 60,
            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
        sectionsSpace: 4,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _incidentBarChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['12AM', '6AM', '12PM', '6PM', '12AM'];
                return Text(labels[value.toInt()], style: TextStyle(fontSize: 12));
              },
              interval: 1,
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: Colors.deepPurple)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: Colors.deepPurple)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: Colors.deepPurple)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 7, color: Colors.deepPurple)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4, color: Colors.deepPurple)]),
        ],
      ),
    );
  }
}
