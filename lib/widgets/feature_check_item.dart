import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';

class FeatureCheckItem extends StatelessWidget {
  const FeatureCheckItem({
    super.key,
    required this.label,
    required this.accentColor,
    this.textColor,
  });

  final String label;
  final Color accentColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: accentColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: textColor ?? context.palette.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
