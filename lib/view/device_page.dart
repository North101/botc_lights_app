import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';
import '/player_state.dart';
import '/providers.dart';
import '/view/default_scaffold.dart';
import 'setup_page.dart';

const playerSize = 30.0;

final deviceProvider = Provider<DiscoveredDevice>((ref) => throw UnimplementedError());

final deviceConnectionProvider = StreamProvider.autoDispose((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return bluetooth.connectToAdvertisingDevice(
    id: device.id,
    prescanDuration: const Duration(seconds: 2),
    withServices: [
      uartServiceId,
      uartRxServiceId,
    ],
  );
}, dependencies: [
  deviceProvider,
]);

enum ActionBarState {
  none,
  delete,
}

final actionBarStateProvider = StateProvider.autoDispose((ref) => ActionBarState.none);

final playerStateProvider = ChangeNotifierProvider.autoDispose<PlayerStateNotifier>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return PlayerStateNotifier(bluetooth, device);
}, dependencies: [
  bluetoothProvider,
  deviceProvider,
]);

final alivePlayerCountProvider = Provider.autoDispose((ref) {
  final playerState = ref.watch(playerStateProvider).players;
  return playerState.where((e) => e.alive == AliveState.alive).length;
}, dependencies: [
  playerStateProvider,
]);

final playerCountProvider = Provider.autoDispose((ref) {
  final playerState = ref.watch(playerStateProvider).players;
  return playerState.where((e) => e.alive != AliveState.hidden && e.type == TypeState.player).length;
}, dependencies: [
  playerStateProvider,
]);

final travellerCountProvider = Provider.autoDispose((ref) {
  final playerState = ref.watch(playerStateProvider).players;
  return playerState.where((e) => e.alive != AliveState.hidden && e.type == TypeState.traveller).length;
}, dependencies: [
  playerStateProvider,
]);

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
    final playerState = ref.watch(playerStateProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(device.name),
        actions: [
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
        child: Center(child: TownsquareWidget()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !playerState.hasMaxPlayers ? playerState.addPlayer : null,
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

class TownsquareWidget extends ConsumerWidget {
  const TownsquareWidget({super.key});

  double left(double radius, int index, int length) {
    return radius + (radius * sin(pi * 2 * (index / length * 360) / 360));
  }

  double top(double radius, int index, int length) {
    return radius + (radius * cos(pi * 2 * (180 + (index / length * 360)) / 360));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final radius = (size / 2) - playerSize;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(children: [
            for (final (index, player) in playerState.players.indexed)
              Positioned(
                left: left(radius, index, playerState.players.length),
                top: top(radius, index, playerState.players.length),
                child: PlayerWidget(
                  index: index,
                  player: player,
                  nominated: playerState.nominatedPlayer == index,
                ),
              ),
            const TownsquareInfoWidget(),
          ]),
        );
      },
    );
  }
}

class TownsquareInfoWidget extends ConsumerWidget {
  const TownsquareInfoWidget({super.key});

  int townsfolk(totalPlayerCount) => switch (totalPlayerCount) {
        5 || 6 => 3,
        7 || 8 || 9 => 5,
        10 || 11 || 12 => 7,
        13 || 14 || 15 => 9,
        _ => 0,
      };

  int outsiders(totalPlayerCount) => switch (totalPlayerCount) {
        6 || 8 || 11 || 14 => 1,
        9 || 12 || 15 => 2,
        _ => 0,
      };

  int minions(totalPlayerCount) => switch (totalPlayerCount) {
        5 || 6 || 7 || 8 || 9 => 1,
        10 || 11 || 12 => 2,
        13 || 14 || 15 => 0,
        _ => 0,
      };

  int demons(totalPlayerCount) => 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliveCount = ref.watch(alivePlayerCountProvider);
    final playerCount = ref.watch(playerCountProvider);
    final travellerCount = ref.watch(travellerCountProvider);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$aliveCount / ${playerCount + travellerCount}'),
        Text(
            '${townsfolk(playerCount)} / ${outsiders(playerCount)} / ${minions(playerCount)} / ${demons(playerCount)}'),
      ]),
    );
  }
}

