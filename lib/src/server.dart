import 'dart:async';
import 'dart:io';

import 'package:dttp_mqtt/src/message/message_enums.dart';

import 'message/message_delegator.dart';

class Server {
  final String address;
  final int port;
  static final delegator = MessageDelegator();
  late final Future<ServerSocket> serverSocket;

  Server(this.address, this.port);

  Future<void> start() async {
    serverSocket = ServerSocket.bind(address, port, shared: true).then((server) {
      server.listen((client) async {
        bool first = true;
        client.listen((bytes) {
          try {
            if (first) {
              try {
                var messageType = MessageTypeUtil.valueOf((bytes)[0] >> 4);
                if (messageType != MessageType.connect) {
                  client.close();
                  return;
                }
                first = false;
              } on Exception {
                client.close();
                return;
              }
            }
            int counter = 1;
            int remainingBytes = 0;
            while (counter < remainingBytes || counter < bytes.lengthInBytes) {
              remainingBytes = bytes[counter];
              delegator.delegate(bytes.sublist(counter - 1, remainingBytes + counter + 1), client);
              counter += remainingBytes + 2;
            }
          } on SocketException {
            client.close();
          }
        });
      });
      return server;
    });
  }
}
