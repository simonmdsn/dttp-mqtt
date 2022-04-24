import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


import 'package:dttp_mqtt/src/message/message.dart';
import 'package:dttp_mqtt/src/session_manager.dart';

import 'message/message_deletagor.dart';

class Server {
  static final delegator = MessageDelegator();
  final serverSocket = ServerSocket.bind(
    'localhost',
    6000,
  ).then((server) async {
    return server.listen((client) => client
      .transform<Uint8List>(StreamTransformer.fromHandlers())
      .listen((bytes) => delegator.delegate(bytes, client)));
  });


  final Timer timer = Timer.periodic(Duration(seconds: 5), (timer) {
    for (var key in SubscriptionManager.instance.subscriptions.keys) {
      SubscriptionManager.instance.subscriptions[key]?.forEach((element) {
        key.socket.add(PublishMessage(
            qos: element.qos,
            topic: element.topic,
            packetIdentifier: 1,
            payload: Uint8List.fromList(utf8.encode('Hello, world!')))
            .toByte());
      });
    }
  });
}
