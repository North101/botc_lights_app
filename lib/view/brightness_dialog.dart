import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';

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
            min: BrightnessNotifier.minBrightness.toDouble(),
            max: BrightnessNotifier.maxBrightness.toDouble(),
            divisions: 100,
            label: '$brightness%',
            onChanged: (value) => ref.read(brightnessProvider.notifier).update(value.round()),
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
