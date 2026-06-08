import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showIcon;

  const AppLogo({
    super.key,
    this.fontSize = 20,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            width: fontSize * 1.6,
            height: fontSize * 1.6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGrad,
            ),
            child: Icon(Icons.home_work_rounded, size: fontSize * 0.8, color: Colors.white),
          ),
          SizedBox(width: fontSize * 0.5),
        ],
        Text.rich(
          TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(decoration: TextDecoration.none),
            children: [
              TextSpan(
                text: 'Prop',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: 'Lens',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
