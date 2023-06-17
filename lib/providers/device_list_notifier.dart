import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';

class DeviceListStateNotifier extends StateNotifier<List<DiscoveredDevice>> {
  static final bluetoothManager = FlutterReactiveBle();

  DeviceListStateNotifier._() : super([]);

  StreamSubscription<DiscoveredDevice>? scanner;

  factory DeviceListStateNotifier() {
    final notifier = DeviceListStateNotifier._();
    notifier.listen();
    return notifier;
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  void listen() {
    scanner = bluetoothManager.scanForDevices(
      withServices: [
        uartServiceId,
      ],
      scanMode: ScanMode.lowLatency,
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

