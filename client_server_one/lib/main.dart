import 'dart:convert';

import 'package:client_server/WebSocketService.dart';
import 'package:client_server/direct_message.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WebSocketService _webSocketService = WebSocketService();
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];
  WebSocketChannel? _channel;

  void connectWebSocket() {
    const url = 'ws://localhost:3000/cable?user_id=1';
    _channel = WebSocketChannel.connect(Uri.parse(url));

// Subscribe to the "ChatChannel"
    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);

    _channel!.stream.listen(
      (message) {
        var parsedMessage = jsonDecode(message) as Map<String, dynamic>;
        var directmsg = parsedMessage['message']['message']['directmsg'];

        setState(() {
          _messages.add(directmsg);
        });
      },
      onDone: () {
        print('WebSocket connection closed');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    _loadMessages();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      DirectMessages messages = await _webSocketService.fetchData();
      setState(() {
        _messages = messages.tDirectMessages!
            .map((e) => e.directmsg.toString())
            .toList();
      });
    } catch (e) {
      print('Failed to fetch messages: $e');
    }
  }

  void _sendMessage() async {
    List<Map<String, String>> files = [
      {"mime": "", "data": ""}
    ];
    Map<String, dynamic> body = {
      "message": _controller.text,
      "user_id": "2",
      "s_user_id": "1",
      "file": files
    };

// Send message to WebSocket and save to database
    _webSocketService.sendMessage(body);
    await _webSocketService.sendMessageToDb(body);

    setState(() {
      _messages.add(_controller.text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
