import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';
import 'device_page.dart';
import 'setup_page.dart';

final deviceListProvider =
    StateNotifierProvider.autoDispose<DeviceListStateNotifier, Iterable<DiscoveredDevice>>((ref) {
  final bluetooth = ref.watch(bluetoothProvider);
  return DeviceListStateNotifier(bluetooth);
});

class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SetupPage(child: DeviceListScaffold());
  }
}

class DeviceListScaffold extends ConsumerWidget {
  const DeviceListScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(deviceListProvider),
        child: const Column(children: [
          LinearProgressIndicator(),
          Expanded(child: DeviceListView()),
        ]),
      ),
    );
  }
}

class DeviceListView extends ConsumerWidget {
  const DeviceListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceList = ref.watch(deviceListProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const Divider(),
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        final device = deviceList.elementAt(index);
        return Card(
          child: ListTile(
            title: Center(child: Text(device.name.isEmpty ? device.id : device.name)),
            onTap: () async {
              final deviceList = ref.read(deviceListProvider.notifier);
              await deviceList.cancel();

              if (!context.mounted) return;
              await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return DevicePage.withOverrides(device: device);
              }));
              deviceList.scan();
            },
          ),
        );
      },
    );
  }
}
