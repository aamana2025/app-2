import 'package:flutter/material.dart';
import 'countdown_timer.dart';

/// Test widget to verify countdown timer responsiveness on different screen sizes
/// This widget can be temporarily added to any screen for testing
class CountdownTimerTest extends StatelessWidget {
  const CountdownTimerTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a test expiry date (25 days from now)
    final testExpiryDate = DateTime.now()
        .add(const Duration(days: 25, hours: 4, minutes: 3, seconds: 16));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Countdown Timer Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Screen Width: ${MediaQuery.of(context).size.width}px',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Screen Size: ${_getScreenSize(MediaQuery.of(context).size.width)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Countdown Timer:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CountdownTimer(
              expiryDate: testExpiryDate,
              onExpired: () {
                print('Countdown expired!');
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Different Text Lengths Test:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Test with different text lengths
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: const Text(
                'معاد التجديد: 25 يوم 04:03:16',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Text(
                'معاد التجديد: 25د 04:03:16',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScreenSize(double width) {
    if (width < 320) {
      return 'Very Small (< 320px)';
    } else if (width < 360) {
      return 'Small (320-360px)';
    } else if (width < 400) {
      return 'Medium (360-400px)';
    } else if (width < 500) {
      return 'Large (400-500px)';
    } else {
      return 'Extra Large (> 500px)';
    }
  }
}
