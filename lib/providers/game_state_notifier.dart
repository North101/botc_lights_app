import 'dart:typed_data';

import 'package:bits/bits.dart';
import 'package:botc_lights_app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '/constants.dart';
import '/player_state.dart';

enum GameState {
  game,
  reveal,
}

class GameStateNotifier extends ChangeNotifier {
  static const maxPlayers = 20;
  static const minPlayers = 5;

  GameStateNotifier(this.bluetooth, this.device);

  final FlutterReactiveBle bluetooth;
  final DiscoveredDevice device;

  var state = GameState.game;
  final players = [
    for (var i = 0; i < 7; i++) const Player(
      LivingState.alive,
      TypeState.player,
      TeamState.hidden,
    ),
  ];
  int? nominatedPlayer;

  bool get hasMaxPlayers => players.length >= maxPlayers;

  void setGameState(GameState state) {
    this.state = state;
    notifyListeners();
    writeStateData();
  }

  void addPlayer() {
    players.add(const Player(
      LivingState.alive,
      TypeState.player,
      TeamState.hidden,
    ));
    notifyListeners();
    writePlayerCharacteristics();
  }

  void removePlayerAt(int index) {
    players.removeAt(index);
    notifyListeners();
    writePlayerCharacteristics();
  }

  void updatePlayer(int index, Player player) {
    players[index] = player;
    notifyListeners();
    writePlayerCharacteristics();
  }

  void nominatePlayer(int? index) {
    nominatedPlayer = index;
    notifyListeners();
    writePlayerNominatedData();
  }

  Future<void> writeStateData() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: stateCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packStateBytes());
  }

  Uint8List packStateBytes() {
    final writer = BitBuffer().writer();
    writer.writeInt(state.index, signed: false, bits: GameState.values.last.index.bitLength);
    return writer.buffer.toUInt8List();
  }

  Future<void> writePlayerCharacteristics() async {
    await Future.wait([
      _writePlayerAliveCharacteristic(),
      _writePlayerTypeCharacteristic(),
      _writePlayerTeamCharacteristic(),
    ]);
  }

  Future<void> _writePlayerAliveCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerLivingCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packPlayerAliveBytes());
  }

  Uint8List packPlayerAliveBytes() {
    final writer = BitBuffer().writer();
    for (final player in players) {
      writer.writeEnum<LivingState>(LivingState.values, player.living);
    }
    for (var i = players.length; i < maxPlayers; i++) {
      writer.writeEnum<LivingState>(LivingState.values, LivingState.hidden);
    }
    return writer.buffer.toUInt8List();
  }

  Future<void> _writePlayerTypeCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerTypeCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packPlayerTypeBytes());
  }

  Uint8List packPlayerTypeBytes() {
    final writer = BitBuffer().writer();
    for (final player in players) {
      writer.writeEnum<TypeState>(TypeState.values, player.type);
    }
    for (var i = players.length; i < maxPlayers; i++) {
      writer.writeEnum<TypeState>(TypeState.values, TypeState.player);
    }
    return writer.buffer.toUInt8List();
  }

  Future<void> _writePlayerTeamCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerTeamCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packPlayerTeamBytes());
  }

  Uint8List packPlayerTeamBytes() {
    final writer = BitBuffer().writer();
    for (final player in players) {
      writer.writeEnum<TeamState>(TeamState.values, player.team);
    }
    for (var i = players.length; i < maxPlayers; i++) {
      writer.writeEnum<TeamState>(TeamState.values, TeamState.hidden);
    }
    return writer.buffer.toUInt8List();
  }

  Future<void> writePlayerNominatedData() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerNominatedCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packGameNominatedBytes());
  }

  Uint8List packGameNominatedBytes() {
    final writer = BitBuffer().writer();
    final value = (nominatedPlayer ?? -1) + 1;
    writer.writeInt(value, signed: false, bits: (maxPlayers + 1).bitLength);
    return writer.buffer.toUInt8List();
  }
}
