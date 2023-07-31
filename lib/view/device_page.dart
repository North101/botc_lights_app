import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';
import '/player_state.dart';
import '/providers.dart';
import 'default_scaffold.dart';
import 'setup_page.dart';

const playerSize = 30.0;

final deviceProvider = Provider<DiscoveredDevice>((ref) => throw UnimplementedError());

final deviceConnectionProvider = StreamProvider.autoDispose((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return bluetooth.connectToAdvertisingDevice(
    id: device.id,
    prescanDuration: const Duration(seconds: 2),
    withServices: [service],
    servicesWithCharacteristicsToDiscover: {
      service: [
        stateCharacteristic,
        playerLivingCharacteristic,
        playerTypeCharacteristic,
        playerTeamCharacteristic,
        playerNominatedCharacteristic,
      ]
    },
  );
}, dependencies: [
  deviceProvider,
]);

enum ActionBarState {
  none,
  delete,
}

final actionBarStateProvider = StateProvider.autoDispose((ref) => ActionBarState.none);

final gameStateProvider = ChangeNotifierProvider<GameStateNotifier>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return GameStateNotifier(bluetooth, device);
}, dependencies: [
  bluetoothProvider,
  deviceProvider,
]);

final alivePlayerCountProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider).players;
  return gameState.where((e) => e.living == LivingState.alive).length;
}, dependencies: [
  gameStateProvider,
]);

final playerCountProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider).players;
  return gameState.where((e) => e.living != LivingState.hidden && e.type == TypeState.player).length;
}, dependencies: [
  gameStateProvider,
]);

final travellerCountProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider).players;
  return gameState.where((e) => e.living != LivingState.hidden && e.type == TypeState.traveller).length;
}, dependencies: [
  gameStateProvider,
]);

final finalAngleProvider = StateProvider((ref) => -pi / 2);
final upsetAngleProvider = StateProvider((ref) => 0.0);
final flipProvider = StateProvider((ref) => false);

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  static Widget withOverrides({
    required DiscoveredDevice device,
  }) =>
      ProviderScope(
        overrides: [
          deviceProvider.overrideWithValue(device),
        ],
        child: const DevicePage(),
      );

  @override
  Widget build(BuildContext context) {
    return const SetupPage(child: ConnectionWidget());
  }
}

class ConnectionWidget extends ConsumerWidget {
  const ConnectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(deviceConnectionProvider, (previous, next) {
      next.whenData((value) {
        if (value.connectionState == DeviceConnectionState.connected) {
          final notifier = ref.read(gameStateProvider);
          notifier.writeStateData();
          notifier.writePlayerCharacteristics();
          notifier.writePlayerNominatedData();
        } else if (value.connectionState == DeviceConnectionState.disconnected) {
          ref.invalidate(deviceConnectionProvider);
        }
      });
    });

    final deviceConnection = ref.watch(deviceConnectionProvider);
    return deviceConnection.when(
      loading: () => const DefaultLoadingScaffold(),
      error: (error, stackTrace) => DefaultErrorScaffold(
        error: error,
        stackTrace: stackTrace,
      ),
      data: (data) => switch (data.connectionState) {
        DeviceConnectionState.connecting => const DefaultLoadingScaffold(),
        DeviceConnectionState.connected => const ConnectedWidget(),
        DeviceConnectionState.disconnecting => const DefaultLoadingScaffold(),
        DeviceConnectionState.disconnected => const DisconnectedWidget(),
      },
    );
  }
}

class ConnectedWidget extends ConsumerWidget {
  const ConnectedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider);
    final actionBarState = ref.watch(actionBarStateProvider);
    final gameState = ref.watch(gameStateProvider);
    final flip = ref.watch(flipProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(device.name),
        actions: [
          if (gameState.state == GameState.reveal)
            IconButton(
              onPressed: () => gameState.setGameState(GameState.game),
              icon: const Icon(Icons.visibility_off),
            )
          else if (gameState.state == GameState.game)
            IconButton(
              onPressed: () => gameState.setGameState(GameState.reveal),
              icon: const Icon(Icons.visibility),
            ),
          IconButton(
            onPressed: () => ref.read(flipProvider.notifier).state = !flip,
            icon: flip ? const Icon(Icons.rotate_left) : const Icon(Icons.rotate_right),
          ),
          switch (actionBarState) {
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
          },
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: TownsquareContainer()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !gameState.hasMaxPlayers ? gameState.addPlayer : null,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DisconnectedWidget extends ConsumerWidget {
  const DisconnectedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text('Disconnected', style: Theme.of(context).textTheme.bodyLarge)),
          Center(
            child: ElevatedButton(
              onPressed: () => ref.invalidate(deviceConnectionProvider),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class TownsquareContainer extends StatelessWidget {
  const TownsquareContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: AlignmentDirectional.center,
      children: [
        TownsquareFlipAnimationBuilder(),
        TownsquareInfoWidget(),
      ],
    );
  }
}

class TownsquareFlipAnimationBuilder extends ConsumerWidget {
  const TownsquareFlipAnimationBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flip = ref.watch(flipProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (widget, animation) {
        final rotateAnimation = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnimation,
          child: widget,
          builder: (context, widget) {
            final isUnder = widget?.key != const ValueKey(true);
            final tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            final value = isUnder ? min(rotateAnimation.value, pi / 2) : rotateAnimation.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt * (isUnder ? -1.0 : 1.0)),
              alignment: Alignment.center,
              child: widget,
            );
          },
        );
      },
      layoutBuilder: (widget, list) => Stack(children: [
        if (widget != null) widget,
        ...list,
      ]),
      switchInCurve: Curves.easeInBack,
      switchOutCurve: Curves.easeInBack.flipped,
      child: Transform.flip(
        key: ValueKey(flip),
        flipX: flip,
        child: ProviderScope(
          overrides: [
            flipProvider.overrideWith((ref) => flip),
          ],
          child: const TownsquareGestureDetector(),
        ),
      ),
    );
  }
}

