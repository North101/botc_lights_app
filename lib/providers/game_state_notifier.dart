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

abstract class CharacteristicStateNotifier<T> extends StateNotifier<T> {
  CharacteristicStateNotifier(this.bluetooth, this.device, super.state);

  final FlutterReactiveBle bluetooth;
  final DiscoveredDevice device;

  Uuid get characteristicId;

  void update(T value) {
    state = value;
    writeCharacteristic();
  }

  Future<void> writeCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: characteristicId,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packData());
  }

  Uint8List packData();
}

final deviceProvider = Provider<DiscoveredDevice>((ref) => throw UnimplementedError());

const maxCharacters = 15;
const minCharacters = 5;
const maxTravellers = 5;
const minTravellers = 0;
const maxPlayers = maxCharacters + maxTravellers;
const minPlayers = minCharacters + minTravellers;

class PlayerListNotifier extends StateNotifier<List<Player>> {
  PlayerListNotifier(this.bluetooth, this.device)
      : super([
          for (var i = 0; i < 7; i++)
            const Player(
              LivingState.alive,
              TypeState.character,
              TeamState.hidden,
            ),
        ]);

  final FlutterReactiveBle bluetooth;
  final DiscoveredDevice device;

  bool get hasMaxPlayers => state.length >= maxPlayers;

  void add() {
    state = [
      ...state,
      const Player(
        LivingState.alive,
        TypeState.character,
        TeamState.hidden,
      ),
    ];
    writeCharacteristics();
  }

  void remove(int index) {
    state = [
      for (final (i, player) in state.indexed)
        if (i != index) player,
    ];
    writeCharacteristics();
  }

  void update(int index, Player player) {
    state = [
      for (final (i, oldPlayer) in state.indexed)
        if (i == index) player else oldPlayer,
    ];
    writeCharacteristics();
  }

  Future<void> writeCharacteristics() async {
    await Future.wait([
      writeAliveCharacteristic(),
      writeTypeCharacteristic(),
      writeTeamCharacteristic(),
    ]);
  }

  Future<void> writeAliveCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerLivingCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packAliveData());
  }

  Uint8List packAliveData() {
    final writer = BitBuffer().writer();
    for (final player in state) {
      writer.writeEnum<LivingState>(LivingState.values, player.living);
    }
    for (var i = state.length; i < maxPlayers; i++) {
      writer.writeEnum<LivingState>(LivingState.values, LivingState.hidden);
    }
    return writer.buffer.toUInt8List();
  }

  Future<void> writeTypeCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerTypeCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packTypeData());
  }

  Uint8List packTypeData() {
    final writer = BitBuffer().writer();
    for (final player in state) {
      writer.writeEnum<TypeState>(TypeState.values, player.type);
    }
    for (var i = state.length; i < maxPlayers; i++) {
      writer.writeEnum<TypeState>(TypeState.values, TypeState.character);
    }
    return writer.buffer.toUInt8List();
  }

  Future<void> writeTeamCharacteristic() async {
    final characteristic = QualifiedCharacteristic(
      serviceId: service,
      characteristicId: playerTeamCharacteristic,
      deviceId: device.id,
    );
    bluetooth.writeCharacteristicWithResponse(characteristic, value: packTeamData());
  }

  Uint8List packTeamData() {
    final writer = BitBuffer().writer();
    for (final player in state) {
      writer.writeEnum<TeamState>(TeamState.values, player.team);
    }
    for (var i = state.length; i < maxPlayers; i++) {
      writer.writeEnum<TeamState>(TeamState.values, TeamState.hidden);
    }
    return writer.buffer.toUInt8List();
  }
}

final playerListProvider = StateNotifierProvider.autoDispose<PlayerListNotifier, List<Player>>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return PlayerListNotifier(bluetooth, device);
}, dependencies: [
  bluetoothProvider,
  deviceProvider,
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

final addPlayerProvider = Provider.autoDispose((ref) {
  final playerList = ref.watch(playerListProvider.notifier);
  return !playerList.hasMaxPlayers ? playerList.add : null;
}, dependencies: [
  playerListProvider,
]);

class NominatedPlayerNotifier extends CharacteristicStateNotifier<int?> {
  NominatedPlayerNotifier(FlutterReactiveBle bluetooth, DiscoveredDevice device) : super(bluetooth, device, null);

  @override
  final characteristicId = playerNominatedCharacteristic;

  @override
  Uint8List packData() {
    final writer = BitBuffer().writer();
    final value = (state ?? -1) + 1;
    writer.writeInt(value, signed: false, bits: (maxPlayers + 1).bitLength);
    return writer.buffer.toUInt8List();
  }
}

final nominatedPlayerProvider = StateNotifierProvider.autoDispose<NominatedPlayerNotifier, int?>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return NominatedPlayerNotifier(bluetooth, device);
}, dependencies: [
  sharedPreferencesProvider,
  bluetoothProvider,
  deviceProvider,
]);

