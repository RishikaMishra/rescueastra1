import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_model.dart';

class HotspotAnalysisService {
  static final HotspotAnalysisService _instance = HotspotAnalysisService._internal();
  factory HotspotAnalysisService() => _instance;
  HotspotAnalysisService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Configuration parameters
  static const double CLUSTER_RADIUS = 500.0; // meters
  static const int MIN_INCIDENTS_FOR_HOTSPOT = 3;
  static const int ANALYSIS_PERIOD_DAYS = 90; // 3 months
  static const double HIGH_RISK_THRESHOLD = 0.7;
  static const double MEDIUM_RISK_THRESHOLD = 0.4;

  /// Main method to analyze incidents and update hotspots
  Future<void> analyzeAndUpdateHotspots() async {
    try {
      print('Starting hotspot analysis...');
      
      // Step 1: Fetch recent incidents
      final incidents = await _fetchRecentIncidents();
      print('Fetched ${incidents.length} incidents for analysis');
      
      if (incidents.isEmpty) return;
      
      // Step 2: Cluster incidents by location
      final clusters = _clusterIncidentsByLocation(incidents);
      print('Created ${clusters.length} clusters');
      
      // Step 3: Analyze each cluster and create hotspots
      final hotspots = <HotspotModel>[];
      for (final cluster in clusters) {
        if (cluster.length >= MIN_INCIDENTS_FOR_HOTSPOT) {
          final hotspot = await _analyzeCluster(cluster);
          hotspots.add(hotspot);
        }
      }
      
      // Step 4: Save hotspots to database
      await _saveHotspots(hotspots);
      print('Analysis complete. Created ${hotspots.length} hotspots');
      
    } catch (e) {
      print('Error in hotspot analysis: $e');
    }
  }

