import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dttp_mqtt/src/client.dart';

import '../session_manager.dart';
import 'message_enums.dart';

enum ProtocolVersion {
  mqtt_311,
  mqtt_5,
}

extension ProtocolVersionUtil on ProtocolVersion {
  static const _protocols = ProtocolVersion.values;

  static ProtocolVersion getProtocolVersion(int version) {
    final offset = 4;
    return _protocols[version - offset];
  }
}

abstract class Message {
  final MessageType type;
  int fixedHeaderFlags = 0; // value between 0 and 15

  Message({
    required this.type,
  });
}

/// Base model for outgoing message types, i.e. CONNACK, SUBACK, PUBACK...
mixin RequestMessage {
  Uint8List toByte();
}

/// Base model for incoming message types, i.e. CONNECT, SUBSCRIBE, PUBLISH...
mixin ResponseMessage {}

class ConnectMessage extends Message with ResponseMessage {
  final ProtocolVersion version;

  ConnectMessage({
    this.version = ProtocolVersion.mqtt_311,
  }) : super(
          type: MessageType.connect,
        );
}

class ConnackMessage extends Message with RequestMessage {
  final bool cleanSession;
  final ConnectReturnCode returnCode;

  ConnackMessage({required this.cleanSession, required this.returnCode})
      : super(type: MessageType.connack);

  @override
  Uint8List toByte() {
    final variableHeader = Uint8List.fromList([cleanSession ? 0 : 1, returnCode.index]);
    final bytes = Uint8List.fromList([
      type.fixedHeader(),
      variableHeader.lengthInBytes,
      ...variableHeader,
    ]);
    return bytes;
  }
}

class SubscribeMessage extends Message with ResponseMessage {
  SubscribeMessage() : super(type: MessageType.subscribe);
}

class SubackMessage extends Message with RequestMessage {
  final List<int> qoss;
  final int packetIdentifier;

  SubackMessage({required this.qoss, required this.packetIdentifier})
      : super(type: MessageType.suback);

  @override
  Uint8List toByte() {
    final variableHeader = Uint16List.fromList([packetIdentifier]).buffer.asUint8List();
    final payload = Uint8List.fromList(qoss);
    final bytes = Uint8List.fromList([
      type.fixedHeader(),
      variableHeader.lengthInBytes + payload.lengthInBytes,
      ...variableHeader.reversed,
      ...payload,
    ]);
    print(bytes.asMap());
    return bytes;
  }
}

class PublishMessage extends Message with ResponseMessage, RequestMessage {
  final int qos;
  int duplicateFlag = 0;
  final int retain;
  final String topic;
  final int packetIdentifier;
  final Uint8List payload;

  PublishMessage({
    required this.qos,
    this.retain = 0,
    required this.topic,
    required this.packetIdentifier,
    required this.payload,
  }) : super(type: MessageType.publish);

  @override
  Uint8List toByte() {
    int qosShift = qos == 2
        ? 4
        : (qos == 1)
            ? 2
            : 0;
    int shift = duplicateFlag * 8 + qosShift + retain;
    final topicBytes = utf8.encode(topic);
    final variableHeader = Uint8List.fromList([
      ...Uint16List.fromList([topicBytes.length]).buffer.asUint8List().reversed,
      ...topicBytes
    ]);
    //TODO support packet identifier
    final bytes = Uint8List.fromList([
      type.fixedHeader(shift),
      variableHeader.lengthInBytes + payload.lengthInBytes,
      ...variableHeader,
      ...payload.toList()
    ]);
    return bytes;
  }
}

extension Bits on int {
  /**
   * Returns true if bit is 1 else false
   */
  bool isBitSet(final int position) {
    return (this & (1 << position)) != 0;
  }
}

enum ConnectReturnCode {
  connectionAccepted,
  wrongProtocol,
  identifierRejected,
  serverUnavailable,
  badUsernameOrPassword,
  notAuthorized,
}

extension ConnectReturnCodeUtil on ConnectReturnCode {
  static const _connectionReturnCodes = ConnectReturnCode.values;

  static ConnectReturnCode valueOf(int index) {
    if (index > _connectionReturnCodes.length) {
      throw Exception('Invalid message type of index $index');
    }
    return _connectionReturnCodes[index];
  }
}

