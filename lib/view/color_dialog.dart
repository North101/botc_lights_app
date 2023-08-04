import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';

enum PlayerColors {
  character('Character'),
  traveller('Traveller'),
  dead('Dead'),
  good('Good'),
  evil('Evil');

  const PlayerColors(this.title);

  final String title;
}

final selectedColorProvider = StateProvider.autoDispose((ref) => PlayerColors.character);

class ColorsDialog extends StatelessWidget {
  const ColorsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Colors'),
      scrollable: true,
      content: const ColorsDialogContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class ColorsDialogContent extends ConsumerWidget {
  static const pickersEnabled = {
    ColorPickerType.primary: false,
    ColorPickerType.accent: false,
    ColorPickerType.wheel: true,
  };

  const ColorsDialogContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorsProvider);
    final selectedColor = ref.watch(selectedColorProvider);
    final color = switch (selectedColor) {
      PlayerColors.character => colors.character,
      PlayerColors.traveller => colors.traveller,
      PlayerColors.dead => colors.dead,
      PlayerColors.good => colors.good,
      PlayerColors.evil => colors.evil,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton(
          isExpanded: true,
          value: selectedColor,
          items: [
            for (final playerColor in PlayerColors.values)
              DropdownMenuItem(
                value: playerColor,
                child: Text(playerColor.title),
              ),
          ],
          onChanged: (value) => ref.read(selectedColorProvider.notifier).state = value!,
        ),
        ColorPicker(
          color: color,
          pickersEnabled: pickersEnabled,
          enableShadesSelection: false,
          onColorChanged: (value) {
            final gameState = ref.read(gameStateProvider);
            gameState.colors = switch (selectedColor) {
              PlayerColors.character => colors.copyWith(character: value),
              PlayerColors.traveller => colors.copyWith(traveller: value),
              PlayerColors.dead => colors.copyWith(dead: value),
              PlayerColors.good => colors.copyWith(good: value),
              PlayerColors.evil => colors.copyWith(evil: value),
            };
          },
        ),
      ],
    );
  }
}
