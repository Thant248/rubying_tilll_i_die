import 'dart:convert';

// import 'package:dio/dio.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;

class GpThreadMsg{
  
  Future<GroupThreadMessage> fetchGpThread(int id,int channelID) async {  
  var token = await AuthController().getToken();
  // bool? isLoggedIn = await getLogin();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
    Uri.parse(
    'http://localhost:3000/t_group_messages/${id}?s_channel_id=$channelID'),
    headers: <String, String>{
      'Content-Type':'application/json',
      'Authorization': 'Bearer $token',
    },
   
  );

  if (response.statusCode == 200) {
    // List<dynamic> jsonList = jsonDecode(response.body);
    // List<groupMessageData> users = jsonList.map((json) => groupMessageData.fromJson(json)).toList();
    final Map<String, dynamic> data = jsonDecode(response.body);
    GroupThreadMessage thread = GroupThreadMessage.fromJson(data);
   
    return thread;
    
  } else {
   
    throw Exception('Failed to load userdata');
  }
}

Future<void> sendGroupThreadData (
    String groupMessage, int channelID,int messageID, String mentionName) async {
  var token = await AuthController().getToken();   
  // int id = SessionStore.sessionData!.currentUser!.id!.toInt();
  final response = await http.post(
    Uri.parse('http://localhost:3000/groupthreadmsg'),
    headers:{
     'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(
      {
      "s_group_message_id":messageID,
      "s_channel_id": channelID,
      "message": groupMessage,
      "memtion_name": mentionName
      }
    ),
   
  );

  if (response.statusCode == 200) {
    
  } else {
    
  }
}

Future<void> deleteGpThread(int threadID,int channelID,int groupMesssageID) async{
  var token = await AuthController().getToken();   
  final url = 'http://localhost:3000/delete_groupthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
  final Response = await http.get(Uri.parse(url),
  headers: {
    'Content-Type':'application/json',
    'Authorization':'Bearer $token'
  },
  );
  if(Response.statusCode == 200){
   
  }
  else{
   
  }
  
}

Future<void> sendStarThread(int threadID,int channelID,int groupMesssageID) async{
  var token = await AuthController().getToken();   
  final url = 'http://localhost:3000/groupstarthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
  final Response = await http.get(Uri.parse(url),
  headers: {
    'Content-Type':'application/json',
    'Authorization':'Bearer $token'
  },
  );
  if(Response.statusCode == 200){
    
  }
  else{
   
  }
  
}

Future<void> unStarThread(int threadID,int channelID,int groupMesssageID) async{
  var token = await AuthController().getToken();   
  final url = 'http://localhost:3000/groupunstarthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
  final Response = await http.get(Uri.parse(url),
  headers: {
    'Content-Type':'application/json',
    'Authorization':'Bearer $token'
  },
  );
  if(Response.statusCode == 200){
    
  }
  else{
    
  }
  
}


}