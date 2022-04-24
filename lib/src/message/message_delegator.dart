import 'dart:io';
import 'dart:typed_data';

import 'message.dart';
import 'message_enums.dart';

class MessageDelegator {
  //TODO handle wrong protocols, versions, and more...
  void delegate(Uint8List uint8list, Socket socket) {
    final type = MessageTypeUtil.valueOf(uint8list[0] >> 4);
    switch (type) {
      case MessageType.reserved:
        break;
      case MessageType.connect:
        var connack = ConnectMessageDecoder().decode(uint8list, socket);
        socket.add(connack.toByte());
        break;
      case MessageType.connack:
        // TODO: Handle this case.
        break;
      case MessageType.publish:
        // TODO: Handle this case.
        break;
      case MessageType.puback:
        // TODO: Handle this case.
        break;
      case MessageType.pubrec:
        // TODO: Handle this case.
        break;
      case MessageType.pubrel:
        // TODO: Handle this case.
        break;
      case MessageType.pubcomp:
        // TODO: Handle this case.
        break;
      case MessageType.subscribe:
        var suback = SubscribeMessageDecoder().decode(uint8list, socket);
        // socket.add(suback.toByte());
        break;
      case MessageType.suback:
        // TODO: Handle this case.
        break;
      case MessageType.unsubscribe:
        break;
      case MessageType.unsuback:
        // TODO: Handle this case.
        break;
      case MessageType.pingreq:
        // TODO: Handle this case.
        break;
      case MessageType.pingresp:
        // TODO: Handle this case.
        break;
      case MessageType.disconnect:
        // TODO: Handle this case.
        break;
      case MessageType.auth:
        // TODO: Handle this case.
        break;
    }
  }
}
