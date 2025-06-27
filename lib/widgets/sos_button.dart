import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sos_emergency_service.dart';

class SOSButton extends StatefulWidget {
  final double? size;
  final EdgeInsets? margin;
  final bool showLabel;
  final VoidCallback? onSOSActivated;
  final VoidCallback? onSOSCanceled;

  const SOSButton({
    super.key,
    this.size,
    this.margin,
    this.showLabel = false,
    this.onSOSActivated,
    this.onSOSCanceled,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with TickerProviderStateMixin {
  final SOSEmergencyService _sosService = SOSEmergencyService();
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _sosService.initialize();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _onSOSPressed() async {
    if (_sosService.isSOSActive) {
      _showCancelDialog();
      return;
    }

    // Visual feedback through animation

    // Haptic feedback (silent vibration)
    HapticFeedback.heavyImpact();

    // Scale animation
    await _scaleController.forward();
    await _scaleController.reverse();

    try {
      // Show loading dialog
      _showSOSActivationDialog();

      // Activate SOS
      final result = await _sosService.activateSOS(
        recordAudio: true,
        recordVideo: false, // Can be made configurable
      );

      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        if (result.success) {
          _startPulseAnimation();

          // Show success feedback
          _showSOSSuccessDialog(result);

          // Callback
          widget.onSOSActivated?.call();
        } else {
          _showSOSErrorDialog(result);
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        _showSOSErrorDialog(SOSResult(
          success: false,
          message: 'Failed to activate SOS: $e',
        ));
      }
    }
  }

  void _showSOSActivationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Activating Emergency SOS...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Getting location, sending alerts, and starting recording',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSSuccessDialog(SOSResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('SOS Activated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency services have been notified.'),
            SizedBox(height: 8),
            if (result.position != null) ...[
              Text('📍 Location shared successfully'),
              SizedBox(height: 4),
            ],
            if (result.audioPath != null) ...[
              Text('🎤 Audio recording started'),
              SizedBox(height: 4),
            ],
            Text('📱 Emergency contacts alerted'),
            SizedBox(height: 8),
            Text(
              'Recording will stop automatically in 30 seconds.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSOSErrorDialog(SOSResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('SOS Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.errors.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Issues encountered:'),
              ...result.errors.map((error) => Text('• $error')),
            ],
            SizedBox(height: 8),
            Text(
              'Please check your permissions and try again.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel SOS?'),
        content: Text(
          'Are you sure you want to cancel the emergency alert? '
          'This will stop recording and prevent further notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep Active'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelSOS();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Cancel SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSOS() async {
    try {
      await _sosService.cancelSOS();
      _stopPulseAnimation();

      widget.onSOSCanceled?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS canceled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? 60.0;

    return Container(
      margin: widget.margin ?? EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _sosService.isSOSActive ? _pulseAnimation.value : 1.0,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _sosService.isSOSActive ? Colors.red[700] : Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: _sosService.isSOSActive ? 20 : 10,
                              spreadRadius: _sosService.isSOSActive ? 5 : 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(buttonSize / 2),
                            onTap: _onSOSPressed,
                            child: Center(
                              child: Icon(
                                _sosService.isSOSActive ? Icons.stop : Icons.sos,
                                color: Colors.white,
                                size: buttonSize * 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (widget.showLabel) ...[
            SizedBox(height: 8),
            Text(
              _sosService.isSOSActive ? 'SOS ACTIVE' : 'Emergency SOS',
              style: TextStyle(
                color: _sosService.isSOSActive ? Colors.red : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
