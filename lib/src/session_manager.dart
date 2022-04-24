import 'dart:io';

import 'client.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._();
  final Set<Client> sessions = {};

  SessionManager._();

  static SessionManager get instance => _instance;

  bool containsClientId(String clientId) {
    return sessions.any((other) => other.clientId == clientId);
  }

  bool containsClient(Client client) {
    return containsClientId(client.clientId);
  }

  bool containsSocket(Socket socket) {
    return sessions.any((other) => other.socket == socket);
  }

  Client getClient(Socket socket) {
    return sessions.firstWhere((other) => other.socket == socket);
  }
}

class Session {
  void refresh() {}
}
