import 'dart:io';
import 'dart:typed_data';

import 'message.dart';
import 'message_enums.dart';

class MessageDelegator {
  //TODO handle wrong protocols, versions, and more...
  void delegate(Uint8List uint8list, Socket socket) {
    final type = MessageTypeUtil.valueOf(uint8list[0] >> 4);
    switch (type) {
      case MessageType.publish:
        var publish = PublishMessageDecoder().decode(uint8list, socket);
        break;
      case MessageType.connect:
        var connack = ConnectMessageDecoder().decode(uint8list, socket);
        socket.add(connack.toByte());
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
      case MessageType.unsubscribe:
        var unsuback = UnsubscribeMessageDecoder().decode(uint8list, socket);
        break;
      case MessageType.pingreq:
        var pingresp = PingreqMessageDecoder().decode(uint8list, socket);
        break;
      case MessageType.disconnect:
        DisconnectMessageDecoder().decode(uint8list, socket);
        break;
      case MessageType.auth:
        // TODO: Handle this case.
        break;
    }
  }
}
