import 'package:bits/bits.dart';

enum LivingState {
  hidden('Hidden'),
  alive('Alive'),
  dead('Dead');

  const LivingState(this.title);

  final String title;
}

enum TypeState {
  character('Character'),
  traveller('Traveller');

  const TypeState(this.title);

  final String title;
}

enum TeamState {
  hidden('Hidden'),
  good('Good'),
  evil('Evil');

  const TeamState(this.title);

  final String title;
}

class Player {
  const Player(this.living, this.type, this.team);

  factory Player.fromBits(BitBufferReader reader) {
    final living = reader.readInt(signed: false, bits: LivingState.values.last.index.bitLength);
    final type = reader.readInt(signed: false, bits: TypeState.values.last.index.bitLength);
    return Player(
      LivingState.values[living],
      TypeState.values[type],
      TeamState.hidden,
    );
  }

  final LivingState living;
  final TypeState type;
  final TeamState team;

  bool get isHidden => living == LivingState.hidden;
  bool get isAlive => living == LivingState.alive;
  bool get isTraveller => type == TypeState.traveller;

  Player copyWith({
    LivingState? living,
    TypeState? type,
    TeamState? team,
  }) =>
      Player(
        living ?? this.living,
        type ?? this.type,
        team ?? this.team,
      );
}
