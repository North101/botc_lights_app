import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';
import '/view/default_scaffold.dart';
import '/view/setup_page.dart';
import 'appbar.dart';
import 'body.dart';
import 'fab.dart';
import 'providers.dart';

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
          final playerList = ref.read(playerListProvider.notifier);
          final nominatedPlayer = ref.read(nominatedPlayerProvider.notifier);
          final colors = ref.read(colorsProvider.notifier);
          final state = ref.read(stateProvider.notifier);
          final brightness = ref.read(brightnessProvider.notifier);
          Future.wait([
            playerList.writeCharacteristics(),
            nominatedPlayer.writeCharacteristic(),
            colors.writeCharacteristic(),
            state.writeCharacteristic(),
            brightness.writeCharacteristic(),
          ]);
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
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: DeviceAppBar(),
      ),
      body: DeviceBody(),
      floatingActionButton: DeviceFloatingActionButton(),
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
