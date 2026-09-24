import 'package:flutter/material.dart';

class NotificationsEmptyState extends StatelessWidget {
  final Color primaryText;
  final Color secondaryText;

  const NotificationsEmptyState({
    super.key,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FEF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 45,
              color: Color(0xFF5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'No Notifications',
            style: TextStyle(
              color: primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You are all caught up!',
            style: TextStyle(
              color: secondaryText,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}