import 'dart:convert';
import 'package:client_server/direct_message.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  WebSocketChannel? get channel => _channel;

  

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }

  Future<DirectMessages> fetchData() async {
    final uri = Uri.parse("http://127.0.0.1:3000/m_users/2");
    try {
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        Map<String, dynamic> message = jsonDecode(response.body);
        DirectMessages dm = DirectMessages.fromJson(message);
        return dm;
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<void> sendMessageToDb(Map<String, dynamic> body) async {
    final uri = Uri.parse("http://127.0.0.1:3000/directmsg");
    try {
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        print('Message sent successfully');
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
