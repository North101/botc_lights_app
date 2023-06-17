import 'dart:typed_data';

import 'package:bits/bits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '/constants.dart';
import '/player_state.dart';

class PlayerStateNotifier extends ChangeNotifier {
  static const maxPlayers = 20;
  static const minPlayers = 5;

  PlayerStateNotifier._(this.bluetooth, this.device);

  factory PlayerStateNotifier(FlutterReactiveBle bluetooth, DiscoveredDevice device) {
    final notifier = PlayerStateNotifier._(bluetooth, device);
    notifier._sendData();
    return notifier;
  }

  final FlutterReactiveBle bluetooth;
  final DiscoveredDevice device;

  final players = [
    for (var i = 0; i < 7; i++) const Player(AliveState.alive, TypeState.player),
  ];
  var nominatedPlayer = -1;

  bool get hasMaxPlayers => players.length >= maxPlayers;

  void addPlayer() {
    players.add(const Player(AliveState.alive, TypeState.player));
    _notify();
  }

  void removePlayerAt(int index) {
    players.removeAt(index);
    _notify();
  }

  void updatePlayer(int index, Player player) {
    players[index] = player;
    _notify();
  }

  void nominatePlayer(int? index) {
    nominatedPlayer = index ?? -1;
    _notify();
  }

  Future<void> _sendData() {
    final characteristic = QualifiedCharacteristic(
      serviceId: uartServiceId,
      characteristicId: uartRxServiceId,
      deviceId: device.id,
    );
    return bluetooth.writeCharacteristicWithoutResponse(characteristic, value: toBytes());
  }

  void _notify() {
    notifyListeners();
    _sendData();
  }

  Uint8List toBytes() {
    final writer = BitBuffer().writer();
    for (final player in players) {
      player.writeBits(writer);
    }
    for (var i = players.length; i < maxPlayers; i++) {
      const Player(AliveState.hidden, TypeState.player).writeBits(writer);
    }
    writer.writeInt(nominatedPlayer + 1, signed: false, bits: (maxPlayers + 1).bitLength);
    return writer.buffer.toUInt8List();
  }
}
