import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants.dart';

typedef Device = ({DiscoveredDevice device, DateTime expires});

extension on Device {
  bool isExpired(DateTime now) => expires.isBefore(now);
}

class DeviceListStateNotifier extends StateNotifier<List<Device>> {
  DeviceListStateNotifier._(this.bluetooth) : super([]);

  factory DeviceListStateNotifier(FlutterReactiveBle bluetooth) {
    final notifier = DeviceListStateNotifier._(bluetooth);
    notifier.scan();
    return notifier;
  }

  final FlutterReactiveBle bluetooth;

  StreamSubscription<DiscoveredDevice>? scanner;
  Timer? timer;

  @override
  void dispose() async {
    super.dispose();

    await cancel();
  }

  bool get isScanning => scanner != null;

  void scan() {
    if (isScanning) return;

    scanner = bluetooth.scanForDevices(
      withServices: [service],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen((device) {
      final index = state.indexWhere((e) => e.device.id == device.id);
      final now = DateTime.now();
      final expires = now.add(const Duration(seconds: 20));
      final newValue = (device: device, expires: expires);
      state = [
        for (final (i, oldValue) in state.indexed)
          if (i == index) newValue else if (!oldValue.isExpired(now)) oldValue,
        if (index < 0) newValue
      ];
    }, onError: (error, stackTrace) {
      debugPrint(error);
    });
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = DateTime.now();
      state = [
        for (final value in state)
          if (!value.isExpired(now)) value,
      ];
    });
  }

  Future<void> cancel() async {
    await scanner?.cancel();
    scanner = null;

    timer?.cancel();
    timer = null;
  }
}
