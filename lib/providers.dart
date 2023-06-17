import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

export '/providers/player_state_notifier.dart';
export '/providers/device_list_notifier.dart';

final bluetoothProvider = Provider((ref) {
  return FlutterReactiveBle();
});

final bluetoothStatusProvider = StreamProvider((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  return bluetooth.statusStream;
});

final permissionList = {
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
};

extension on PermissionStatus {
  bool get denied => switch (this) {
        PermissionStatus.denied || PermissionStatus.permanentlyDenied || PermissionStatus.restricted => true,
        PermissionStatus.granted || PermissionStatus.limited || PermissionStatus.provisional => false,
      };
}

final deniedPermissionProvider = FutureProvider((ref) {
  return permissionList.toList().request().then((value) {
    return value.entries.where((e) => e.value.denied).map((e) => e.key).firstOrNull;
  });
});

final setupProvider = StreamProvider<Result>((ref) async* {
  final deniedPermission = await ref.watch(deniedPermissionProvider.future);
  if (deniedPermission != null) {
    yield PermissionDeniedResult(deniedPermission);
    return;
  }

  final bluetoothStatus = await ref.watch(bluetoothStatusProvider.future);
  yield BluetoothStatusResult(bluetoothStatus);
  return;
});

sealed class Result {
  const Result();
}

class PermissionDeniedResult extends Result {
  const PermissionDeniedResult(this.permission) : super();

  final Permission permission;
}

class BluetoothStatusResult extends Result {
  const BluetoothStatusResult(this.status) : super();

  final BleStatus status;
}
