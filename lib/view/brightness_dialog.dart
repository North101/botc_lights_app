import '/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_page/providers.dart';

final brightnessProvider = Provider((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.brightness;
});

class BrightnessDialog extends ConsumerWidget {
  const BrightnessDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    return AlertDialog(
      title: const Text('Brightness'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: brightness.toDouble(),
            min: GameStateNotifier.minBrightness.toDouble(),
            max: GameStateNotifier.maxBrightness.toDouble(),
            divisions: 100,
            label: '$brightness%',
            onChanged: (value) => ref.read(gameStateProvider).brightness = value.round(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
