import 'dart:typed_data';

import 'package:bits/bits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/constants.dart';
import '/player_state.dart';
import '/util.dart';

enum GameState {
  game,
  reveal,
}

class GameStateNotifier extends ChangeNotifier {
  static const maxCharacters = 15;
  static const minCharacters = 5;
  static const maxTravellers = 5;
  static const minTravellers = 0;
  static const maxPlayers = maxCharacters + maxTravellers;
  static const minPlayers = minCharacters + minTravellers;
  static const maxBrightness = 100;
  static const minBrightness = 0;
  static const defaultBrightness = 20;

  GameStateNotifier(this.sharedPreferences, this.bluetooth, this.device)
      : _brightness = (sharedPreferences.getInt('brightness') ?? defaultBrightness).clamp(minBrightness, maxBrightness);

  final SharedPreferences sharedPreferences;
  final FlutterReactiveBle bluetooth;
  final DiscoveredDevice device;

  GameState _state = GameState.game;
  var players = [
    for (var i = 0; i < 7; i++)
      const Player(
        LivingState.alive,
        TypeState.character,
        TeamState.hidden,
      ),
  ];
  int? _nominatedPlayer;
  int _brightness = 20;

  bool get hasMaxPlayers => players.length >= maxPlayers;

  int get brightness => _brightness;

  set brightness(int brightness) {
    _brightness = brightness.clamp(minBrightness, maxBrightness);
    sharedPreferences.setInt('brightness', _brightness);

    notifyListeners();
    writeBrightnessData();
  }

  GameState get state => _state;

  set state(GameState state) {
    _state = state;

    notifyListeners();
    writeStateData();
  }

  void addPlayer() {
    players = [
      ...players,
      const Player(
        LivingState.alive,
        TypeState.character,
        TeamState.hidden,
      ),
    ];

    notifyListeners();
    writePlayerCharacteristics();
  }

  void removePlayerAt(int index) {
    players = [
      for (final (i, player) in players.indexed)
        if (i != index) player,
    ];

    notifyListeners();
    writePlayerCharacteristics();
  }

  void updatePlayer(int index, Player player) {
    players = [
      for (final (i, oldPlayer) in players.indexed)
        if (i == index) player else oldPlayer,
    ];

    notifyListeners();
    writePlayerCharacteristics();
  }

  int? get nominatedPlayer => _nominatedPlayer;

  set nominatedPlayer(int? index) {
    _nominatedPlayer = index;

    notifyListeners();
    writePlayerNominatedData();
  }

  Future<void> writeConnectedData() async {
    await Future.wait([
      writeBrightnessData(),
      writeStateData(),
      writePlayerCharacteristics(),
      writePlayerNominatedData(),
    ]);
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
    writer.writeInt(_state.index, signed: false, bits: GameState.values.last.index.bitLength);
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
      writer.writeEnum<TypeState>(TypeState.values, TypeState.character);
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

  Future<void> writeBrightnessData() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: brightnessCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithoutResponse(characteristic, value: packBrightnessBytes());
  }

  Uint8List packBrightnessBytes() {
    final writer = BitBuffer().writer();
    writer.writeInt(brightness, bits: maxBrightness.bitLength, signed: false);
    return writer.buffer.toUInt8List();
  }
}
