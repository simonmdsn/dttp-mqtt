import 'dart:typed_data';

/// Utilities for MQTT
///

/// variable byte decode
///

Map<String, int> decodeVariableByte(Uint8List uint8list, startIndex) {
  int multiplier = 1;
  int value = 0;
  int encodedByte = 0;
  do {
    encodedByte = uint8list.buffer.asByteData(startIndex).getUint8(0);
    value += (encodedByte & 127) * multiplier;
    if (multiplier > 128 * 128 * 128) {
      // Something is wrong
      // disconnect from client
    }
    multiplier *= 128;
    startIndex++;
  } while ((encodedByte & 128) != 0);
  return {'decodedVariableByte': value, 'index': startIndex };
}

/// variable byte encode
