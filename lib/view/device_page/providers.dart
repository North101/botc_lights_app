import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';
import '/providers.dart';

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
        brightnessCharacteristic,
        colorsCharacteristic,
      ]
    },
  );
}, dependencies: [
  bluetoothProvider,
  deviceProvider,
]);

enum ActionBarState {
  none,
  delete,
}

final actionBarStateProvider = StateProvider.autoDispose((ref) => ActionBarState.none);

final finalAngleProvider = StateProvider((ref) => 0.0);
final upsetAngleProvider = StateProvider((ref) => 0.0);
final flipProvider = StateProvider((ref) => false);
