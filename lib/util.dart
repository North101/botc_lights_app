import 'package:bits/writer.dart';

extension EnumBitBufferWriter on BitBufferWriter {
  void writeEnum<T extends Enum>(List<T> values, T value) {
    writeInt(value.index, signed: false, bits: (values.length - 1).bitLength);
  }
}
