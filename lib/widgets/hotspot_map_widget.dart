import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_model.dart';
import '../services/hotspot_analysis_service.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;

class HotspotMapWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialZoom;
  final bool showUserLocation;
  final Function(HotspotModel)? onHotspotTapped;

  const HotspotMapWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom = 12.0,
    this.showUserLocation = true,
    this.onHotspotTapped,
  });

  @override
  State<HotspotMapWidget> createState() => _HotspotMapWidgetState();
}

class _HotspotMapWidgetState extends State<HotspotMapWidget> {
  Set<fm.Marker> _markers = {};
  Set<fm.CircleMarker> _circles = {};
  List<HotspotModel> _hotspots = [];
  Position? _currentPosition;
  bool _isLoading = true;
  String _selectedRiskLevel = 'all';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.showUserLocation) {
      await _getCurrentLocation();
    }
    await _loadHotspots();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadHotspots() async {
    try {
      final hotspotService = HotspotAnalysisService();
      final hotspots = await hotspotService.getAllHotspots();
      
      setState(() {
        _hotspots = hotspots;
        _updateMapMarkers();
      });
    } catch (e) {
      print('Error loading hotspots: $e');
    }
  }

  void _updateMapMarkers() {
    final markers = <fm.Marker>{};
    final circles = <fm.CircleMarker>{};

    // Filter hotspots based on selected risk level
    final filteredHotspots = _selectedRiskLevel == 'all'
        ? _hotspots
        : _hotspots.where((h) => h.riskLevel == _selectedRiskLevel).toList();

    for (final hotspot in filteredHotspots) {
      // Add marker for hotspot center
      markers.add(
        fm.Marker(
          point: latlng.LatLng(hotspot.centerLatitude, hotspot.centerLongitude),
          child: _getMarkerIcon(hotspot.riskLevel),
        ),
      );

      // Add circle to show hotspot area
      circles.add(
        fm.CircleMarker(
          point: latlng.LatLng(hotspot.centerLatitude, hotspot.centerLongitude),
          color: _getCircleColor(hotspot.riskLevel).withAlpha(128),
          radius: hotspot.radius,
        ),
      );
    }

    // Add user location marker if available
    if (_currentPosition != null && widget.showUserLocation) {
      markers.add(
        fm.Marker(
          point: latlng.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: _getUserLocationIcon(),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  Widget _getMarkerIcon(String riskLevel) {
    return Icon(Icons.location_on, color: _getCircleColor(riskLevel));
  }

  Widget _getUserLocationIcon() {
    return Icon(Icons.location_on, color: Colors.blue);
  }

  Color _getCircleColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  void _showHotspotDetails(HotspotModel hotspot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildHotspotDetailsSheet(hotspot),
    );
  }

  Widget _buildHotspotDetailsSheet(HotspotModel hotspot) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCircleColor(hotspot.riskLevel).withAlpha(128),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _getCircleColor(hotspot.riskLevel),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotspot.areaName ?? 'Hotspot Area',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${hotspot.riskLevel.toUpperCase()} RISK AREA',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCircleColor(hotspot.riskLevel),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Total Incidents', '${hotspot.incidentCount}'),
                  _buildDetailRow('Risk Score', '${(hotspot.riskScore * 100).toInt()}%'),
                  _buildDetailRow('Area Radius', '${hotspot.radius.toInt()}m'),
                  _buildDetailRow('Last Updated', _formatDate(hotspot.lastUpdated)),
                  
                  const SizedBox(height: 16),
                  // --- Enhanced Report Section ---
                  if (hotspot.detectedThreatsSummary != null && hotspot.detectedThreatsSummary!.isNotEmpty) ...[
                    const Text('Threats Detected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...hotspot.detectedThreatsSummary!.entries.map(
                      (entry) => _buildDetailRow(entry.key, '${entry.value}'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hotspot.genderDistribution != null && hotspot.genderDistribution!.isNotEmpty) ...[
                    const Text('Gender Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...hotspot.genderDistribution!.entries.map(
                      (entry) => _buildDetailRow(entry.key, '${entry.value}'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hotspot.featureSummary != null && hotspot.featureSummary!.isNotEmpty) ...[
                    const Text('Detected Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...hotspot.featureSummary!.entries.map(
                      (entry) => _buildDetailRow(entry.key, '${entry.value}'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // --- End Enhanced Report Section ---
                  const Text(
                    'Incident Types',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...hotspot.incidentTypes.entries.map(
                    (entry) => _buildDetailRow(entry.key, '${entry.value}'),
                  ),
                  
                  if (hotspot.commonTags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Common Patterns',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: hotspot.commonTags.map(
                        (tag) => Chip(
                          label: Text(tag.replaceAll('_', ' ')),
                          backgroundColor: Colors.grey[200],
                        ),
                      ).toList(),
                    ),
                  ],
                  
                  if (hotspot.timePatterns != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Time Patterns',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Peak Hour', '${hotspot.timePatterns!['peakHour']}:00'),
                    _buildDetailRow('Peak Day', _getDayName(hotspot.timePatterns!['peakDay'])),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final initialPosition = latlng.LatLng(
      widget.initialLatitude ?? _currentPosition?.latitude ?? 28.6139, // Delhi default
      widget.initialLongitude ?? _currentPosition?.longitude ?? 77.2090,
    );

    return Column(
      children: [
        // Filter controls
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Risk Level: '),
              DropdownButton<String>(
                value: _selectedRiskLevel,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRiskLevel = value!;
                    _updateMapMarkers();
                  });
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadHotspots,
              ),
            ],
          ),
        ),
        
        // Map
        Expanded(
          child: fm.FlutterMap(
            options: fm.MapOptions(
              initialCenter: initialPosition,
              initialZoom: widget.initialZoom,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              fm.MarkerLayer(markers: _markers.toList()),
              fm.CircleLayer(circles: _circles.toList()),
            ],
          ),
        ),
      ],
    );
  }
}