class TownsquareGestureDetector extends ConsumerWidget {
  const TownsquareGestureDetector({super.key});

  onPanStart(WidgetRef ref, Offset offset, DragStartDetails details) {
    final touchPositionFromCenter = details.localPosition - offset;
    final finalAngle = ref.read(finalAngleProvider);
    ref.read(upsetAngleProvider.notifier).state = finalAngle - touchPositionFromCenter.direction;
  }

  onPanUpdate(WidgetRef ref, Offset offset, DragUpdateDetails details) {
    final touchPositionFromCenter = details.localPosition - offset;
    final upsetAngle = ref.read(upsetAngleProvider);
    ref.read(finalAngleProvider.notifier).state = touchPositionFromCenter.direction + upsetAngle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight);
      final offset = Offset(size / 2, size / 2);
      return SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onPanStart: (details) => onPanStart(ref, offset, details),
          onPanUpdate: (details) => onPanUpdate(ref, offset, details),
          child: const TownsquareRotated(),
        ),
      );
    });
  }
}

class TownsquareRotated extends ConsumerWidget {
  const TownsquareRotated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angle = ref.watch(finalAngleProvider);
    return Transform.rotate(
      angle: angle,
      child: const Townsquare(),
    );
  }
}

class Townsquare extends ConsumerWidget {
  const Townsquare({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final distanceAngle = 360 / gameState.players.length;
    return Stack(children: [
      for (final (index, player) in gameState.players.indexed)
        Align(
          alignment: Alignment(
            cos(distanceAngle * index * (pi / 180)),
            sin(distanceAngle * index * (pi / 180)),
          ),
          child: PlayerWidget(
            index: index,
            player: player,
            nominated: gameState.nominatedPlayer == index,
            state: gameState.state,
          ),
        ),
    ]);
  }
}

class TownsquareInfoWidget extends ConsumerWidget {
  const TownsquareInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliveCount = ref.watch(alivePlayerCountProvider);
    final playerCount = ref.watch(playerCountProvider);
    final travellerCount = ref.watch(travellerCountProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$aliveCount / ${playerCount + travellerCount}'),
          if (playerCount >= 5 && playerCount <= 20) PlayerInfoWidget(playerCount),
        ],
      ),
    );
  }
}

class PlayerInfoWidget extends StatelessWidget {
  const PlayerInfoWidget(this.playerCount, {super.key});

  final int playerCount;

  int get townsfolk => switch (playerCount) {
        5 || 6 => 3,
        7 || 8 || 9 => 5,
        10 || 11 || 12 => 7,
        13 || 14 || 15 => 9,
        _ => 0,
      };

  int get outsiders => switch (playerCount) {
        5 || 7 || 10 || 13 => 0,
        6 || 8 || 11 || 14 => 1,
        9 || 12 || 15 => 2,
        _ => 0,
      };

  int get minions => switch (playerCount) {
        5 || 6 || 7 || 8 || 9 => 1,
        10 || 11 || 12 => 2,
        13 || 14 || 15 => 0,
        _ => 0,
      };

  int get demons => 1;

  @override
  Widget build(BuildContext context) {
    return Text('$townsfolk / $outsiders / $minions / $demons');
  }
}

class PlayerWidget extends ConsumerWidget {
  static const colorBorder = Color.fromARGB(255, 255, 255, 255);
  static const colorHidden = Color.fromARGB(255, 000, 000, 000);

  static const colorPlayerAlive = Color.fromARGB(255, 244, 241, 234);
  static const colorTravellerAlive = Color.fromARGB(255, 205, 170, 056);
  static const colorDead = Color.fromARGB(255, 063, 025, 066);

