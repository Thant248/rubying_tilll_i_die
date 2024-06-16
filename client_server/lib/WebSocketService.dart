import 'dart:convert';
import 'dart:io';
import 'package:client_server/direct_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;

class WebSocketService {
  WebSocketChannel? _channel;

  WebSocketChannel? get channel => _channel;

  void connect(int userId) {
    final url = 'ws://localhost:3000/cable?user_id=$userId';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (message) {
        // Handle incoming messages
        final decodedMessage = jsonDecode(message);
        print('Received: $decodedMessage');
        // Process the message and update your UI accordingly
      },
      onDone: () {
        print('WebSocket connection closed');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }
  }


  Future<DirectMessages> fetchdata() async {
    final uri = Uri.parse("http://127.0.0.1:3000/m_users/2");
    var response = await http.get(uri);
    Map<String, dynamic> message = jsonDecode(response.body);
    DirectMessages dm = DirectMessages.fromJson(message);
    return dm;
  }

  Future<void> sendmessagetodb(Map<String, dynamic> body) async {
    final uri = Uri.parse("http://127.0.0.1:3000/directmsg");
    await http.post(uri, body: jsonEncode(body), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    }, );
  
  }

}
