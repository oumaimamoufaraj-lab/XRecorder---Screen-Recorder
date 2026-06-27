import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/blur_region.dart';
import '../theme/app_colors.dart';

/// Draws draggable blur regions over a video preview.
class BlurRegionOverlay extends StatelessWidget {
  const BlurRegionOverlay({
    super.key,
    required this.regions,
    required this.selectedId,
    required this.onRegionTap,
    required this.onRegionDrag,
    required this.onBackgroundTap,
  });

  final List<BlurRegion> regions;
  final String? selectedId;
  final ValueChanged<String> onRegionTap;
  final void Function(String id, Offset deltaNormalized) onRegionDrag;
  final ValueChanged<Offset> onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final nx = details.localPosition.dx / w;
            final ny = details.localPosition.dy / h;
            final hit = _hitTest(nx, ny);
            if (hit != null) {
              onRegionTap(hit);
            } else {
              onBackgroundTap(Offset(nx, ny));
            }
          },
          child: Stack(
            children: [
              for (final region in regions)
                _BlurRegionBox(
                  region: region,
                  width: w,
                  height: h,
                  selected: region.id == selectedId,
                  onDrag: (delta) => onRegionDrag(region.id, delta),
                  onTap: () => onRegionTap(region.id),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _hitTest(double nx, double ny) {
    for (final region in regions.reversed) {
      if (nx >= region.left &&
          nx <= region.left + region.width &&
          ny >= region.top &&
          ny <= region.top + region.height) {
        return region.id;
      }
    }
    return null;
  }
}

class _BlurRegionBox extends StatelessWidget {
  const _BlurRegionBox({
    required this.region,
    required this.width,
    required this.height,
    required this.selected,
    required this.onDrag,
    required this.onTap,
  });

  final BlurRegion region;
  final double width;
  final double height;
  final bool selected;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: region.left * width,
      top: region.top * height,
      width: region.width * width,
      height: region.height * height,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) {
          onDrag(
            Offset(
              details.delta.dx / width,
              details.delta.dy / height,
            ),
          );
        },
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? AppColors.privacyTeal
                      : Colors.white.withValues(alpha: 0.7),
                  width: selected ? 2.5 : 1.5,
                ),
                color: Colors.black.withValues(alpha: 0.08),
              ),
              child: selected
                  ? const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.blur_on,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
