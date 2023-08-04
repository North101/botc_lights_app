import 'dart:typed_data';

import 'package:bits/bits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/providers.dart';
import '/constants.dart';
import '/player_state.dart';
import '/util.dart';

class PlayerColors {
  static const colorHidden = Color.fromARGB(255, 000, 000, 000);
  static const colorCharacterAlive = Color.fromARGB(255, 244, 241, 234);
  static const colorTravellerAlive = Color.fromARGB(255, 205, 170, 056);
  static const colorDead = Color.fromARGB(255, 063, 025, 066);
  static const colorGood = Color.fromARGB(255, 082, 182, 255);
  static const colorEvil = Color.fromARGB(255, 255, 54, 54);

  const PlayerColors({
    required this.hidden,
    required this.character,
    required this.traveller,
    required this.dead,
    required this.good,
    required this.evil,
  });

  factory PlayerColors.fromSharedPreferences(SharedPreferences sharedPreferences) {
    return PlayerColors(
      hidden: Color(sharedPreferences.getInt('hidden') ?? colorHidden.value),
      character: Color(sharedPreferences.getInt('character') ?? colorCharacterAlive.value),
      traveller: Color(sharedPreferences.getInt('traveller') ?? colorTravellerAlive.value),
      dead: Color(sharedPreferences.getInt('dead') ?? colorDead.value),
      good: Color(sharedPreferences.getInt('good') ?? colorGood.value),
      evil: Color(sharedPreferences.getInt('evil') ?? colorEvil.value),
    );
  }

  final Color hidden;
  final Color character;
  final Color traveller;
  final Color dead;
  final Color good;
  final Color evil;

  PlayerColors copyWith({
    Color? hidden,
    Color? character,
    Color? traveller,
    Color? dead,
    Color? good,
    Color? evil,
  }) =>
      PlayerColors(
        hidden: hidden ?? this.hidden,
        character: character ?? this.character,
        traveller: traveller ?? this.traveller,
        dead: dead ?? this.dead,
        good: good ?? this.good,
        evil: evil ?? this.evil,
      );

  @override
  bool operator ==(Object other) =>
      other is PlayerColors &&
      hidden == other.hidden &&
      character == other.character &&
      traveller == other.traveller &&
      dead == other.dead &&
      good == other.good &&
      evil == other.evil;

  @override
  int get hashCode => Object.hash(
        hidden,
        character,
        traveller,
        dead,
        good,
        evil,
      );
}

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

  static int clampBrightness(int value) {
    return value.clamp(minBrightness, maxBrightness);
  }

  GameStateNotifier(this.sharedPreferences, this.bluetooth, this.device)
      : _brightness = clampBrightness(sharedPreferences.getInt('brightness') ?? defaultBrightness),
        _colors = PlayerColors.fromSharedPreferences(sharedPreferences);

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
  int _brightness;
  PlayerColors _colors;

  bool get hasMaxPlayers => players.length >= maxPlayers;

  int get brightness => _brightness;

  set brightness(int brightness) {
    _brightness = clampBrightness(brightness);
    sharedPreferences.setInt('brightness', _brightness);

    notifyListeners();
    writeBrightnessData();
  }

  PlayerColors get colors => _colors;

  set colors(PlayerColors colors) {
    _colors = colors;
    sharedPreferences.setInt('hidden', _colors.hidden.value);
    sharedPreferences.setInt('character', _colors.character.value);
    sharedPreferences.setInt('traveller', _colors.traveller.value);
    sharedPreferences.setInt('dead', _colors.dead.value);
    sharedPreferences.setInt('good', _colors.good.value);
    sharedPreferences.setInt('evil', _colors.evil.value);

    notifyListeners();
    writeColorsData();
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
      writeColorsData(),
    ]);
  }

  Future<void> writeStateData() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: stateCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packStateBytes());
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
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packPlayerAliveBytes());
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
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packPlayerTypeBytes());
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
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packPlayerTeamBytes());
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
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packGameNominatedBytes());
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
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packBrightnessBytes());
  }

  Uint8List packBrightnessBytes() {
    final writer = BitBuffer().writer();
    writer.writeInt(brightness, bits: maxBrightness.bitLength, signed: false);
    return writer.buffer.toUInt8List();
  }

  Future<void> writeColorsData() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: colorsCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packColorsBytes());
  }

  Uint8List packColorsBytes() {
    final writer = BitBuffer().writer();
    writer.writeColor(_colors.hidden);
    writer.writeColor(_colors.character);
    writer.writeColor(_colors.traveller);
    writer.writeColor(_colors.dead);
    writer.writeColor(_colors.good);
    writer.writeColor(_colors.evil);
    return writer.buffer.toUInt8List();
  }
}

final deviceProvider = Provider<DiscoveredDevice>((ref) => throw UnimplementedError());
final gameStateProvider = ChangeNotifierProvider.autoDispose<GameStateNotifier>((ref) {
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

final playerListProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.players;
}, dependencies: [
  gameStateProvider,
]);

final alivePlayerCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living == LivingState.alive).length;
}, dependencies: [
  playerListProvider,
]);

final characterCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living != LivingState.hidden && e.type == TypeState.character).length;
}, dependencies: [
  playerListProvider,
]);

final travellerCountProvider = Provider.autoDispose((ref) {
  final players = ref.watch(playerListProvider);
  return players.where((e) => e.living != LivingState.hidden && e.type == TypeState.traveller).length;
}, dependencies: [
  playerListProvider,
]);

final colorsProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.colors;
}, dependencies: [
  gameStateProvider,
]);

final addPlayerProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider);
  return !gameState.hasMaxPlayers ? gameState.addPlayer : null;
}, dependencies: [
  gameStateProvider,
]);

final stateProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.state;
}, dependencies: [
  gameStateProvider,
]);

final brightnessProvider = Provider.autoDispose((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.brightness;
}, dependencies: [
  gameStateProvider,
]);
