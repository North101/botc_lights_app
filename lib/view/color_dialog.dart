import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';

class ColorsDialog extends ConsumerWidget {
  static const pickersEnabled = {
    ColorPickerType.primary: false,
    ColorPickerType.accent: false,
    ColorPickerType.wheel: true,
  };

  const ColorsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorsProvider);
    return AlertDialog(
      title: const Text('Colors'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPicker(
            title: const Text('Character'),
            color: colors.character,
            pickersEnabled: pickersEnabled,
            enableShadesSelection: false,
            onColorChanged: (value) => ref.read(gameStateProvider).colors = colors.copyWith(
              character: value,
            ),
          ),
          ColorPicker(
            title: const Text('Traveller'),
            color: colors.traveller,
            pickersEnabled: pickersEnabled,
            enableShadesSelection: false,
            onColorChanged: (value) => ref.read(gameStateProvider).colors = colors.copyWith(
              traveller: value,
            ),
          ),
          ColorPicker(
            title: const Text('Dead'),
            color: colors.dead,
            pickersEnabled: pickersEnabled,
            enableShadesSelection: false,
            onColorChanged: (value) => ref.read(gameStateProvider).colors = colors.copyWith(
              dead: value,
            ),
          ),
          ColorPicker(
            title: const Text('Good'),
            color: colors.good,
            pickersEnabled: pickersEnabled,
            enableShadesSelection: false,
            onColorChanged: (value) => ref.read(gameStateProvider).colors = colors.copyWith(
              good: value,
            ),
          ),
          ColorPicker(
            title: const Text('Evil'),
            color: colors.evil,
            pickersEnabled: pickersEnabled,
            enableShadesSelection: false,
            onColorChanged: (value) => ref.read(gameStateProvider).colors = colors.copyWith(
              evil: value,
            ),
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
