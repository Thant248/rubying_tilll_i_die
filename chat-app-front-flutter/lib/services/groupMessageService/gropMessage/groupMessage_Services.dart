import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:flutter_frontend/model/groupMessage.dart';

part 'groupMessage_Services.g.dart';



@RestApi(baseUrl: 'http://localhost:3000')
abstract class GroupMessageServices {
  factory GroupMessageServices(Dio dio)=> _GroupMessageServices(dio);


  @GET('/m_channels/{id}')
   Future<groupMessageData> getAllGpMsg(
    @Path("id") int id,@Header('Authorization') String token
  );
  @POST("/groupmsg")
  Future<void> sendGroupMsgData(
    @Body() Map<String, dynamic> requestBody,@Header('Authorization') String token
  );
}