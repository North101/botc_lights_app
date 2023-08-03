import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';

class DeviceFloatingActionButton extends ConsumerWidget {
  const DeviceFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addPlayer = ref.watch(addPlayerProvider);
    return FloatingActionButton(
      onPressed: addPlayer,
      child: const Icon(Icons.add),
    );
  }
}
