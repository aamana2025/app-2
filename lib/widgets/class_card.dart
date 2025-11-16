import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  final String className;
  final String status; // "active" or "suspended"
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.className,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == 'suspended' || status == 'pending';
    print(
        'ClassCard: Building card for $className with status: $status, isSuspended: $isSuspended');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSuspended ? () => _showSuspendedDialog(context) : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isSuspended
              ? Colors.orange.withOpacity(0.1)
              : const Color(0xFF0A84FF).withOpacity(0.1),
          highlightColor: isSuspended
              ? Colors.orange.withOpacity(0.05)
              : const Color(0xFF0A84FF).withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSuspended
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: isSuspended
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 92,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSuspended
                            ? const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isSuspended
                              ? Icons.pause_circle_outline
                              : Icons.co_present_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            className,
                            style: TextStyle(
                              color: isSuspended
                                  ? Colors.orange[700]
                                  : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSuspended
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSuspended ? Colors.orange : Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isSuspended ? 'معلق' : 'نشط',
                              style: TextStyle(
                                color: isSuspended
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSuspended
                          ? Icons.warning_amber
                          : Icons.arrow_forward_ios,
                      size: 18,
                      color:
                          isSuspended ? Colors.orange : const Color(0xFF0A84FF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuspendedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'كلاس معلق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'هذا الكلاس معلق لا يمكن الدخول',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
