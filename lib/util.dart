import 'package:bits/writer.dart';
import 'package:flutter/material.dart';

extension EnumBitBufferWriter on BitBufferWriter {
  void writeEnum<T extends Enum>(List<T> values, T value) {
    writeInt(value.index, signed: false, bits: (values.length - 1).bitLength);
  }

  void writeColor(Color value) {
    writeInt(value.red, bits: 8, signed: false);
    writeInt(value.green, bits: 8, signed: false);
    writeInt(value.blue, bits: 8, signed: false);
  }
}
