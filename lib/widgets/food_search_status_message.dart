import 'package:flutter/material.dart';

import '../models/food_search_result.dart';

class FoodSearchStatusMessage extends StatelessWidget {
  final FoodSearchStatus status;
  final String query;
  final String? customMessage;
  final VoidCallback? onRetry;

  const FoodSearchStatusMessage({
    super.key,
    required this.status,
    required this.query,
    this.customMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == FoodSearchStatus.notFound) {
      return _StatusCard(
        icon: Icons.search_off,
        iconColor: Colors.blueGrey,
        backgroundColor: const Color(0xFFF5F5F5),
        borderColor: const Color(0xFFE0E0E0),
        title: 'לא נמצא מזון',
        message: customMessage ??
            (query.isEmpty
                ? 'לא נמצאו תוצאות לחיפוש הזה.'
                : 'לא נמצא מזון עבור "$query".\nנסי מילה אחרת או חיפוש באנגלית.'),
      );
    }

    return _StatusCard(
      icon: Icons.cloud_off_outlined,
      iconColor: Colors.deepOrange,
      backgroundColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFFCC80),
      title: 'חיפוש מהאינטרנט לא זמין',
      message: customMessage ??
          'לא הצלחנו להתחבר למאגר המזון באינטרנט.\nבדקי את חיבור האינטרנט ונסי שוב.',
      action: onRetry == null
          ? null
          : TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('נסי שוב'),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final Widget? action;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            action!,
          ],
        ],
      ),
    );
  }
}
