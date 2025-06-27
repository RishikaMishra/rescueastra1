import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSEmergencyService {
  static final SOSEmergencyService _instance = SOSEmergencyService._internal();
  factory SOSEmergencyService() => _instance;
  SOSEmergencyService._internal();

  // Emergency contacts and settings
  List<String> emergencyContacts = [];
  String emergencyNumber = '112'; // Default emergency number
  bool isSOSActive = false;
  Timer? _sosTimer;

  // Recording instances
  final AudioRecorder _audioRecorder = AudioRecorder();
  CameraController? _cameraController;
  String? _currentRecordingPath;

  // Firebase instances
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the SOS service
  Future<void> initialize() async {
    await _loadEmergencyContacts();
    await _loadEmergencyNumber();
    await _initializeCamera();
  }

  /// Load emergency contacts from SharedPreferences
  Future<void> _loadEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    emergencyContacts = prefs.getStringList('emergency_contacts') ?? [
      '+911234567890', // Default contact 1
      '+919876543210', // Default contact 2
    ];
  }

  /// Load emergency number from SharedPreferences
  Future<void> _loadEmergencyNumber() async {
    final prefs = await SharedPreferences.getInstance();
    emergencyNumber = prefs.getString('emergency_number') ?? '112';
  }

  /// Save emergency contacts to SharedPreferences
  Future<void> saveEmergencyContacts(List<String> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    emergencyContacts = contacts;
    await prefs.setStringList('emergency_contacts', contacts);
  }

  /// Save emergency number to SharedPreferences
  Future<void> saveEmergencyNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    emergencyNumber = number;
    await prefs.setString('emergency_number', number);
  }

  /// Initialize camera for video recording
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await _cameraController?.initialize();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  /// Request all necessary permissions
  Future<Map<Permission, PermissionStatus>> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};

    // Check if running on web
    if (kIsWeb) {
      // Web platform has limited permissions
      statuses[Permission.location] = PermissionStatus.granted; // Web can request location
      statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
      statuses[Permission.microphone] = PermissionStatus.granted; // Web can request microphone
      statuses[Permission.camera] = PermissionStatus.granted; // Web can request camera
      statuses[Permission.storage] = PermissionStatus.granted; // Web has storage access
      statuses[Permission.sms] = PermissionStatus.denied; // Web doesn't support SMS
      statuses[Permission.phone] = PermissionStatus.denied; // Web doesn't support phone calls
      return statuses;
    }

    // Mobile platform permissions
    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.sms,
      Permission.phone,
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ];

    for (Permission permission in permissions) {
      final status = await permission.request();
      statuses[permission] = status;
    }

    return statuses;
  }

  /// Check if all required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    // On web, we only require location permission
    if (kIsWeb) {
      final locationStatus = await Permission.location.status;
      return locationStatus.isGranted;
    }

    // On mobile, check all permissions
    final locationStatus = await Permission.location.status;
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;

    return locationStatus.isGranted &&
           smsStatus.isGranted &&
           phoneStatus.isGranted;
  }

  /// Get current GPS location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Generate Google Maps link from coordinates
  String generateMapsLink(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Send SMS to emergency contacts
  Future<void> sendEmergencySMS(Position position) async {
    // Skip SMS on web platform
    if (kIsWeb) {
      return;
    }

    try {
      final mapsLink = generateMapsLink(position.latitude, position.longitude);
      final message = "🚨 EMERGENCY ALERT 🚨\n"
          "I'm in danger and need immediate help!\n"
          "My current location: $mapsLink\n"
          "Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n"
          "Time: ${DateTime.now().toString()}\n"
          "Please contact emergency services immediately!";

      for (String contact in emergencyContacts) {
        try {
          await sendSMS(
            message: message,
            recipients: [contact],
            sendDirect: true,
          );
          print('SMS sent to $contact');
        } catch (e) {
          print('Failed to send SMS to $contact: $e');
        }
      }
    } catch (e) {
      print('Error sending emergency SMS: $e');
    }
  }

  /// Make emergency call
  Future<void> makeEmergencyCall() async {
    try {
      final Uri phoneUri = Uri.parse('tel:$emergencyNumber');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      print('Error making emergency call: $e');
    }
  }

  /// Start audio recording
  Future<String?> startAudioRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/emergency_audio_$timestamp.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        _currentRecordingPath = path;
        return path;
      }
    } catch (e) {
      print('Error starting audio recording: $e');
    }
    return null;
  }

  /// Stop audio recording
  Future<String?> stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      return path;
    } catch (e) {
      print('Error stopping audio recording: $e');
      return null;
    }
  }

  /// Start video recording
  Future<String?> startVideoRecording() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/emergency_video_$timestamp.mp4';

        await _cameraController!.startVideoRecording();
        _currentRecordingPath = path;
        return path;
      }
    } catch (e) {
      print('Error starting video recording: $e');
    }
    return null;
  }

  /// Stop video recording
  Future<String?> stopVideoRecording() async {
    try {
      if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
        final file = await _cameraController!.stopVideoRecording();
        return file.path;
      }
    } catch (e) {
      print('Error stopping video recording: $e');
    }
    return null;
  }

  /// Upload file to Firebase Storage
  Future<String?> uploadToFirebase(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final ref = _storage.ref().child('emergency_recordings/$fileName');
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading to Firebase: $e');
      return null;
    }
  }

  /// Save emergency data to Firestore
  Future<void> saveEmergencyData({
    required Position position,
    String? audioUrl,
    String? videoUrl,
  }) async {
    try {
      await _firestore.collection('emergency_alerts').add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
        'mapsLink': generateMapsLink(position.latitude, position.longitude),
        'audioRecording': audioUrl,
        'videoRecording': videoUrl,
        'emergencyContacts': emergencyContacts,
        'emergencyNumber': emergencyNumber,
        'status': 'active',
      });
    } catch (e) {
      print('Error saving emergency data: $e');
    }
  }

  /// Main SOS activation method
  Future<SOSResult> activateSOS({bool recordAudio = true, bool recordVideo = false}) async {
    if (isSOSActive) {
      return SOSResult(
        success: false,
        message: 'SOS is already active',
      );
    }

    isSOSActive = true;
    List<String> errors = [];
    String? audioPath;
    String? videoPath;
    Position? position;

    try {
      // 1. Check permissions
      final hasPermissions = await hasRequiredPermissions();
      if (!hasPermissions) {
        final permissionResults = await requestPermissions();
        final deniedPermissions = permissionResults.entries
            .where((entry) => !entry.value.isGranted)
            .map((entry) => entry.key.toString())
            .toList();

        if (deniedPermissions.isNotEmpty) {
          errors.add('Missing permissions: ${deniedPermissions.join(', ')}');
        }
      }

      // 2. Get current location
      position = await getCurrentLocation();
      if (position == null) {
        errors.add('Could not get current location');
      }

      // 3. Start recording (audio or video)
      if (recordAudio && await Permission.microphone.isGranted) {
        audioPath = await startAudioRecording();
        if (audioPath == null) {
          errors.add('Failed to start audio recording');
        }
      }

      if (recordVideo && await Permission.camera.isGranted) {
        videoPath = await startVideoRecording();
        if (videoPath == null) {
          errors.add('Failed to start video recording');
        }
      }

      // 4. Send SMS alerts (if location available and not on web)
      if (position != null && !kIsWeb && await Permission.sms.isGranted) {
        await sendEmergencySMS(position);
      } else if (!kIsWeb) {
        errors.add('Could not send SMS alerts');
      }

      // 5. Make emergency call (not available on web)
      if (!kIsWeb && await Permission.phone.isGranted) {
        await makeEmergencyCall();
      } else if (!kIsWeb) {
        errors.add('Could not make emergency call');
      }

      // 6. Set timer to stop recording after 30 seconds
      _sosTimer = Timer(Duration(seconds: 30), () async {
        await stopSOS();
      });

      // Create success message based on platform
      String successMessage;
      if (kIsWeb) {
        successMessage = errors.isEmpty
            ? 'SOS activated successfully (Web mode: Location and recording available)'
            : 'SOS activated with limited features on web: ${errors.join(', ')}';
      } else {
        successMessage = errors.isEmpty
            ? 'SOS activated successfully'
            : 'SOS activated with some issues: ${errors.join(', ')}';
      }

      return SOSResult(
        success: errors.isEmpty || (position != null), // Success if we at least got location
        message: successMessage,
        position: position,
        audioPath: audioPath,
        videoPath: videoPath,
        errors: errors,
      );

    } catch (e) {
      isSOSActive = false;
      return SOSResult(
        success: false,
        message: 'SOS activation failed: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Stop SOS and upload recordings
  Future<void> stopSOS() async {
    if (!isSOSActive) return;

    try {
      String? audioUrl;
      String? videoUrl;

      // Stop recordings
      if (_currentRecordingPath != null) {
        final audioPath = await stopAudioRecording();
        final videoPath = await stopVideoRecording();

        // Upload to Firebase
        if (audioPath != null) {
          final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          audioUrl = await uploadToFirebase(audioPath, fileName);
        }

        if (videoPath != null) {
          final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
          videoUrl = await uploadToFirebase(videoPath, fileName);
        }
      }

      // Save to Firestore if we have location data
      final position = await getCurrentLocation();
      if (position != null) {
        await saveEmergencyData(
          position: position,
          audioUrl: audioUrl,
          videoUrl: videoUrl,
        );
      }

    } catch (e) {
      print('Error stopping SOS: $e');
    } finally {
      isSOSActive = false;
      _sosTimer?.cancel();
      _currentRecordingPath = null;
    }
  }

  /// Cancel SOS (emergency stop)
  Future<void> cancelSOS() async {
    if (!isSOSActive) return;

    try {
      // Stop recordings without uploading
      await stopAudioRecording();
      await stopVideoRecording();

      // Delete local files
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          await file.delete();
        }
      }

    } catch (e) {
      print('Error canceling SOS: $e');
    } finally {
      isSOSActive = false;
      _sosTimer?.cancel();
      _currentRecordingPath = null;
    }
  }

  /// Dispose resources
  void dispose() {
    _sosTimer?.cancel();
    _audioRecorder.dispose();
    _cameraController?.dispose();
  }
}

/// Result class for SOS activation
class SOSResult {
  final bool success;
  final String message;
  final Position? position;
  final String? audioPath;
  final String? videoPath;
  final List<String> errors;

  SOSResult({
    required this.success,
    required this.message,
    this.position,
    this.audioPath,
    this.videoPath,
    this.errors = const [],
  });
}