class PlayerColors {
  static const keyHidden = 'hidden';
  static const keyCharacter = 'character';
  static const keyTraveller = 'traveller';
  static const keyDead = 'dead';
  static const keyGood = 'good';
  static const keyEvil = 'evil';

  static const colorHidden = Colors.black;
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
      hidden: Color(sharedPreferences.getInt(keyHidden) ?? colorHidden.value),
      character: Color(sharedPreferences.getInt(keyCharacter) ?? colorCharacterAlive.value),
      traveller: Color(sharedPreferences.getInt(keyTraveller) ?? colorTravellerAlive.value),
      dead: Color(sharedPreferences.getInt(keyDead) ?? colorDead.value),
      good: Color(sharedPreferences.getInt(keyGood) ?? colorGood.value),
      evil: Color(sharedPreferences.getInt(keyEvil) ?? colorEvil.value),
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

  Future<void> save(SharedPreferences sharedPreferences) async {
    await Future.wait([
      sharedPreferences.setInt(keyHidden, hidden.value),
      sharedPreferences.setInt(keyCharacter, character.value),
      sharedPreferences.setInt(keyTraveller, traveller.value),
      sharedPreferences.setInt(keyDead, dead.value),
      sharedPreferences.setInt(keyGood, good.value),
      sharedPreferences.setInt(keyEvil, evil.value),
    ]);
  }

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

class PlayerColorsNotifier extends CharacteristicStateNotifier<PlayerColors> {
  PlayerColorsNotifier(this.sharedPreferences, FlutterReactiveBle bluetooth, DiscoveredDevice device)
      : super(bluetooth, device, PlayerColors.fromSharedPreferences(sharedPreferences));

  final SharedPreferences sharedPreferences;

  @override
  final characteristicId = colorsCharacteristic;

  @override
  void update(PlayerColors value) {
    super.update(value);

    state.save(sharedPreferences);
  }

  @override
  Uint8List packData() {
    final writer = BitBuffer().writer();
    writer.writeColor(state.hidden);
    writer.writeColor(state.character);
    writer.writeColor(state.traveller);
    writer.writeColor(state.dead);
    writer.writeColor(state.good);
    writer.writeColor(state.evil);
    return writer.buffer.toUInt8List();
  }
}

final colorsProvider = StateNotifierProvider.autoDispose<PlayerColorsNotifier, PlayerColors>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return PlayerColorsNotifier(sharedPreferences, bluetooth, device);
}, dependencies: [
  sharedPreferencesProvider,
  bluetoothProvider,
  deviceProvider,
]);

class BrightnessNotifier extends CharacteristicStateNotifier<int> {
  static const key = 'brightness';
  static const minBrightness = 0;
  static const maxBrightness = 100;
  static const defaultBrightness = 20;

  static int clamp(int value) => value.clamp(minBrightness, maxBrightness);

  BrightnessNotifier(this.sharedPreferences, FlutterReactiveBle bluetooth, DiscoveredDevice device)
      : super(bluetooth, device, clamp(sharedPreferences.getInt(key) ?? defaultBrightness));

  final SharedPreferences sharedPreferences;

  @override
  final characteristicId = brightnessCharacteristic;

  @override
  void update(int value) {
    super.update(clamp(value));

    sharedPreferences.setInt(key, value);
  }

  @override
  Uint8List packData() {
    final writer = BitBuffer().writer();
    writer.writeInt(state, bits: maxBrightness.bitLength, signed: false);
    return writer.buffer.toUInt8List();
  }
}

final brightnessProvider = StateNotifierProvider.autoDispose<BrightnessNotifier, int>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return BrightnessNotifier(sharedPreferences, bluetooth, device);
}, dependencies: [
  sharedPreferencesProvider,
  bluetoothProvider,
  deviceProvider,
]);

enum GameState {
  game,
  reveal,
}

class GameStateNotifier extends CharacteristicStateNotifier<GameState> {
  GameStateNotifier(FlutterReactiveBle bluetooth, DiscoveredDevice device) : super(bluetooth, device, GameState.game);

  @override
  final characteristicId = stateCharacteristic;

  @override
  Uint8List packData() {
    final writer = BitBuffer().writer();
    writer.writeInt(state.index, signed: false, bits: GameState.values.last.index.bitLength);
    return writer.buffer.toUInt8List();
  }
}

final stateProvider = StateNotifierProvider.autoDispose<GameStateNotifier, GameState>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  final device = ref.watch(deviceProvider);
  return GameStateNotifier(bluetooth, device);
}, dependencies: [
  bluetoothProvider,
  deviceProvider,
]);
