import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 110,
    this.radius = 28,
    this.withShadow = true,
  });

  final double size;
  final double radius;
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: const Image(
        image: AssetImage('assets/images/app_icon.png'),
        fit: BoxFit.cover,
      ),
    );
  }
}
