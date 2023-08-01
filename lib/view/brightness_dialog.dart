import 'package:botc_lights_app/view/device_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrightnessDialog extends ConsumerWidget {
  const BrightnessDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    return AlertDialog(
      title: const Text('Brightness'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: gameState.brightness,
            max: 1.0,
            divisions: 100,
            label: '${(gameState.brightness * 100).round()}%',
            onChanged: (value) => gameState.setBrightness(value),
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
