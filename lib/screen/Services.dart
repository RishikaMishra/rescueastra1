import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_map_utils.dart' if (dart.library.html) '../utils/web_map_utils_web.dart';
import '../widgets/location_search_field.dart';
import '../widgets/hotspot_map_widget.dart';
import '../models/incident_model.dart';
import '../services/hotspot_analysis_service.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:pie_chart/pie_chart.dart';
import '../utils/demo_data_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueAstra',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: ServicesPage(),
    );
  }
}

class ServicesPage extends StatefulWidget {
  final int initialTab;
  const ServicesPage({super.key, this.initialTab = 0});

  @override
  State<ServicesPage> createState() => ServicesPageState();
}

class ServicesPageState extends State<ServicesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  latlng.LatLng? _selectedLocation;
  latlng.LatLng? _currentLocation; // Make this nullable and dynamic
  final List<latlng.LatLng> _polylinePoints = [];
  final List<fm.Marker> _markers = [];
  String _distanceText = "";
  String _durationText = "";
  final TextEditingController _locationController = TextEditingController();
  List<IncidentModel> _searchedIncidents = [];
  bool _isRouteLoading = false;
  String? _routeError;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() { _isLocating = true; });
    try {
      // Import geolocator at the top if not already
      // import 'package:geolocator/geolocator.dart';
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = latlng.LatLng(position.latitude, position.longitude);
        _markers.clear();
        _markers.add(
          fm.Marker(
            key: ValueKey('currentLocation'),
            point: _currentLocation!,
            child: Icon(Icons.my_location, color: Colors.blue, size: 40),
          ),
        );
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        // Fallback to India if location fails
        _currentLocation = latlng.LatLng(20.5937, 78.9629);
        _markers.clear();
        _markers.add(
          fm.Marker(
            key: ValueKey('currentLocation'),
            point: _currentLocation!,
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        );
        _isLocating = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Calculate route between current location and destination
  Future<void> _calculateRoute() async {
    if (_selectedLocation != null && _currentLocation != null) {
      setState(() {
        _isRouteLoading = true;
        _routeError = null;
      });
      try {
        final start = _currentLocation!;
        final end = _selectedLocation!;
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          _polylinePoints.clear();
          for (final c in coords) {
            _polylinePoints.add(latlng.LatLng(c[1], c[0]));
          }
          // Optionally, update _distanceText and _durationText from API
          final distance = data['routes'][0]['distance'] ?? 0.0;
          final duration = data['routes'][0]['duration'] ?? 0.0;
          setState(() {
            _distanceText = distance > 1000 ? "${(distance / 1000).toStringAsFixed(1)} km" : "${distance.round()} m";
            _durationText = duration > 3600 ? "${(duration / 3600).toStringAsFixed(1)} hours" : "${(duration / 60).round()} mins";
          });
        } else {
          setState(() {
            _routeError = 'Failed to fetch route (status ${response.statusCode})';
          });
        }
      } catch (e) {
        setState(() {
          _routeError = 'Error fetching route: $e';
        });
      } finally {
        setState(() {
          _isRouteLoading = false;
        });
      }
    }
  }

  // Calculate approximate distance and duration
  void _calculateDistanceAndDuration() {
    if (_selectedLocation != null) {
      // Calculate distance using the Haversine formula
      double distanceInMeters = _calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude
      );

      // Convert to kilometers
      double distanceInKm = distanceInMeters / 1000;

      // Estimate duration (assuming average speed of 50 km/h)
      double durationInHours = distanceInKm / 50;
      int durationInMinutes = (durationInHours * 60).round();

      setState(() {
        _distanceText = distanceInKm < 1
            ? "${(distanceInMeters).round()} m"
            : "${distanceInKm.toStringAsFixed(1)} km";

        _durationText = durationInMinutes < 60
            ? "$durationInMinutes mins"
            : "${(durationInHours).toStringAsFixed(1)} hours";
      });
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Convert degrees to radians
  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_routeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_routeError!)),
        );
        setState(() {
          _routeError = null;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Services'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Navigation'),
            Tab(icon: Icon(Icons.warning), text: 'Hotspots'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNavigationTab(),
          _buildHotspotsTab(),
        ],
      ),
    );
  }

  Widget _buildNavigationTab() {
    if (_isLocating || _currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Location search bar with auto-suggestions
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: LocationSearchField(
                controller: _locationController,
                hint: 'Search locations in India',
                onLocationSelected: (latlng.LatLng position, String address) async {
                  setState(() {
                    _selectedLocation = position;
                    _markers.removeWhere((marker) => marker.key == ValueKey('selectedLocation'));
                    _markers.add(
                      fm.Marker(
                        key: ValueKey('selectedLocation'),
                        point: position,
                        child: Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    );
                  });
                  await _calculateRoute();
                  // Fetch incidents near the searched location (2km radius)
                  final incidents = await HotspotAnalysisService().getIncidentsNearLocation(
                    position.latitude,
                    position.longitude,
                    2.0,
                  );
                  setState(() {
                    _searchedIncidents = incidents;
                  });
                },
              ),
            ),
            // Map view
            Container(
              height: 350,
              child: Stack(
                children: [
                  fm.FlutterMap(
                    options: fm.MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: 15.0,
                      onTap: (tapPosition, position) {
                        setState(() {
                          _selectedLocation = position;
                          _markers.removeWhere((marker) => marker.key == ValueKey('selectedLocation'));
                          _markers.add(
                            fm.Marker(
                              key: ValueKey('selectedLocation'),
                              point: position,
                              child: Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          );
                          _calculateRoute();
                          _locationController.text = "Selected Location";
                        });
                      },
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      fm.MarkerLayer(markers: _markers),
                      fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: _polylinePoints,
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isRouteLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),

            // Direction info panel
            if (_selectedLocation != null)
              Container(
                padding: EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Directions to: ${_locationController.text}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Distance: $_distanceText'),
                        SizedBox(width: 16),
                        Icon(Icons.access_time, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('ETA: $_durationText'),
                      ],
                    ),
                  ],
                ),
              ),

            // Safety information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildGenderCard()),
                      SizedBox(width: 16),
                      Expanded(child: _buildThreatCard()),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildRecentAlerts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotsTab() {
    return Column(
      children: [
        // Header with analysis controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Safety Hotspots Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Trigger hotspot analysis
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analyzing hotspots...')),
                      );
                      try {
                        await HotspotAnalysisService().analyzeAndUpdateHotspots();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hotspot analysis completed!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Analysis failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Identifying high-risk areas based on past incidents and alerts',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        // Legend with Delhi Safety Analysis button on the same row
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Risk Levels',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                    ),
                    icon: Icon(Icons.analytics),
                    label: Text('Delhi Safety Analysis'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.85,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (context, scrollController) => SingleChildScrollView(
                            controller: scrollController,
                            child: DelhiSafetyStats(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Critical', Colors.red),
                  _buildLegendItem('High', Colors.orange),
                  _buildLegendItem('Medium', Colors.yellow),
                  _buildLegendItem('Low', Colors.green),
                ],
              ),
            ],
          ),
        ),
        // Hotspot map
        Expanded(
          child: HotspotMapWidget(
            initialLatitude: _currentLocation?.latitude ?? 0.0,
            initialLongitude: _currentLocation?.longitude ?? 0.0,
            onHotspotTapped: (hotspot) {
              _showHotspotInfo(hotspot);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showHotspotInfo(HotspotModel hotspot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${hotspot.areaName ?? "Hotspot"} - ${hotspot.riskLevel.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incidents: ${hotspot.incidentCount}'),
            Text('Risk Score: ${(hotspot.riskScore * 100).toInt()}%'),
            Text('Radius: ${hotspot.radius.toInt()}m'),
            const SizedBox(height: 8),
            const Text('Incident Types:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...hotspot.incidentTypes.entries.map(
              (e) => Text('• ${e.key}: ${e.value}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard() {
    if (_searchedIncidents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No gender data for this location."),
        ),
      );
    }
    int women = 0;
    int men = 0;
    for (final incident in _searchedIncidents) {
      // Example: check tags or fields for gender info
      if (incident.tags != null && incident.tags!.contains('women')) women++;
      if (incident.tags != null && incident.tags!.contains('men')) men++;
    }
    int total = women + men;
    String percent = total > 0 ? "${((women / total) * 100).toStringAsFixed(0)}%" : "-";
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Gender Ratio", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(percent, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            Text("Women"),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [Text("$women", style: TextStyle(fontWeight: FontWeight.bold)), Text("Women")]),
                Column(children: [Text("$men", style: TextStyle(fontWeight: FontWeight.bold)), Text("Men")]),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCard() {
    if (_searchedIncidents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No threat data for this location."),
        ),
      );
    }
    // Aggregate threat level (use highest severity or weighted average)
    final severityOrder = {'low': 1, 'medium': 2, 'high': 3, 'critical': 4};
    int maxSeverity = 0;
    for (final incident in _searchedIncidents) {
      maxSeverity = incident.severity != null && severityOrder[incident.severity] != null
        ? (severityOrder[incident.severity]! > maxSeverity ? severityOrder[incident.severity]! : maxSeverity)
        : maxSeverity;
    }
    String threatLabel = "Unknown";
    Color threatColor = Colors.grey;
    switch (maxSeverity) {
      case 4:
        threatLabel = "Critical";
        threatColor = Colors.red;
        break;
      case 3:
        threatLabel = "High";
        threatColor = Colors.orange;
        break;
      case 2:
        threatLabel = "Medium";
        threatColor = Colors.yellow;
        break;
      case 1:
        threatLabel = "Low";
        threatColor = Colors.green;
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Threat Level", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: threatColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 8),
            Text(threatLabel, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Based on incidents in this area", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    List<Map<String, String>> alerts = [
      {"title": "High Risk Area Detected", "desc": "Multiple incidents reported", "time": "01:57 PM"},
      {"title": "Suspicious Activity", "desc": "Reported by users", "time": "12:57 PM"},
    ];

    if (alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No risks detected on this route."),
        ),
      );
    }

    return Column(
      children: alerts.map((alert) {
        return Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: Colors.deepPurple),
            title: Text(alert["title"]!, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert["desc"]!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("4/24/2025, ${alert["time"]!}"),
                    GestureDetector(
                      onTap: () {
                        if (_selectedLocation != null) {
                          // Placeholder for the removed _controller
                        }
                      },
                      child: Text("View on map", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DelhiSafetyStats extends StatefulWidget {
  @override
  _DelhiSafetyStatsState createState() => _DelhiSafetyStatsState();
}

class _DelhiSafetyStatsState extends State<DelhiSafetyStats> {
  int totalIncidents = 0;
  int unsafeForWomen = 0;
  Map<String, int> genderCounts = {};
  double threatDetectionRate = 0.0;
  List<IncidentModel> unsafeForWomenList = [];
  bool loading = false;
  String? errorMsg;
  bool analyzedOnce = false;

  Future<void> _generateDemoData() async {
    setState(() { loading = true; errorMsg = null; });
    try {
      await DemoDataGenerator.generateDemoEmergencyAlerts(
        count: 100,
        centerLat: 28.6139,
        centerLng: 77.2090,
        radiusKm: 10.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo data generated!')),
      );
      await _analyze();
    } catch (e) {
      setState(() { errorMsg = 'Failed to generate demo data: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _analyze() async {
    setState(() { loading = true; errorMsg = null; });
    try {
      final incidents = await HotspotAnalysisService().getIncidentsNearLocation(
        28.6139, 77.2090, 2.0,
      );
      print('Fetched incidents: \\${incidents.length}');
      final unsafe = incidents.where((i) =>
        i.gender == 'female' &&
        (i.incidentType == 'harassment' ||
         i.incidentType == 'assault' ||
         i.incidentType == 'stalking')
      ).toList();
      final genderMap = <String, int>{};
      for (var i in incidents) {
        if (i.gender != null) {
          genderMap[i.gender!] = (genderMap[i.gender!] ?? 0) + 1;
        }
      }
      final threatIncidents = incidents.where((i) => i.detectedThreats != null && i.detectedThreats!.isNotEmpty).length;
      setState(() {
        totalIncidents = incidents.length;
        unsafeForWomen = unsafe.length;
        genderCounts = genderMap;
        threatDetectionRate = incidents.isNotEmpty ? (threatIncidents / incidents.length) : 0.0;
        unsafeForWomenList = unsafe;
        analyzedOnce = true;
      });
    } catch (e) {
      setState(() { errorMsg = 'Failed to fetch or analyze data: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delhi Women Safety Analysis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : _generateDemoData,
              icon: Icon(Icons.data_usage),
              label: Text('Generate Demo Data for Delhi'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            SizedBox(height: 16),
            if (loading) Center(child: CircularProgressIndicator()),
            if (errorMsg != null) ...[
              SizedBox(height: 12),
              Text(errorMsg!, style: TextStyle(color: Colors.red)),
            ],
            if (!loading && errorMsg == null) ...[
              if (analyzedOnce && totalIncidents == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No data found for Delhi. Please generate demo data or check your connection.', style: TextStyle(color: Colors.orange, fontSize: 16)),
                ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Incidents: $totalIncidents', style: TextStyle(fontSize: 16)),
                      Text('Unsafe for Women: $unsafeForWomen', style: TextStyle(fontSize: 16, color: Colors.red)),
                      SizedBox(height: 10),
                      Text('Gender Ratio:', style: TextStyle(fontWeight: FontWeight.bold)),
                      genderCounts.isNotEmpty
                        ? PieChart(
                            dataMap: genderCounts.map((k, v) => MapEntry(k, v.toDouble())),
                            chartType: ChartType.ring,
                            chartRadius: 100,
                            legendOptions: const LegendOptions(showLegends: true),
                          )
                        : Text('No gender data'),
                      SizedBox(height: 10),
                      Text('Threat Detection Rate:', style: TextStyle(fontWeight: FontWeight.bold)),
                      LinearProgressIndicator(
                        value: threatDetectionRate,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        color: Colors.red,
                      ),
                      SizedBox(height: 4),
                      Text('${(threatDetectionRate * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text('Unsafe-for-Women Incidents in Delhi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              unsafeForWomenList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: unsafeForWomenList.length,
                    itemBuilder: (context, index) {
                      final incident = unsafeForWomenList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(Icons.warning, color: Colors.red),
                          title: Text('${incident.incidentType} at ${incident.address ?? 'Unknown'}'),
                          subtitle: Text(incident.description ?? ''),
                          trailing: Text(incident.severity, style: TextStyle(color: Colors.deepPurple)),
                        ),
                      );
                    },
                  )
                : Text('No unsafe-for-women incidents found.'),
            ],
          ],
        ),
      ),
    );
  }
}