class PlayerWidget extends ConsumerWidget {
  static const colorBorder = Color.fromARGB(255, 255, 255, 255);
  static const colorPlayerAlive = Color.fromARGB(255, 244, 241, 234);
  static const colorTravellerAlive = Color.fromARGB(255, 205, 170, 056);
  static const colorDeadVote = Color.fromARGB(255, 063, 025, 066);
  static const colorDeadNoVote = Color.fromARGB(255, 114, 026, 022);
  static const colorHidden = Color.fromARGB(255, 000, 000, 000);

  const PlayerWidget({
    required this.index,
    required this.player,
    required this.nominated,
    super.key,
  });

  final int index;
  final Player player;
  final bool nominated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionBarState = ref.watch(actionBarStateProvider);
    return CircleAvatar(
      backgroundColor: colorBorder,
      radius: playerSize,
      child: CircleAvatar(
        backgroundColor: switch (player.alive) {
          AliveState.hidden => colorHidden,
          AliveState.deadNoVote => colorDeadNoVote,
          AliveState.deadVote => colorDeadVote,
          AliveState.alive => switch (player.type) {
              TypeState.player => colorPlayerAlive,
              TypeState.traveller => colorTravellerAlive,
            },
        },
        radius: playerSize - 2,
        child: switch (actionBarState) {
          ActionBarState.none => PlayerMenuWidget(
              index: index,
              value: player,
              nominated: nominated,
            ),
          ActionBarState.delete => IconButton(
              onPressed: () {
                final playerState = ref.read(playerStateProvider);
                playerState.removePlayerAt(index);
              },
              icon: const Icon(Icons.delete),
            )
        },
      ),
    );
  }
}

class PlayerMenuWidget extends ConsumerWidget {
  const PlayerMenuWidget({
    required this.index,
    required this.value,
    required this.nominated,
    super.key,
  });

  final int index;
  final Player value;
  final bool nominated;

  PlayerStateNotifier playerState(WidgetRef ref) => ref.read(playerStateProvider);

  bool get enabled => value.alive != AliveState.hidden;

  void hide(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(AliveState.hidden, value.type));

  void deadNoVote(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(AliveState.deadNoVote, value.type));

  void deadVote(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(AliveState.deadVote, value.type));

  void alive(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(AliveState.alive, value.type));

  void player(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(value.alive, TypeState.player));

  void traveller(WidgetRef ref) => playerState(ref).updatePlayer(index, Player(value.alive, TypeState.traveller));

  void nominate(WidgetRef ref) => playerState(ref).nominatePlayer(nominated ? null : index);

  void remove(WidgetRef ref) => playerState(ref).removePlayerAt(index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<PopupMenuEntry>(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => alive(ref),
          child: ListTile(
            title: const Text('Alive'),
            leading: value.alive == AliveState.alive
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        PopupMenuItem(
          onTap: () => deadVote(ref),
          child: ListTile(
            title: const Text('Dead (Vote)'),
            leading: value.alive == AliveState.deadVote
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        PopupMenuItem(
          onTap: () => deadNoVote(ref),
          child: ListTile(
            title: const Text('Dead (No Vote)'),
            leading: value.alive == AliveState.deadNoVote
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        PopupMenuItem(
          onTap: () => hide(ref),
          child: ListTile(
            title: const Text('Hide'),
            leading: value.alive == AliveState.hidden
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: enabled,
          onTap: () => player(ref),
          child: ListTile(
            enabled: enabled,
            title: const Text('Player'),
            leading: value.type == TypeState.player
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        PopupMenuItem(
          enabled: enabled,
          onTap: () => traveller(ref),
          child: ListTile(
            enabled: enabled,
            title: const Text('Traveller'),
            leading: value.type == TypeState.traveller
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_off),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: enabled,
          onTap: () => nominate(ref),
          child: ListTile(
            enabled: enabled,
            title: const Text('Nominate'),
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
      icon: switch (nominated) {
        true => switch (value.alive) {
            AliveState.alive => const Icon(Icons.error, color: Colors.black),
            _ => const Icon(Icons.error, color: Colors.white),
          },
        false => const SizedBox(),
      },
    );
  }
}