  static const colorGood = Color.fromARGB(255, 082, 182, 255);
  static const colorEvil = Color.fromARGB(255, 255, 54, 54);

  const PlayerWidget({
    required this.index,
    required this.player,
    required this.nominated,
    required this.state,
    super.key,
  });

  final int index;
  final Player player;
  final bool nominated;
  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionBarState = ref.watch(actionBarStateProvider);
    return CircleAvatar(
      backgroundColor: colorBorder,
      radius: playerSize,
      child: CircleAvatar(
        backgroundColor: switch (state) {
          GameState.game => switch (player.living) {
              LivingState.hidden => colorHidden,
              LivingState.dead => colorDead,
              LivingState.alive => switch (player.type) {
                  TypeState.player => colorPlayerAlive,
                  TypeState.traveller => colorTravellerAlive,
                },
            },
          GameState.reveal => switch (player.team) {
              TeamState.hidden => colorHidden,
              TeamState.good => colorGood,
              TeamState.evil => colorEvil,
            }
        },
        radius: playerSize - 2,
        child: RotatedPlayerChild(switch (actionBarState) {
          ActionBarState.none => switch (state) {
              GameState.game => GamePlayerMenuWidget(
                  index: index,
                  value: player,
                  nominated: nominated,
                ),
              GameState.reveal => RevealPlayerMenuWidget(
                  index: index,
                  value: player,
                ),
            },
          ActionBarState.delete => IconButton(
              onPressed: () {
                final gameState = ref.read(gameStateProvider);
                gameState.removePlayerAt(index);
              },
              icon: const Icon(Icons.delete, color: Colors.black),
            )
        }),
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

class GamePlayerMenuWidget extends ConsumerWidget {
  const GamePlayerMenuWidget({
    required this.index,
    required this.value,
    required this.nominated,
    super.key,
  });

  final int index;
  final Player value;
  final bool nominated;

  GameStateNotifier gameState(WidgetRef ref) => ref.read(gameStateProvider);

  bool get enabled => value.living != LivingState.hidden;

  void update(WidgetRef ref, Player player) => gameState(ref).updatePlayer(index, player);

  void setLiving(WidgetRef ref, LivingState living) => update(ref, Player(living, value.type, value.team));

  void setType(WidgetRef ref, TypeState type) => update(ref, Player(value.living, type, value.team));

  void setNominated(WidgetRef ref) => gameState(ref).nominatePlayer(nominated ? null : index);

  void remove(WidgetRef ref) => gameState(ref).removePlayerAt(index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final living in LivingState.values)
          PopupMenuItem(
            onTap: () => setLiving(ref, living),
            child: ListTile(
              title: Text(living.title),
              leading: switch (value.living == living) {
                true => const Icon(Icons.radio_button_checked),
                false => const Icon(Icons.radio_button_off),
              },
            ),
          ),
        const PopupMenuDivider(),
        for (final type in TypeState.values)
          PopupMenuItem(
            enabled: enabled,
            onTap: () => setType(ref, type),
            child: ListTile(
              enabled: enabled,
              title: Text(type.title),
              leading: switch (value.type == type) {
                true => const Icon(Icons.radio_button_checked),
                false => const Icon(Icons.radio_button_off),
              },
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: enabled,
          onTap: () => setNominated(ref),
          child: ListTile(
            enabled: enabled,
            title: const Text('Nominated'),
            leading: nominated ? const Icon(Icons.check) : const Icon(null),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => remove(ref),
          child: const ListTile(
            leading: Icon(null),
            title: Text('Remove'),
          ),
        ),
      ],
      child: switch (nominated) {
        true => switch (value.living) {
            LivingState.alive => const Icon(Icons.error, color: Colors.black),
            _ => const Icon(Icons.error, color: Colors.white),
          },
        false => Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.black),
          ),
      },
    );
  }
}

class RevealPlayerMenuWidget extends ConsumerWidget {
  const RevealPlayerMenuWidget({
    required this.index,
    required this.value,
    super.key,
  });

  final int index;
  final Player value;

  GameStateNotifier gameState(WidgetRef ref) => ref.read(gameStateProvider);

  bool get enabled => value.living != LivingState.hidden;

  void update(WidgetRef ref, Player player) => gameState(ref).updatePlayer(index, player);

  void setTeam(WidgetRef ref, TeamState team) => update(ref, Player(value.living, value.type, team));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        for (final team in TeamState.values)
          PopupMenuItem(
            enabled: enabled,
            onTap: () => setTeam(ref, team),
            child: ListTile(
              enabled: enabled,
              title: Text(team.title),
              leading: switch (value.team == team) {
                true => const Icon(Icons.radio_button_checked),
                false => const Icon(Icons.radio_button_off),
              },
            ),
          ),
      ],
      icon: const SizedBox(),
    );
  }
}
