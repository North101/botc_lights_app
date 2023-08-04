import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers.dart';
import 'player_widget.dart';
import 'providers.dart';

class DeviceBody extends ConsumerWidget {
  const DeviceBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: TownsquareContainer()),
    );
  }
}

class TownsquareContainer extends StatelessWidget {
  const TownsquareContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: AlignmentDirectional.center,
      children: [
        TownsquareFlipAnimation(),
        TownsquareInfoWidget(),
      ],
    );
  }
}

class TownsquareFlipAnimation extends ConsumerWidget {
  const TownsquareFlipAnimation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flip = ref.watch(flipProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (widget, animation) {
        final rotateAnimation = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnimation,
          child: widget,
          builder: (context, widget) {
            final isUnder = widget?.key != const ValueKey(true);
            final tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            final value = isUnder ? min(rotateAnimation.value, pi / 2) : rotateAnimation.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt * (isUnder ? -1.0 : 1.0)),
              alignment: Alignment.center,
              child: widget,
            );
          },
        );
      },
      layoutBuilder: (widget, list) => Stack(children: [
        if (widget != null) widget,
        ...list,
      ]),
      switchInCurve: Curves.easeInBack,
      switchOutCurve: Curves.easeInBack.flipped,
      child: Transform.flip(
        key: ValueKey(flip),
        flipX: flip,
        child: ProviderScope(
          overrides: [
            flipProvider.overrideWith((ref) => flip),
          ],
          child: const TownsquareGestureDetector(),
        ),
      ),
    );
  }
}

class TownsquareGestureDetector extends ConsumerWidget {
  const TownsquareGestureDetector({super.key});

  onPanStart(WidgetRef ref, Offset offset, DragStartDetails details) {
    final touchPositionFromCenter = details.localPosition - offset;
    final finalAngle = ref.read(finalAngleProvider);
    ref.read(upsetAngleProvider.notifier).state = finalAngle - touchPositionFromCenter.direction;
  }

  onPanUpdate(WidgetRef ref, Offset offset, DragUpdateDetails details) {
    final touchPositionFromCenter = details.localPosition - offset;
    final upsetAngle = ref.read(upsetAngleProvider);
    ref.read(finalAngleProvider.notifier).state = touchPositionFromCenter.direction + upsetAngle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight);
      final offset = Offset(size / 2, size / 2);
      return SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onPanStart: (details) => onPanStart(ref, offset, details),
          onPanUpdate: (details) => onPanUpdate(ref, offset, details),
          child: const TownsquareRotated(),
        ),
      );
    });
  }
}

class TownsquareRotated extends ConsumerWidget {
  const TownsquareRotated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angle = ref.watch(finalAngleProvider);
    return Transform.rotate(
      angle: angle,
      child: const Townsquare(),
    );
  }
}

class Townsquare extends ConsumerWidget {
  static const playerAngleOffset = -pi / 2;

  const Townsquare({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerLength = ref.watch(playerListProvider.select((e) => e.length));
    final distanceAngle = 2 / playerLength * pi;
    return Stack(children: [
      for (var i = 0; i < playerLength; i++)
        Align(
          key: ValueKey(i),
          alignment: Alignment(
            cos(playerAngleOffset + (distanceAngle * i)),
            sin(playerAngleOffset + (distanceAngle * i)),
          ),
          child: ProviderScope(
            overrides: [
              playerIndexProvider.overrideWith((ref) => i),
            ],
            child: const PlayerWidget(),
          ),
        ),
    ]);
  }
}

class TownsquareInfoWidget extends ConsumerWidget {
  const TownsquareInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliveCount = ref.watch(alivePlayerCountProvider);
    final characterCount = ref.watch(characterCountProvider);
    final travellerCount = ref.watch(travellerCountProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$aliveCount / ${characterCount + travellerCount}'),
          if (characterCount >= minCharacters && characterCount <= maxCharacters)
            CharacterInfoWidget(characterCount),
        ],
      ),
    );
  }
}

class CharacterInfoWidget extends StatelessWidget {
  const CharacterInfoWidget(this.characterCount, {super.key});

  final int characterCount;

  int get townsfolk => switch (characterCount) {
        5 || 6 => 3,
        7 || 8 || 9 => 5,
        10 || 11 || 12 => 7,
        13 || 14 || 15 => 9,
        _ => 0,
      };

  int get outsiders => switch (characterCount) {
        5 || 7 || 10 || 13 => 0,
        6 || 8 || 11 || 14 => 1,
        9 || 12 || 15 => 2,
        _ => 0,
      };

  int get minions => switch (characterCount) {
        5 || 6 || 7 || 8 || 9 => 1,
        10 || 11 || 12 => 2,
        13 || 14 || 15 => 0,
        _ => 0,
      };

  int get demons => 1;

  @override
  Widget build(BuildContext context) {
    return Text('$townsfolk / $outsiders / $minions / $demons');
  }
}
