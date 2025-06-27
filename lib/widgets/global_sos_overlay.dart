import 'package:flutter/material.dart';
import 'sos_button.dart';
import '../screen/emergency_settings.dart';

class GlobalSOSOverlay extends StatelessWidget {
  final Widget child;
  final bool showSettingsButton;
  final EdgeInsets? sosButtonMargin;
  final double? sosButtonSize;

  const GlobalSOSOverlay({
    super.key,
    required this.child,
    this.showSettingsButton = true,
    this.sosButtonMargin,
    this.sosButtonSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: sosButtonMargin?.bottom ?? 80, // Just above taskbar
          right: sosButtonMargin?.right ?? 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSettingsButton) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmergencySettingsPage(),
                        ),
                      );
                    },
                    backgroundColor: Colors.grey[700],
                    tooltip: 'Emergency Settings',
                    elevation: 6,
                    child: Icon(Icons.settings, size: 20, color: Colors.white),
                  ),
                ),
              ],
              SOSButton(
                size: sosButtonSize ?? 60,
                margin: EdgeInsets.zero, // No additional margin since we're positioning with Positioned
                showLabel: true,
                onSOSActivated: () {
                  // Global SOS activation callback
                  _showSOSActiveNotification(context);
                },
                onSOSCanceled: () {
                  // Global SOS cancellation callback
                  _showSOSCanceledNotification(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSOSActiveNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Emergency SOS is now active. Help is on the way!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSOSCanceledNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Emergency SOS has been canceled'),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Wrapper widget to easily add SOS functionality to any screen
class SOSEnabledScreen extends StatelessWidget {
  final Widget child;
  final bool showSettingsButton;
  final EdgeInsets? sosButtonMargin;
  final double? sosButtonSize;

  const SOSEnabledScreen({
    super.key,
    required this.child,
    this.showSettingsButton = true,
    this.sosButtonMargin,
    this.sosButtonSize,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalSOSOverlay(
      showSettingsButton: showSettingsButton,
      sosButtonMargin: sosButtonMargin,
      sosButtonSize: sosButtonSize,
      child: child,
    );
  }
}