  /// Fetch incidents from the last ANALYSIS_PERIOD_DAYS
  Future<List<IncidentModel>> _fetchRecentIncidents() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: ANALYSIS_PERIOD_DAYS));
    
    final querySnapshot = await _firestore
        .collection('emergency_alerts')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
        .where('status', whereIn: ['active', 'resolved']) // exclude false alarms
        .get();
    
    return querySnapshot.docs
        .map((doc) => _convertToIncidentModel(doc))
        .where((incident) => incident != null)
        .cast<IncidentModel>()
        .toList();
  }

  /// Convert emergency alert document to IncidentModel
  IncidentModel? _convertToIncidentModel(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      
      if (location == null) return null;
      
      return IncidentModel(
        id: doc.id,
        latitude: location['latitude']?.toDouble() ?? 0.0,
        longitude: location['longitude']?.toDouble() ?? 0.0,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        incidentType: data['incidentType'] ?? 'emergency',
        severity: _determineSeverity(data),
        userId: data['userId'] ?? '',
        description: data['description'],
        additionalData: data,
        status: data['status'] ?? 'active',
        address: data['address'],
        responseTime: data['responseTime'] ?? 0,
        tags: _extractTags(data),
      );
    } catch (e) {
      print('Error converting document to incident: $e');
      return null;
    }
  }

  /// Determine incident severity based on available data
  String _determineSeverity(Map<String, dynamic> data) {
    // Logic to determine severity based on various factors
    final hasAudio = data['audioRecording'] != null;
    final hasVideo = data['videoRecording'] != null;
    final responseTime = data['responseTime'] ?? 0;
    
    if (hasAudio && hasVideo && responseTime < 5) {
      return 'critical';
    } else if ((hasAudio || hasVideo) && responseTime < 15) {
      return 'high';
    } else if (responseTime < 30) {
      return 'medium';
    }
    return 'low';
  }

  /// Extract relevant tags from incident data
  List<String> _extractTags(Map<String, dynamic> data) {
    final tags = <String>[];
    
    // Add tags based on available data
    if (data['audioRecording'] != null) tags.add('audio_evidence');
    if (data['videoRecording'] != null) tags.add('video_evidence');
    if (data['emergencyContacts']?.isNotEmpty == true) tags.add('contacts_notified');
    
    // Add time-based tags
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final hour = timestamp.hour;
    if (hour >= 22 || hour <= 6) tags.add('night_incident');
    if (timestamp.weekday >= 6) tags.add('weekend_incident');
    
    return tags;
  }

  /// Cluster incidents by geographic proximity
  List<List<IncidentModel>> _clusterIncidentsByLocation(List<IncidentModel> incidents) {
    final clusters = <List<IncidentModel>>[];
    final processed = List<bool>.filled(incidents.length, false);
    
    for (int i = 0; i < incidents.length; i++) {
      if (processed[i]) continue;
      
      final cluster = <IncidentModel>[incidents[i]];
      processed[i] = true;
      
      // Find nearby incidents
      for (int j = i + 1; j < incidents.length; j++) {
        if (processed[j]) continue;
        
        final distance = Geolocator.distanceBetween(
          incidents[i].latitude,
          incidents[i].longitude,
          incidents[j].latitude,
          incidents[j].longitude,
        );
        
        if (distance <= CLUSTER_RADIUS) {
          cluster.add(incidents[j]);
          processed[j] = true;
        }
      }
      
      clusters.add(cluster);
    }
    
    return clusters;
  }

  /// Analyze a cluster of incidents to create a hotspot
  Future<HotspotModel> _analyzeCluster(List<IncidentModel> cluster) async {
    // Calculate center point
    final centerLat = cluster.map((i) => i.latitude).reduce((a, b) => a + b) / cluster.length;
    final centerLng = cluster.map((i) => i.longitude).reduce((a, b) => a + b) / cluster.length;
    
    // Calculate risk score
    final riskScore = _calculateRiskScore(cluster);
    
    // Determine risk level
    final riskLevel = _determineRiskLevel(riskScore);
    
    // Analyze incident types
    final incidentTypes = <String, int>{};
    final allTags = <String>[];
    
    for (final incident in cluster) {
      incidentTypes[incident.incidentType] = (incidentTypes[incident.incidentType] ?? 0) + 1;
      if (incident.tags != null) allTags.addAll(incident.tags!);
    }
    
    // Get most common tags
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    final commonTags = tagCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
    
    // Analyze time patterns
    final timePatterns = _analyzeTimePatterns(cluster);
    
    // Get area name (you might want to use a geocoding service)
    final areaName = await _getAreaName(centerLat, centerLng);
    
    return HotspotModel(
      id: _generateHotspotId(centerLat, centerLng),
      centerLatitude: centerLat,
      centerLongitude: centerLng,
      radius: CLUSTER_RADIUS,
      incidentCount: cluster.length,
      riskScore: riskScore,
      riskLevel: riskLevel,
      lastUpdated: DateTime.now(),
      incidentTypes: incidentTypes,
      commonTags: commonTags,
      areaName: areaName,
      timePatterns: timePatterns,
    );
  }

  /// Calculate risk score based on various factors
  double _calculateRiskScore(List<IncidentModel> incidents) {
    double score = 0.0;
    
    // Base score from incident count
    score += min(incidents.length / 10.0, 0.4); // Max 0.4 from count
    
    // Severity weighting
    final severityWeights = {'low': 0.1, 'medium': 0.2, 'high': 0.3, 'critical': 0.4};
    final avgSeverity = incidents
        .map((i) => severityWeights[i.severity] ?? 0.1)
        .reduce((a, b) => a + b) / incidents.length;
    score += avgSeverity;
    
    // Recency factor (more recent incidents increase score)
    final now = DateTime.now();
    final avgDaysAgo = incidents
        .map((i) => now.difference(i.timestamp).inDays)
        .reduce((a, b) => a + b) / incidents.length;
    final recencyFactor = max(0.0, 1.0 - (avgDaysAgo / ANALYSIS_PERIOD_DAYS));
    score += recencyFactor * 0.2;
    
    return min(score, 1.0);
  }

  /// Determine risk level from score
  String _determineRiskLevel(double score) {
    if (score >= HIGH_RISK_THRESHOLD) return 'critical';
    if (score >= MEDIUM_RISK_THRESHOLD) return 'high';
    if (score >= 0.2) return 'medium';
    return 'low';
  }

  /// Analyze time patterns in incidents
  Map<String, dynamic> _analyzeTimePatterns(List<IncidentModel> incidents) {
    final hourCounts = <int, int>{};
    final dayCounts = <int, int>{};
    
    for (final incident in incidents) {
      final hour = incident.timestamp.hour;
      final day = incident.timestamp.weekday;
      
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }
    
    return {
      'hourlyPattern': hourCounts,
      'dailyPattern': dayCounts,
      'peakHour': hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'peakDay': dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    };
  }

  /// Generate unique ID for hotspot
  String _generateHotspotId(double lat, double lng) {
    return 'hotspot_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
  }

  /// Get area name for coordinates (placeholder - implement with geocoding service)
  Future<String?> _getAreaName(double lat, double lng) async {
    // TODO: Implement with a geocoding service like Google Maps API
    return 'Area_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
  }

  /// Save hotspots to database
  Future<void> _saveHotspots(List<HotspotModel> hotspots) async {
    final batch = _firestore.batch();
    
    for (final hotspot in hotspots) {
      final docRef = _firestore.collection('hotspots').doc(hotspot.id);
      batch.set(docRef, hotspot.toFirestore(), SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  /// Get hotspots near a location
  Future<List<HotspotModel>> getHotspotsNearLocation(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    // Simple bounding box query (for more precision, use geohash)
    final latDelta = radiusKm / 111.0; // Rough conversion
    final lngDelta = radiusKm / (111.0 * cos(latitude * pi / 180));
    
    final querySnapshot = await _firestore
        .collection('hotspots')
        .where('centerLatitude', isGreaterThan: latitude - latDelta)
        .where('centerLatitude', isLessThan: latitude + latDelta)
        .get();
    
    final hotspots = querySnapshot.docs
        .map((doc) => HotspotModel.fromFirestore(doc))
        .where((hotspot) {
          final distance = Geolocator.distanceBetween(
            latitude, longitude,
            hotspot.centerLatitude, hotspot.centerLongitude,
          );
          return distance <= radiusKm * 1000;
        })
        .toList();
    
    return hotspots;
  }

  /// Get all hotspots with optional filtering
  Future<List<HotspotModel>> getAllHotspots({
    String? riskLevel,
    int? minIncidents,
  }) async {
    Query query = _firestore.collection('hotspots');
    
    if (riskLevel != null) {
      query = query.where('riskLevel', isEqualTo: riskLevel);
    }
    
    if (minIncidents != null) {
      query = query.where('incidentCount', isGreaterThanOrEqualTo: minIncidents);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => HotspotModel.fromFirestore(doc))
        .toList();
  }
}
