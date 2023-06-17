import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '/providers.dart';
import '/view/default_scaffold.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    return setup.when(
      loading: () => const DefaultLoadingScaffold(),
      error: (error, stackTrace) => DefaultErrorScaffold(
        error: error,
        stackTrace: stackTrace,
      ),
      data: (data) => switch (data) {
        PermissionDeniedResult() => DefaultScaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data.permission == Permission.bluetoothScan)
                  const Center(child: Text('Bluetooth Scan permissions are required')),
                if (data.permission == Permission.bluetoothConnect)
                  const Center(child: Text('Bluetooth Connect permissions are required')),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    ref.invalidate(deniedPermissionProvider);
                  },
                  child: const Text('Open App Settings'),
                ),
              ],
            ),
          ),
        BluetoothStatusResult() => switch (data.status) {
            BleStatus.unknown => const DefaultLoadingScaffold(),
            BleStatus.unsupported => const DefaultScaffold(
                body: Center(child: Text('Bluetooth is not supported')),
              ),
            BleStatus.unauthorized => DefaultScaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(child: Text('Bluetooth is off')),
                    ElevatedButton(
                      onPressed: () async {
                        await openAppSettings();
                        ref.invalidate(setupProvider);
                      },
                      child: const Text('Open App Settings'),
                    ),
                  ],
                ),
              ),
            BleStatus.poweredOff => DefaultScaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(child: Text('Bluetooth is off')),
                    ElevatedButton(
                      onPressed: () async {
                        await AppSettings.openBluetoothSettings();
                        ref.invalidate(setupProvider);
                      },
                      child: const Text('Open Bluetooth Settings'),
                    ),
                  ],
                ),
              ),
            BleStatus.locationServicesDisabled => DefaultScaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(child: Text('Location services are disabled')),
                    ElevatedButton(
                      onPressed: () async {
                        await AppSettings.openLocationSettings();
                        ref.invalidate(setupProvider);
                      },
                      child: const Text('Open Location Settings'),
                    ),
                  ],
                ),
              ),
            BleStatus.ready => child,
          },
      },
    );
  }
}