class ConnectMessageDecoder extends MessageDecoder {
  @override
  ConnackMessage decode(Uint8List uint8list, Socket socket) {
    print(uint8list.asMap());

    int currentIndex = 8;

    print('version: ' + ProtocolVersionUtil.getProtocolVersion(uint8list[currentIndex]).name);
    currentIndex++;

    print('number of bytes: ' + uint8list.length.toString());
    final bits = uint8list[currentIndex].toRadixString(2);
    print('connect flag bits: ' + bits);
    final cleanSession = uint8list[currentIndex].isBitSet(1);
    print('clean session: ' + cleanSession.toString());
    final cleanWill = uint8list[currentIndex].isBitSet(2);
    print('clean will flag: ' + cleanWill.toString());
    final willQos = (uint8list[currentIndex].isBitSet(3)
        ? 1
        : 0 + (uint8list[currentIndex].isBitSet(4) ? 1 : 0));
    print('will qos: ' + (willQos.toString()));
    final willRetain = uint8list[currentIndex].isBitSet(5);
    print('will retain: ' + willRetain.toString());
    final passwordFlag = uint8list[currentIndex].isBitSet(6);
    print('password flag: ' + passwordFlag.toString());
    final usernameFlag = uint8list[currentIndex].isBitSet(7);
    print('user name flag $usernameFlag');

    currentIndex++;
    final keepAliveSeconds =
        Uint8List.fromList([uint8list[currentIndex++], uint8list[currentIndex++]])
            .buffer
            .asByteData()
            .getUint16(0)
            .toString();
    print('Keep alive: ' + keepAliveSeconds);

    final clientIdStringLength =
        uint8list.sublist(currentIndex++, ++currentIndex).buffer.asByteData().getUint16(0);
    final clientIdString =
        utf8.decode(uint8list.sublist(currentIndex, currentIndex + clientIdStringLength));

    print('client id: ' + clientIdString);

    currentIndex += clientIdStringLength;

    if (usernameFlag) {
      final usernameLength = uint8list.buffer.asByteData(currentIndex++).getUint16(0);
      currentIndex++;
      final usernameString =
          utf8.decode(uint8list.sublist(currentIndex, currentIndex + usernameLength));
      currentIndex += usernameLength;
      print('username: ' + usernameString);
    }

    print(currentIndex);

    if(passwordFlag) {

    final passwordLength = uint8list.buffer.asByteData(currentIndex++).getUint16(0);
    final passwordString =
        utf8.decode(uint8list.sublist(++currentIndex, currentIndex + passwordLength));
    currentIndex += passwordLength;

    print('password: $passwordString');
    }

    //TODO implement will topic
    if (SessionManager.instance.containsClientId(clientIdString)) {
      //TODO check flags and send error to socket
    }

    SessionManager.instance.sessions.add(Client(clientId: clientIdString, socket: socket));

    final connack = ConnackMessage(
        cleanSession: cleanSession, returnCode: ConnectReturnCode.connectionAccepted);

    return connack;
  }
}

class Subscription {
  final int qos;
  final String topic;

  Subscription({required this.qos, required this.topic});
}

class SubscriptionManager {
  final Map<Client, Set<Subscription>> subscriptions = {};

  static final _instance = SubscriptionManager._();

  static SubscriptionManager get instance => _instance;

  SubscriptionManager._();

  void add(Client client, Subscription subscription) {
    if (!subscriptions.containsKey(client)) {
      subscriptions[client] = {};
    }
    subscriptions[client]!.add(subscription);
  }

  void addAll(Client client, List<Subscription> subscriptions) {
    for (var subscription in subscriptions) {
      add(client, subscription);
    }
  }
}

class SubscribeMessageDecoder implements MessageDecoder {
  @override
  SubackMessage decode(Uint8List uint8list, Socket socket) {
    final buffer = uint8list.buffer;
    print(uint8list.asMap());
    int currentIndex = 2;

    final packetIdentifier = buffer.asByteData(currentIndex, 2).getUint16(0);
    print('packet identifier: $packetIdentifier');
    currentIndex++;

    print(buffer.lengthInBytes);

    final List<String> topics = [];

    final List<Subscription> subscriptions = [];

    print(currentIndex);
    ///payload
    while (currentIndex < buffer.lengthInBytes - 1) {
      currentIndex++;
      int payloadLength = buffer.asByteData(currentIndex, 2).getUint16(0);
      currentIndex += 2;
      final topic = utf8.decode(buffer.asUint8List(currentIndex, payloadLength));
      topics.add(topic);
      currentIndex += payloadLength;
      final qos = buffer.asByteData(currentIndex, 1).getUint8(0);
      subscriptions.add(Subscription(qos: qos, topic: topic));
    }

    SubscriptionManager.instance.addAll(SessionManager.instance.getClient(socket), subscriptions);
    final suback = SubackMessage(
        qoss: subscriptions.map((e) => e.qos).toList(), packetIdentifier: packetIdentifier);
    socket.add(suback.toByte());
    return suback;
  }
}

abstract class MessageDecoder {
  Message decode(Uint8List uint8list, Socket socket);
}

main() {}
