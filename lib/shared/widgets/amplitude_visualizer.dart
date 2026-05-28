import 'dart:math';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:speakeng/core/theme.dart';

/// Animated bars visualizing microphone amplitude during recording.
class AmplitudeVisualizer extends StatelessWidget {
  const AmplitudeVisualizer({super.key, required this.amplitudeStream});

  final Stream<Amplitude> amplitudeStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Amplitude>(
      stream: amplitudeStream,
      builder: (context, snapshot) {
        final normalized = _normalize(snapshot.data?.current ?? -50);
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (i) {
              final barHeight = _barHeight(i, normalized);
              return Container(
                width: 3,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.full,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// Normalize dB value (-50..0) to 0..1.
  double _normalize(double dB) => ((dB + 50) / 50).clamp(0.0, 1.0);

  /// Generate varied bar heights based on position and amplitude.
  double _barHeight(int index, double amplitude) {
    final wave = (sin(index * 0.7) + 1) / 2;
    return max(4, 48 * amplitude * wave);
  }
}
