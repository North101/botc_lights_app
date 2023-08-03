import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/player_state.dart';
import '/providers.dart';
import '/view/popup_menu_tile.dart';
import 'providers.dart';

class PlayerInfo {
  const PlayerInfo({
    required this.gameState,
    required this.state,
    required this.index,
    required this.player,
    required this.isNominated,
  });

  final GameStateNotifier gameState;
  final GameState state;
  final int index;
  final Player player;
  final bool isNominated;

  bool get enabled => player.living != LivingState.hidden;

  void update(Player player) => gameState.updatePlayer(index, player);

  void setLiving(LivingState living) => update(Player(living, player.type, player.team));

  void setType(TypeState type) => update(Player(player.living, type, player.team));

  void setTeam(TeamState team) => update(Player(player.living, player.type, team));

  void setNominated() => gameState.nominatedPlayer = isNominated ? null : index;

  void remove() => gameState.removePlayerAt(index);

  @override
  bool operator ==(Object other) =>
      other is PlayerInfo &&
      gameState == other.gameState &&
      state == other.state &&
      index == other.index &&
      player == other.player &&
      isNominated == other.isNominated;

  @override
  int get hashCode => Object.hash(
        gameState,
        state,
        index,
        player,
        isNominated,
      );
}

final playerProvider = Provider<PlayerInfo>((ref) => throw UnimplementedError());

final backgroundColorProvider = Provider.autoDispose((ref) {
  final colors = ref.watch(colorsProvider);
  final playerInfo = ref.watch(playerProvider);
  return switch (playerInfo.state) {
    GameState.game => switch (playerInfo.player.living) {
        LivingState.hidden => colors.hidden,
        LivingState.dead => colors.dead,
        LivingState.alive => switch (playerInfo.player.type) {
            TypeState.character => colors.character,
            TypeState.traveller => colors.traveller,
          },
      },
    GameState.reveal => switch (playerInfo.player.team) {
        TeamState.hidden => colors.hidden,
        TeamState.good => colors.good,
        TeamState.evil => colors.evil,
      },
  };
}, dependencies: [
  colorsProvider,
  playerProvider,
]);

final textColorProvider = StateProvider.autoDispose((ref) {
  final backgroundColor = ref.watch(backgroundColorProvider);
  return switch (ThemeData.estimateBrightnessForColor(backgroundColor)) {
    Brightness.dark => Colors.white,
    Brightness.light => Colors.black,
  };
}, dependencies: [
  backgroundColorProvider,
]);

class PlayerWidget extends ConsumerWidget {
  static const colorBorder = Color.fromARGB(255, 255, 255, 255);
  static const playerSize = 30.0;
  static const playerBorder = 2.0;

  const PlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ref.watch(backgroundColorProvider);
    return CircleAvatar(
      backgroundColor: colorBorder,
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
    final playerInfo = ref.watch(playerProvider);
    final textColor = ref.watch(textColorProvider);
    return switch (actionBarState) {
      ActionBarState.none => switch (playerInfo.state) {
          GameState.game => const GamePlayerMenuWidget(),
          GameState.reveal => const RevealPlayerMenuWidget(),
        },
      ActionBarState.delete => IconButton(
          onPressed: () => ref.read(gameStateProvider).removePlayerAt(playerInfo.index),
          icon: Icon(Icons.delete, color: textColor),
        ),
    };
  }
}

class GamePlayerMenuWidget extends ConsumerWidget {
  const GamePlayerMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerInfo = ref.watch(playerProvider);
    final textColor = ref.watch(textColorProvider);
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final living in LivingState.values)
          PopupMenuTile(
            onTap: () => playerInfo.setLiving(living),
            icon: switch (playerInfo.player.living == living) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(living.title),
          ),
        const PopupMenuDivider(),
        for (final type in TypeState.values)
          PopupMenuTile(
            enabled: playerInfo.enabled,
            onTap: () => playerInfo.setType(type),
            icon: switch (playerInfo.player.type == type) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(type.title),
          ),
        const PopupMenuDivider(),
        PopupMenuTile(
          enabled: playerInfo.enabled,
          onTap: () => playerInfo.setNominated(),
          icon: playerInfo.isNominated ? const Icon(Icons.check) : const Icon(null),
          child: const Text('Nominated'),
        ),
        const PopupMenuDivider(),
        PopupMenuTile(
          onTap: () => playerInfo.remove(),
          icon: const Icon(null),
          child: const Text('Remove'),
        ),
      ],
      icon: switch (playerInfo.isNominated) {
        true => Icon(Icons.error, color: textColor),
        false => Text(
            '${playerInfo.index + 1}',
            style: TextStyle(color: textColor),
          ),
      },
    );
  }
}

class RevealPlayerMenuWidget extends ConsumerWidget {
  const RevealPlayerMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerInfo = ref.watch(playerProvider);
    final textColor = ref.watch(textColorProvider);
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final team in TeamState.values)
          PopupMenuTile(
            enabled: playerInfo.enabled,
            onTap: () => playerInfo.setTeam(team),
            icon: switch (playerInfo.player.team == team) {
              true => const Icon(Icons.radio_button_checked),
              false => const Icon(Icons.radio_button_off),
            },
            child: Text(team.title),
          ),
      ],
      icon: Text(
        '${playerInfo.index + 1}',
        style: TextStyle(color: textColor),
      ),
    );
  }
}
