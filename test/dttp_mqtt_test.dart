import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dttp_mqtt/dttp_mqtt.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    late Server server;
    late MqttServerClient client;
    final List<MqttServerClient> clients = [];

    setUp(() async {
      server = Server('localhost', 6000);
      client = MqttServerClient.withPort(server.address, 'tester', server.port);
      sleep(Duration(seconds: 1));
      // client = MqttServerClient('simonmdsn.com', 'tester');
      client.setProtocolV311();
      await client.connect();
    });

    test('Subscribe', () {
      client.unsubscribe('a topic');
      client.subscribe('topic1', MqttQos.atMostOnce);
      client.updates?.listen((event) {
        print(event);
      });
    });

    test('Publish', () async {
      var mqttClientPayloadBuilder = MqttClientPayloadBuilder();
      mqttClientPayloadBuilder.addString('hello');
      for (int i = 0; i < 10; i++) {
        client.publishMessage('topic1', MqttQos.atMostOnce, mqttClientPayloadBuilder.payload!);
      }
      await Future.delayed(Duration(milliseconds: 100));
    });

    test('Subscribe', () {
      client.subscribe('topic2', MqttQos.atMostOnce);
    });

    test('Close', () {
      client.disconnect();
    });

    test('Heavy benchmark', () async {
      for (int i = 0; i < 10; i++) {
        var mqttServerClient = MqttServerClient.withPort(server.address, 'tester$i', server.port);
        await mqttServerClient.connect();
        mqttServerClient.updates?.listen((event) {print(event);});
        mqttServerClient.subscribe('topic1', MqttQos.atMostOnce);
        clients.add(mqttServerClient);
      }
      var mqttClientPayloadBuilder = MqttClientPayloadBuilder();
      mqttClientPayloadBuilder.addString('hello');
      clients.first.publishMessage('topic1', MqttQos.atMostOnce, mqttClientPayloadBuilder.payload!);
      await Future.delayed(Duration(seconds: 1));
    });
  });
}
