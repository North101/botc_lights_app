import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/player_state.dart';
import '/providers.dart';
import '/view/popup_menu_tile.dart';
import 'providers.dart';

final playerIndexProvider = Provider.autoDispose<int>((ref) => throw UnimplementedError());

final playerProvider = Provider.autoDispose((ref) {
  final playerList = ref.watch(playerListProvider);
  final playerIndex = ref.watch(playerIndexProvider);
  return playerList[playerIndex];
}, dependencies: [
  playerListProvider,
  playerIndexProvider,
]);

final isNominatedProvider = Provider.autoDispose((ref) {
  final playerIndex = ref.watch(playerIndexProvider);
  final nominatedPlayer = ref.watch(nominatedPlayerProvider);
  return playerIndex == nominatedPlayer;
}, dependencies: [
  playerIndexProvider,
  nominatedPlayerProvider,
]);

final backgroundColorProvider = Provider.autoDispose((ref) {
  final state = ref.watch(stateProvider);
  final colors = ref.watch(colorsProvider);
  final player = ref.watch(playerProvider);
  return switch (state) {
    GameState.game => switch (player.living) {
        LivingState.hidden => colors.hidden,
        LivingState.dead => colors.dead,
        LivingState.alive => switch (player.type) {
            TypeState.character => colors.character,
            TypeState.traveller => colors.traveller,
          },
      },
    GameState.reveal => switch (player.team) {
        TeamState.hidden => colors.hidden,
        TeamState.good => colors.good,
        TeamState.evil => colors.evil,
      },
  };
}, dependencies: [
  stateProvider,
  colorsProvider,
  playerProvider,
  isNominatedProvider,
]);

final brightnessColorProvider = StateProvider.autoDispose((ref) {
  final backgroundColor = ref.watch(backgroundColorProvider);
  return switch (ThemeData.estimateBrightnessForColor(backgroundColor)) {
    Brightness.dark => Colors.white,
    Brightness.light => Colors.black,
  };
}, dependencies: [
  backgroundColorProvider,
]);

class PlayerWidget extends ConsumerWidget {
  static const playerSize = 30.0;
  static const playerBorder = 2.0;

  const PlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNominated = ref.watch(isNominatedProvider);
    final backgroundColor = ref.watch(backgroundColorProvider);
    final brightnessColor = ref.watch(brightnessColorProvider);
    return CircleAvatar(
      backgroundColor: isNominated ? Colors.red : brightnessColor,
      radius: playerSize,
      child: CircleAvatar(
        backgroundColor: backgroundColor,
        radius: playerSize - playerBorder,
        child: const RotatedPlayerChild(PlayerMenuWidget()),
      ),
    );
  }
}

class RotatedPlayerChild extends ConsumerWidget {
  const RotatedPlayerChild(
    this.child, {
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flip = ref.watch(flipProvider);
    final angle = ref.watch(finalAngleProvider);
    return Transform.flip(
      flipX: flip,
      child: Transform.rotate(
        angle: flip ? angle : -angle,
        child: child,
      ),
    );
  }
}

class PlayerMenuWidget extends ConsumerWidget {
  const PlayerMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionBarState = ref.watch(actionBarStateProvider);
    final state = ref.watch(stateProvider);
    final index = ref.watch(playerIndexProvider);
    final brightnessColor = ref.watch(brightnessColorProvider);
    return switch (actionBarState) {
      ActionBarState.none => switch (state) {
          GameState.game => const GamePlayerMenuWidget(),
          GameState.reveal => const RevealPlayerMenuWidget(),
        },
      ActionBarState.delete => IconButton(
          onPressed: () => ref.read(playerListProvider.notifier).remove(index),
          icon: Icon(Icons.delete, color: brightnessColor),
        ),
    };
  }
}

class GamePlayerMenuWidget extends ConsumerWidget {
  const GamePlayerMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(playerIndexProvider);
    final player = ref.watch(playerProvider);
    final isNominated = ref.watch(isNominatedProvider);
    final brightnessColor = ref.watch(brightnessColorProvider);
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final living in LivingState.values)
          PopupMenuTile(
            onTap: () => ref.read(playerListProvider.notifier).update(index, player.copyWith(living: living)),
            icon: switch (player.living == living) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(living.title),
          ),
        const PopupMenuDivider(),
        for (final type in TypeState.values)
          PopupMenuTile(
            onTap: () => ref.read(playerListProvider.notifier).update(index, player.copyWith(type: type)),
            icon: switch (player.type == type) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(type.title),
          ),
        const PopupMenuDivider(),
        PopupMenuTile(
          enabled: !player.isHidden,
          onTap: () => ref.read(nominatedPlayerProvider.notifier).update(isNominated ? null : index),
          icon: isNominated ? const Icon(Icons.check) : const Icon(null),
          child: const Text('Nominated'),
        ),
        const PopupMenuDivider(),
        PopupMenuTile(
          onTap: () => ref.read(playerListProvider.notifier).remove(index),
          icon: const Icon(null),
          child: const Text('Remove'),
        ),
      ],
      icon: Text(
        '${index + 1}',
        style: TextStyle(color: brightnessColor),
      ),
    );
  }
}

class RevealPlayerMenuWidget extends ConsumerWidget {
  const RevealPlayerMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(playerIndexProvider);
    final player = ref.watch(playerProvider);
    final brightnessColor = ref.watch(brightnessColorProvider);
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final team in TeamState.values)
          PopupMenuTile(
            enabled: !player.isHidden,
            onTap: () => ref.read(playerListProvider.notifier).update(index, player.copyWith(team: team)),
            icon: switch (player.team == team) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(team.title),
          ),
      ],
      icon: Text(
        '${index + 1}',
        style: TextStyle(color: brightnessColor),
      ),
    );
  }
}
