import 'package:bits/bits.dart';

enum AliveState {
  hidden,
  alive,
  deadVote,
  deadNoVote,
}

enum TypeState {
  player,
  traveller,
}

class Player {
  const Player(this.alive, this.type);

  factory Player.fromBits(BitBufferReader reader) {
    final alive = reader.readInt(signed: false, bits: AliveState.values.last.index.bitLength);
    final type = reader.readInt(signed: false, bits: TypeState.values.last.index.bitLength);
    return Player(
      AliveState.values[alive],
      TypeState.values[type],
    );
  }

  final AliveState alive;
  final TypeState type;

  bool get isAlive => alive == AliveState.alive;
  bool get isTraveller => type == TypeState.traveller;

  void writeBits(BitBufferWriter writer) {
    writer.writeInt(alive.index, signed: false, bits: AliveState.values.last.index.bitLength);
    writer.writeInt(type.index, signed: false, bits: TypeState.values.last.index.bitLength);
  }
}
