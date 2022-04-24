enum MessageType {
  reserved,
  connect,
  connack,
  publish,
  puback,
  pubrec,
  pubrel,
  pubcomp,
  subscribe,
  suback,
  unsubscribe,
  unsuback,
  pingreq,
  pingresp,
  disconnect,
  auth
}

extension MessageTypeUtil on MessageType {
  static const _messageTypes = MessageType.values;

  static MessageType valueOf(int index) {
    if (index > _messageTypes.length) {
      throw Exception('Invalid message type of index $index');
    }
    return _messageTypes[index];
  }

  int fixedHeader([int flags = 0]) => (index << 4) | flags;
}
