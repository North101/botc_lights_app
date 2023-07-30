import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';

class DeviceListStateNotifier extends StateNotifier<List<DiscoveredDevice>> {
  DeviceListStateNotifier._(this.bluetooth) : super([]);

  factory DeviceListStateNotifier(FlutterReactiveBle bluetooth) {
    final notifier = DeviceListStateNotifier._(bluetooth);
    notifier.scan();
    return notifier;
  }

  final FlutterReactiveBle bluetooth;

  StreamSubscription<DiscoveredDevice>? scanner;

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  void scan() {
    scanner = bluetooth.scanForDevices(
      withServices: [service],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen((device) {
      final newState = [...state];
      final i = newState.indexWhere((e) => e.id == device.id);
      if (i >= 0) {
        newState[i] = device;
      } else {
        newState.add(device);
      }
      state = newState;
    }, onError: (error, stackTrace) {
      debugPrint(error);
    });
  }

  Future<void> cancel() async {
    await scanner?.cancel();
    scanner = null;
  }
}
