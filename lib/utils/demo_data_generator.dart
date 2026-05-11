import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generate demo emergency alerts for testing hotspot analysis
  static Future<void> generateDemoEmergencyAlerts({
    int count = 50,
    double centerLat = 28.6139, // Delhi
    double centerLng = 77.2090,
    double radiusKm = 10.0,
  }) async {
    print('Generating $count demo emergency alerts...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    // Define hotspot centers for realistic clustering
    final hotspotCenters = [
      {'lat': 28.6139, 'lng': 77.2090, 'name': 'Connaught Place'},
      {'lat': 28.5355, 'lng': 77.3910, 'name': 'Noida Sector 18'},
      {'lat': 28.4595, 'lng': 77.0266, 'name': 'Gurgaon Cyber City'},
      {'lat': 28.6692, 'lng': 77.4538, 'name': 'Laxmi Nagar'},
      {'lat': 28.7041, 'lng': 77.1025, 'name': 'Rohini'},
    ];
    
    final incidentTypes = [
      'harassment',
      'theft',
      'assault',
      'stalking',
      'emergency',
      'suspicious_activity',
    ];
    
    final severityLevels = ['low', 'medium', 'high', 'critical'];
    
    // Always add fixed incidents for specific locations in Delhi NCR
    final fixedIncidents = [
      {
        'userId': 'demo_user_connaught',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'location': {'latitude': 28.6304, 'longitude': 77.2177},
        'incidentType': 'harassment',
        'severity': 'high',
        'status': 'resolved',
        'responseTime': 5,
        'description': 'Verbal harassment by unknown person - High priority situation',
        'address': 'Connaught Place, Delhi',
        'tags': ['verbal_harassment', 'audio_evidence', 'contacts_notified'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 1', 'phone': '+911234567890', 'relation': 'family'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'isDemo': true,
        'gender': 'female',
        'detectedThreats': ['verbal'],
      },
      {
        'userId': 'demo_user_noida',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'location': {'latitude': 28.5700, 'longitude': 77.3210},
        'incidentType': 'theft',
        'severity': 'medium',
        'status': 'active',
        'responseTime': 10,
        'description': 'Bag stolen from public transport - Medium priority situation',
        'address': 'Noida City Centre, Noida',
        'tags': ['personal_belongings', 'contacts_notified'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 2', 'phone': '+911234567891', 'relation': 'friend'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'isDemo': true,
        'gender': 'male',
        'detectedThreats': ['weapon'],
      },
      {
        'userId': 'demo_user_gurgaon',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'location': {'latitude': 28.5045, 'longitude': 77.0970},
        'incidentType': 'assault',
        'severity': 'critical',
        'status': 'resolved',
        'responseTime': 3,
        'description': 'Physical altercation with stranger - URGENT: Immediate danger',
        'address': 'MG Road, Gurgaon',
        'tags': ['immediate_danger', 'contacts_notified'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 3', 'phone': '+911234567892', 'relation': 'colleague'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'isDemo': true,
        'gender': 'female',
        'detectedThreats': ['physical'],
      },
      {
        'userId': 'demo_user_laxminagar',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'location': {'latitude': 28.6038, 'longitude': 77.2774},
        'incidentType': 'stalking',
        'severity': 'low',
        'status': 'resolved',
        'responseTime': 8,
        'description': 'Being followed by unknown person',
        'address': 'Laxmi Nagar, Delhi',
        'tags': ['audio_evidence'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 4', 'phone': '+911234567893', 'relation': 'family'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'isDemo': true,
        'gender': 'female',
        'detectedThreats': [],
      },
      {
        'userId': 'demo_user_rohini',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'location': {'latitude': 28.7499, 'longitude': 77.0565},
        'incidentType': 'suspicious_activity',
        'severity': 'medium',
        'status': 'active',
        'responseTime': 12,
        'description': 'Suspicious person in the area',
        'address': 'Rohini, Delhi',
        'tags': ['suspicious_object'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 5', 'phone': '+911234567894', 'relation': 'friend'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'isDemo': true,
        'gender': 'unknown',
        'detectedThreats': ['suspicious_object'],
      },
      {
        'userId': 'demo_user_khatana',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
        'location': {'latitude': 28.3866, 'longitude': 77.3076},
        'incidentType': 'emergency',
        'severity': 'high',
        'status': 'active',
        'responseTime': 7,
        'description': 'General emergency situation - High priority situation',
        'address': 'Khatana Chowk, Dabua Colony, NIT Faridabad',
        'tags': ['contacts_notified'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 6', 'phone': '+911234567895', 'relation': 'family'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
        'isDemo': true,
        'gender': 'female',
        'detectedThreats': ['verbal'],
      },
      {
        'userId': 'demo_user_pali',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'location': {'latitude': 28.4100, 'longitude': 77.2100},
        'incidentType': 'harassment',
        'severity': 'medium',
        'status': 'resolved',
        'responseTime': 9,
        'description': 'Inappropriate comments and gestures - Medium priority situation',
        'address': 'Pali gaon, Faridabad',
        'tags': ['verbal_harassment', 'contacts_notified'],
        'audioRecording': null,
        'videoRecording': null,
        'emergencyContacts': [
          {'name': 'Emergency Contact 7', 'phone': '+911234567896', 'relation': 'friend'}
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'isDemo': true,
        'gender': 'female',
        'detectedThreats': ['verbal'],
      },
    ];
    for (final incident in fixedIncidents) {
      final docRef = _firestore.collection('emergency_alerts').doc();
      batch.set(docRef, incident);
    }
    
    for (int i = 0; i < count; i++) {
      // Choose a hotspot center (80% chance) or random location (20% chance)
      late double lat, lng;
      String? areaName;
      
      if (_random.nextDouble() < 0.8) {
        // Cluster around hotspot centers
        final hotspot = hotspotCenters[_random.nextInt(hotspotCenters.length)];
        lat = hotspot['lat'] as double;
        lng = hotspot['lng'] as double;
        areaName = hotspot['name'] as String;
        
        // Add some random offset within 1km
        final offsetKm = _random.nextDouble() * 1.0;
        final angle = _random.nextDouble() * 2 * pi;
        lat += (offsetKm / 111.0) * cos(angle);
        lng += (offsetKm / (111.0 * cos(lat * pi / 180))) * sin(angle);
      } else {
        // Random location within radius
        final distance = _random.nextDouble() * radiusKm;
        final angle = _random.nextDouble() * 2 * pi;
        lat = centerLat + (distance / 111.0) * cos(angle);
        lng = centerLng + (distance / (111.0 * cos(centerLat * pi / 180))) * sin(angle);
      }
      
      // Generate timestamp within last 90 days
      final daysAgo = _random.nextInt(90);
      final hoursAgo = _random.nextInt(24);
      final minutesAgo = _random.nextInt(60);
      final timestamp = now.subtract(Duration(
        days: daysAgo,
        hours: hoursAgo,
        minutes: minutesAgo,
      ));
      
      // Generate incident data
      final incidentType = incidentTypes[_random.nextInt(incidentTypes.length)];
      final severity = severityLevels[_random.nextInt(severityLevels.length)];
      final responseTime = _random.nextInt(30) + 1; // 1-30 minutes
      
      // Generate gender (bias towards female for Delhi)
      String gender = 'female';
      if (_random.nextDouble() < 0.2) gender = 'male';
      if (_random.nextDouble() < 0.05) gender = 'unknown';

      // Generate detected threats (realistic for incident type)
      List<String> detectedThreats = [];
      if (incidentType == 'harassment' || incidentType == 'assault') {
        if (_random.nextBool()) detectedThreats.add('verbal');
        if (_random.nextBool()) detectedThreats.add('physical');
      }
      if (incidentType == 'theft') {
        if (_random.nextBool()) detectedThreats.add('weapon');
      }
      if (incidentType == 'suspicious_activity') {
        if (_random.nextBool()) detectedThreats.add('suspicious_object');
      }
      
      // Generate realistic tags based on incident type and time
      final tags = <String>[];
      if (incidentType == 'harassment') tags.add('verbal_harassment');
      if (incidentType == 'theft') tags.add('personal_belongings');
      if (severity == 'critical') tags.add('immediate_danger');
      if (timestamp.hour >= 22 || timestamp.hour <= 6) tags.add('night_incident');
      if (timestamp.weekday >= 6) tags.add('weekend_incident');
      if (_random.nextBool()) tags.add('audio_evidence');
      if (_random.nextBool()) tags.add('video_evidence');
      if (_random.nextBool()) tags.add('contacts_notified');
      
      final alertData = {
        'userId': 'demo_user_${_random.nextInt(100)}',
        'timestamp': Timestamp.fromDate(timestamp),
        'location': {
          'latitude': lat,
          'longitude': lng,
        },
        'incidentType': incidentType,
        'severity': severity,
        'status': _random.nextDouble() < 0.9 ? 'resolved' : 'active',
        'responseTime': responseTime,
        'description': _generateDescription(incidentType, severity),
        'address': areaName ?? 'Demo Location $i',
        'tags': tags,
        'audioRecording': _random.nextBool() ? 'demo_audio_$i.mp3' : null,
        'videoRecording': _random.nextBool() ? 'demo_video_$i.mp4' : null,
        'emergencyContacts': _generateEmergencyContacts(),
        'createdAt': Timestamp.fromDate(timestamp),
        'isDemo': true, // Mark as demo data for easy cleanup
        'gender': gender,
        'detectedThreats': detectedThreats,
      };
      
      final docRef = _firestore.collection('emergency_alerts').doc();
      batch.set(docRef, alertData);
    }
    
    await batch.commit();
    print('Successfully generated $count demo emergency alerts!');
  }
  
  static String _generateDescription(String incidentType, String severity) {
    final descriptions = {
      'harassment': [
        'Verbal harassment by unknown person',
        'Inappropriate comments and gestures',
        'Following and making uncomfortable remarks',
      ],
      'theft': [
        'Phone snatched while walking',
        'Bag stolen from public transport',
        'Wallet pickpocketed in crowded area',
      ],
      'assault': [
        'Physical altercation with stranger',
        'Pushed and threatened',
        'Attempted physical harm',
      ],
      'stalking': [
        'Being followed by unknown person',
        'Repeated unwanted attention',
        'Suspicious person tracking movements',
      ],
      'emergency': [
        'General emergency situation',
        'Feeling unsafe and threatened',
        'Need immediate assistance',
      ],
      'suspicious_activity': [
        'Suspicious person in the area',
        'Unusual activity observed',
        'Potential safety concern',
      ],
    };
    
    final typeDescriptions = descriptions[incidentType] ?? ['Emergency situation'];
    final baseDescription = typeDescriptions[_random.nextInt(typeDescriptions.length)];
    
    if (severity == 'critical') {
      return '$baseDescription - URGENT: Immediate danger';
    } else if (severity == 'high') {
      return '$baseDescription - High priority situation';
    }
    
    return baseDescription;
  }
  
  static List<Map<String, String>> _generateEmergencyContacts() {
    final contacts = <Map<String, String>>[];
    final contactCount = _random.nextInt(3) + 1; // 1-3 contacts
    
    for (int i = 0; i < contactCount; i++) {
      contacts.add({
        'name': 'Emergency Contact ${i + 1}',
        'phone': '+91${_random.nextInt(9000000000) + 1000000000}',
        'relation': ['family', 'friend', 'colleague'][_random.nextInt(3)],
      });
    }
    
    return contacts;
  }
  
  /// Clean up demo data
  static Future<void> cleanupDemoData() async {
    print('Cleaning up demo data...');
    
    final querySnapshot = await _firestore
        .collection('emergency_alerts')
        .where('isDemo', isEqualTo: true)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('Demo data cleanup completed!');
  }
  
  /// Generate demo data and run analysis
  static Future<void> generateDemoDataAndAnalyze() async {
    try {
      // Clean up existing demo data
      await cleanupDemoData();
      
      // Generate new demo data
      await generateDemoEmergencyAlerts(count: 75);
      
      // Wait a moment for data to be indexed
      await Future.delayed(const Duration(seconds: 2));
      
      print('Demo data generation completed! You can now run hotspot analysis.');
      
    } catch (e) {
      print('Error generating demo data: $e');
    }
  }
}
