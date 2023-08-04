import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';
import '/view/brightness_dialog.dart';
import '/view/color_dialog.dart';
import '/view/popup_menu_tile.dart';
import 'providers.dart';

class DeviceAppBar extends ConsumerWidget {
  const DeviceAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider);
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(device.name),
      actions: const [
        GameStateButton(),
        DeleteButton(),
        MoreButton(),
      ],
    );
  }
}

class GameStateButton extends ConsumerWidget {
  const GameStateButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stateProvider);
    return switch (state) {
      GameState.reveal => IconButton(
          onPressed: () => ref.read(stateProvider.notifier).update(GameState.game),
          icon: const Icon(Icons.visibility_off),
        ),
      GameState.game => IconButton(
          onPressed: () => ref.read(stateProvider.notifier).update(GameState.reveal),
          icon: const Icon(Icons.visibility),
        ),
    };
  }
}

class DeleteButton extends ConsumerWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionBarState = ref.watch(actionBarStateProvider);
    return switch (actionBarState) {
      ActionBarState.none => IconButton(
          onPressed: () {
            final actionBarState = ref.read(actionBarStateProvider.notifier);
            actionBarState.state = ActionBarState.delete;
          },
          icon: const Icon(Icons.delete),
        ),
      ActionBarState.delete => IconButton(
          onPressed: () {
            final actionBarState = ref.read(actionBarStateProvider.notifier);
            actionBarState.state = ActionBarState.none;
          },
          icon: const Icon(Icons.close),
        ),
    };
  }
}

class MoreButton extends ConsumerWidget {
  const MoreButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flip = ref.watch(flipProvider);
    return PopupMenuButton<dynamic>(
      itemBuilder: (context) => [
        PopupMenuTile(
          onTap: () => showDialog(
            context: context,
            builder: (context) => ProviderScope(
              parent: ProviderScope.containerOf(ref.context),
              child: const BrightnessDialog(),
            ),
          ),
          icon: const Icon(Icons.brightness_6),
          child: const Text('Brightness'),
        ),
        PopupMenuTile(
          onTap: () => showDialog(
            context: context,
            builder: (context) => ProviderScope(
              parent: ProviderScope.containerOf(ref.context),
              child: const ColorsDialog(),
            ),
          ),
          icon: const Icon(Icons.palette),
          child: const Text('Colors'),
        ),
        const PopupMenuDivider(),
        RadioPopupMenuTile<bool>(
          value: false,
          groupValue: flip,
          onChange: (value) => ref.read(flipProvider.notifier).state = value,
          child: const Text('Clockwise'),
        ),
        RadioPopupMenuTile<bool>(
          value: true,
          groupValue: flip,
          onChange: (value) => ref.read(flipProvider.notifier).state = value,
          child: const Text('Anti-Clockwise'),
        ),
      ],
    );
  }
}
