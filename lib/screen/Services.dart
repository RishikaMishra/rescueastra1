import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_map_utils.dart' if (dart.library.html) '../utils/web_map_utils_web.dart';
import '../widgets/location_search_field.dart';
import '../widgets/hotspot_map_widget.dart';
import '../models/incident_model.dart';
import '../services/hotspot_analysis_service.dart';

// Google Maps API key with billing enabled and proper restrictions
const kGoogleApiKey = 'AIzaSyBQBDjcrBXZuT0WPRATX5lmNUPu20Rtiig';
final places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

void main() {
  // Initialize Google Maps for Web
  if (kIsWeb) {
    configureWebGoogleMaps();
  }
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
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => ServicesPageState();
}

class ServicesPageState extends State<ServicesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  final LatLng _currentLocation = LatLng(20.5937, 78.9629); // Default location (India)
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _distanceText = "";
  String _durationText = "";
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add marker for India location
    _markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'India'),
      ),
    );

    // Add a delay to ensure the map is properly loaded before manipulating it
    Future.delayed(Duration(milliseconds: 500), () {
      if (_controller != null) {
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 5.0));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationController.dispose();
    super.dispose();
  }







  // Calculate route between current location and destination
  void _calculateRoute() {
    if (_selectedLocation != null) {
      // Create a polyline between the two points
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: [_currentLocation, _selectedLocation!],
          color: Colors.blue,
          width: 5,
        ),
      );

      // Calculate approximate distance and duration
      _calculateDistanceAndDuration();
    }
  }

  // Calculate approximate distance and duration
  void _calculateDistanceAndDuration() {
    if (_selectedLocation != null) {
      // Calculate distance using the Haversine formula
      double distanceInMeters = _calculateDistance(
        _currentLocation.latitude,
        _currentLocation.longitude,
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

  // Fit map bounds to show all markers
  void _fitBounds() {
    if (_selectedLocation != null && _controller != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentLocation.latitude, _selectedLocation!.latitude),
          math.min(_currentLocation.longitude, _selectedLocation!.longitude),
        ),
        northeast: LatLng(
          math.max(_currentLocation.latitude, _selectedLocation!.latitude),
          math.max(_currentLocation.longitude, _selectedLocation!.longitude),
        ),
      );

      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }



  @override
  Widget build(BuildContext context) {
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
    return SafeArea(
      child: Column(
        children: [
          // Location search bar with auto-suggestions
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: LocationSearchField(
              apiKey: kGoogleApiKey,
              controller: _locationController,
              hint: 'Search locations in India',
              onLocationSelected: (LatLng position, String address) {
                setState(() {
                  _selectedLocation = position;
                  _markers.removeWhere((marker) => marker.markerId.value == 'selectedLocation');
                  _markers.add(
                    Marker(
                      markerId: MarkerId('selectedLocation'),
                      position: position,
                      infoWindow: InfoWindow(title: address),
                    ),
                  );
                  _calculateRoute();
                });

                // Move camera to show both markers
                _fitBounds();
              },
            ),
          ),

          // Map view
          Expanded(
            flex: 4, // Increased from 2 to 4 for better visualization
            child: AbsorbPointer(
              absorbing: false,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  setState(() {
                    _controller = controller;
                  });
                },
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 5.0, // Zoom out to show more of India
                  bearing: 0,
                  tilt: 0,
                ),
                onTap: (position) {
                  setState(() {
                    _selectedLocation = position;
                    _markers.removeWhere((marker) => marker.markerId.value == 'selectedLocation');
                    _markers.add(
                      Marker(
                        markerId: MarkerId('selectedLocation'),
                        position: position,
                        infoWindow: InfoWindow(title: 'Selected Location'),
                      ),
                    );
                    _calculateRoute();
                    _locationController.text = "Selected Location";
                  });
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: kIsWeb ? false : true, // Disable on web to avoid errors
                myLocationButtonEnabled: kIsWeb ? false : true, // Disable on web to avoid errors
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                compassEnabled: true,
                trafficEnabled: false,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: true,
              ),
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
          Expanded(
            flex: _selectedLocation != null ? 1 : 2, // Reduced to give more space to the map
            child: ListView(
              padding: EdgeInsets.all(16),
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

        // Hotspot map
        Expanded(
          child: HotspotMapWidget(
            initialLatitude: _currentLocation.latitude,
            initialLongitude: _currentLocation.longitude,
            onHotspotTapped: (hotspot) {
              _showHotspotInfo(hotspot);
            },
          ),
        ),

        // Legend
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Risk Levels',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Gender Ratio", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("70%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            Text("Women"),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [Text("12", style: TextStyle(fontWeight: FontWeight.bold)), Text("Women")]),
                Column(children: [Text("5", style: TextStyle(fontWeight: FontWeight.bold)), Text("Men")]),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCard() {
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
                gradient: LinearGradient(colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 8),
            Text("Moderate", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Based on time, location, demographics", textAlign: TextAlign.center),
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
                          _controller?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
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
