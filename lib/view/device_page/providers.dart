import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/player_state.dart';
import '/constants.dart';
import '/providers.dart';

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
        brightnessCharacteristic,
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
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return GameStateNotifier(
    sharedPreferences,
    bluetooth,
    device,
  );
}, dependencies: [
  sharedPreferencesProvider,
  bluetoothProvider,
  deviceProvider,
]);

final playerListProvider = Provider((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.players;
});

final alivePlayerCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living == LivingState.alive).length;
}, dependencies: [
  gameStateProvider,
]);

final characterCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living != LivingState.hidden && e.type == TypeState.character).length;
}, dependencies: [
  gameStateProvider,
]);

final travellerCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living != LivingState.hidden && e.type == TypeState.traveller).length;
}, dependencies: [
  gameStateProvider,
]);

final finalAngleProvider = StateProvider((ref) => 0.0);
final upsetAngleProvider = StateProvider((ref) => 0.0);
final flipProvider = StateProvider((ref) => false);
