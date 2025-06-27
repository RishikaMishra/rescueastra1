import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String incidentType;
  final String severity; // low, medium, high, critical
  final String userId;
  final String? description;
  final Map<String, dynamic>? additionalData;
  final String status; // active, resolved, false_alarm
  final String? address;
  final int responseTime; // in minutes
  final List<String>? tags; // harassment, theft, assault, etc.

  IncidentModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.incidentType,
    required this.severity,
    required this.userId,
    this.description,
    this.additionalData,
    required this.status,
    this.address,
    required this.responseTime,
    this.tags,
  });

  // Convert from Firestore document
  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncidentModel(
      id: doc.id,
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      incidentType: data['incidentType'] ?? 'unknown',
      severity: data['severity'] ?? 'low',
      userId: data['userId'] ?? '',
      description: data['description'],
      additionalData: data['additionalData'],
      status: data['status'] ?? 'active',
      address: data['address'],
      responseTime: data['responseTime'] ?? 0,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'incidentType': incidentType,
      'severity': severity,
      'userId': userId,
      'description': description,
      'additionalData': additionalData,
      'status': status,
      'address': address,
      'responseTime': responseTime,
      'tags': tags,
    };
  }
}

class HotspotModel {
  final String id;
  final double centerLatitude;
  final double centerLongitude;
  final double radius; // in meters
  final int incidentCount;
  final double riskScore; // 0.0 to 1.0
  final String riskLevel; // low, medium, high, critical
  final DateTime lastUpdated;
  final Map<String, int> incidentTypes; // type -> count
  final List<String> commonTags;
  final String? areaName;
  final Map<String, dynamic>? timePatterns; // hour/day patterns

  HotspotModel({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radius,
    required this.incidentCount,
    required this.riskScore,
    required this.riskLevel,
    required this.lastUpdated,
    required this.incidentTypes,
    required this.commonTags,
    this.areaName,
    this.timePatterns,
  });

  factory HotspotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HotspotModel(
      id: doc.id,
      centerLatitude: data['centerLatitude']?.toDouble() ?? 0.0,
      centerLongitude: data['centerLongitude']?.toDouble() ?? 0.0,
      radius: data['radius']?.toDouble() ?? 100.0,
      incidentCount: data['incidentCount'] ?? 0,
      riskScore: data['riskScore']?.toDouble() ?? 0.0,
      riskLevel: data['riskLevel'] ?? 'low',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      incidentTypes: Map<String, int>.from(data['incidentTypes'] ?? {}),
      commonTags: List<String>.from(data['commonTags'] ?? []),
      areaName: data['areaName'],
      timePatterns: data['timePatterns'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radius': radius,
      'incidentCount': incidentCount,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'incidentTypes': incidentTypes,
      'commonTags': commonTags,
      'areaName': areaName,
      'timePatterns': timePatterns,
    };
  }
}
