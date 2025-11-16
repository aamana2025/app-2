import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime expiryDate;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.expiryDate,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.expiryDate.difference(now);

    if (difference.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
        _isExpired = true;
      });
      widget.onExpired?.call();
    } else {
      setState(() {
        _remainingTime = difference;
        _isExpired = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days} يوم ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Format duration for small screens (more compact)
  String _formatDurationCompact(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}د ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine if we need to adjust layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Small phones like iPhone SE
    final isVerySmallScreen = screenWidth < 320; // Very small screens

    return Container(
      width: double.infinity, // Take full width to prevent overflow
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
        vertical: isVerySmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: _isExpired
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpired ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isExpired ? Icons.warning : Icons.access_time,
            color: _isExpired ? Colors.red : Colors.orange,
            size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
          ),
          SizedBox(width: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
          Expanded(
            // Make text flexible to prevent overflow
            child: Text(
              _isExpired
                  ? 'انتهت الصلاحية'
                  : 'معاد التجديد: ${_getFormattedDuration(isVerySmallScreen, isSmallScreen)}',
              style: TextStyle(
                color: _isExpired ? Colors.red : Colors.orange,
                fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow gracefully
              maxLines: isVerySmallScreen
                  ? 3
                  : 2, // Allow more lines for very small screens
            ),
          ),
        ],
      ),
    );
  }

  // Get the appropriate formatted duration based on screen size
  String _getFormattedDuration(bool isVerySmallScreen, bool isSmallScreen) {
    if (isVerySmallScreen) {
      // For very small screens, use the most compact format
      return _formatDurationVeryCompact(_remainingTime);
    } else if (isSmallScreen) {
      // For small screens, use compact format
      return _formatDurationCompact(_remainingTime);
    } else {
      // For normal screens, use full format
      return _formatDuration(_remainingTime);
    }
  }

  // Format duration for very small screens (most compact)
  String _formatDurationVeryCompact(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}د ${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
