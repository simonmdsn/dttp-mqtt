import 'dart:io';
import 'dart:typed_data';

import 'message.dart';
import 'message_enums.dart';

class MessageDelegator {
  final publishDecoder = PublishMessageDecoder();
  final connectDecoder = ConnectMessageDecoder();
  final subscribeDecoder= SubscribeMessageDecoder();
  final unsubDecoder = UnsubscribeMessageDecoder();
  final pingreqDecoder = PingreqMessageDecoder();
  final disconnectDecoder = DisconnectMessageDecoder();

  //TODO handle wrong protocols, versions, and more...
  Future<void> delegate(Uint8List uint8list, Socket socket) async {
    final type = MessageTypeUtil.valueOf(uint8list[0] >> 4);
    switch (type) {
      case MessageType.publish:
        publishDecoder.decode(uint8list, socket);
        break;
      case MessageType.connect:
        var connack = await connectDecoder.decode(uint8list, socket);
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
        subscribeDecoder.decode(uint8list, socket);
        break;
      case MessageType.unsubscribe:
        unsubDecoder.decode(uint8list, socket);
        break;
      case MessageType.pingreq:
        pingreqDecoder.decode(uint8list, socket);
        break;
      case MessageType.disconnect:
        disconnectDecoder.decode(uint8list, socket);
        break;
      case MessageType.auth:
        // TODO: Handle this case.
        break;
    }
  }
}
