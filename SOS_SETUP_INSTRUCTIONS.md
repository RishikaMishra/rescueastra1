# SOS Emergency System Setup Instructions

## Overview
The SOS Emergency System provides comprehensive emergency response functionality including:
- Real-time GPS location sharing
- Automatic SMS alerts to emergency contacts
- Emergency service calls
- Audio/video recording
- Cloud storage backup
- Silent operation with visual feedback

## Dependencies Added

The following dependencies have been added to `pubspec.yaml`:

```yaml
# SOS Emergency System Dependencies
geolocator: ^10.1.0           # GPS location services
permission_handler: ^11.3.1   # Runtime permissions
telephony: ^0.2.0            # SMS functionality (alternative)
camera: ^0.10.5+9            # Camera for video recording
path_provider: ^2.1.2        # File system access
record: ^5.0.4               # Audio recording
firebase_storage: ^12.3.2    # Cloud file storage
cloud_firestore: ^5.4.4      # Database for emergency logs
flutter_sms: ^2.3.3          # SMS sending
```

## Installation Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Android Configuration

#### Permissions (Already Added)
The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- SEND_SMS
- CALL_PHONE
- RECORD_AUDIO
- CAMERA
- WRITE_EXTERNAL_STORAGE
- READ_EXTERNAL_STORAGE
- INTERNET
- ACCESS_NETWORK_STATE
- VIBRATE

#### ProGuard Rules (Optional)
If using ProGuard, add to `android/app/proguard-rules.pro`:
```
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
```

### 3. iOS Configuration

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to send your location during emergencies</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to send your location during emergencies</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio during emergencies</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record video during emergencies</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save emergency recordings</string>
```

### 4. Firebase Setup

#### Enable Required Services
1. Go to Firebase Console
2. Enable the following services:
   - Cloud Firestore
   - Firebase Storage
   - Authentication (if not already enabled)

#### Storage Rules
Update Firebase Storage rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /emergency_recordings/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Firestore Rules
Update Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /emergency_alerts/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Usage

### 1. Basic Implementation

Add SOS button to any screen:
```dart
import 'package:rescueastra/widgets/sos_button.dart';

// In your widget build method:
SOSButton(
  size: 70,
  showLabel: true,
  onSOSActivated: () {
    // Optional callback when SOS is activated
  },
  onSOSCanceled: () {
    // Optional callback when SOS is canceled
  },
)
```

### 2. Global SOS Overlay

Wrap any screen with SOS functionality:
```dart
import 'package:rescueastra/widgets/global_sos_overlay.dart';

SOSEnabledScreen(
  showSettingsButton: true,
  child: YourScreenWidget(),
)
```

### 3. Emergency Settings

Navigate to emergency settings:
```dart
import 'package:rescueastra/screen/emergency_settings.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EmergencySettingsPage(),
  ),
);
```

### 4. Service Initialization

Initialize the SOS service in your app:
```dart
import 'package:rescueastra/services/sos_emergency_service.dart';

// In your main app or initialization
final sosService = SOSEmergencyService();
await sosService.initialize();
```

## Configuration

### Emergency Contacts
- Add emergency contacts through the Emergency Settings page
- Contacts should include country code (e.g., +91 for India)
- Minimum 1 contact required, maximum 5 recommended

### Emergency Number
- Default: 112 (international emergency number)
- Can be changed to local emergency numbers (911, 100, etc.)
- Configure through Emergency Settings page

### Recording Settings
- Audio recording: 30 seconds by default
- Video recording: Optional (can be enabled in code)
- Files are automatically uploaded to Firebase Storage

## Testing

### Permission Testing
1. Go to Emergency Settings
2. Tap the security icon in the app bar
3. Check permission status
4. Grant any missing permissions

### SOS Testing
⚠️ **WARNING**: Testing will send real SMS messages and make real calls!

For safe testing:
1. Use test phone numbers
2. Temporarily disable SMS sending in code
3. Use a test emergency number
4. Test in a controlled environment

### Test Checklist
- [ ] Location permission granted
- [ ] SMS permission granted
- [ ] Phone permission granted
- [ ] Camera permission granted
- [ ] Microphone permission granted
- [ ] Emergency contacts configured
- [ ] Emergency number configured
- [ ] Firebase services working
- [ ] SOS button responds to tap
- [ ] Recording starts/stops correctly

## Troubleshooting

### Common Issues

1. **Permissions Denied**
   - Check Android/iOS permission settings
   - Request permissions through the app
   - Restart app after granting permissions

2. **Location Not Available**
   - Enable GPS/Location services
   - Check location permissions
   - Test in open area (not indoors)

3. **SMS Not Sending**
   - Check SMS permissions
   - Verify phone numbers include country code
   - Test with different carriers

4. **Recording Fails**
   - Check microphone/camera permissions
   - Ensure sufficient storage space
   - Test on different devices

5. **Firebase Upload Fails**
   - Check internet connection
   - Verify Firebase configuration
   - Check Firebase Storage rules

### Debug Mode
Enable debug logging by modifying the service:
```dart
// In sos_emergency_service.dart
// Replace print statements with proper logging
```

## Security Considerations

1. **Data Privacy**
   - Emergency recordings are encrypted in transit
   - Firebase Storage provides secure cloud storage
   - Location data is only shared during emergencies

2. **Access Control**
   - Only authenticated users can access emergency data
   - Firestore rules prevent unauthorized access
   - Local files are stored in app-private directories

3. **Emergency Contacts**
   - Stored locally on device
   - Backed up to secure preferences
   - Not shared with third parties

## Production Deployment

### Before Release
1. Test on multiple devices
2. Verify all permissions work correctly
3. Test with real emergency contacts (with consent)
4. Configure proper Firebase security rules
5. Remove debug logging
6. Test emergency number calling

### App Store Guidelines
- Clearly describe emergency functionality in app description
- Include privacy policy covering location and recording data
- Ensure compliance with local emergency service regulations

## Support

For issues or questions:
1. Check this documentation
2. Review Firebase console for errors
3. Test permissions and configuration
4. Contact development team

---

**IMPORTANT**: This system is designed for real emergencies. Test responsibly and ensure all stakeholders understand the functionality before deployment.
