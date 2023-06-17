import 'package:flutter/material.dart';

import 'default_title.dart';

class DefaultScaffold extends StatelessWidget {
  const DefaultScaffold({
    required this.body,
    this.title = const DefaultTitle(),
    super.key,
  });

  final Widget title;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: title,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: body,
        ),
      );
}

class DefaultLoadingScaffold extends StatelessWidget {
  const DefaultLoadingScaffold({
    this.title = const DefaultTitle(),
    super.key,
  });

  final Widget title;

  @override
  Widget build(BuildContext context) => DefaultScaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator()),
      );
}


class DefaultErrorScaffold extends StatelessWidget {
  const DefaultErrorScaffold({
    this.title = const DefaultTitle(),
    required this.error,
    required this.stackTrace,
    super.key,
  });

  final Widget title;
  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    debugPrintStack(stackTrace: stackTrace);
    return DefaultScaffold(
        title: title,
        body: Center(child: Text(error.toString())),
      );
  }
}