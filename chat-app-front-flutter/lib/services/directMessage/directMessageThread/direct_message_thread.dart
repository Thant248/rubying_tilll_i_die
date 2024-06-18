import 'package:dio/dio.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:retrofit/http.dart';

part 'direct_message_thread.g.dart';

@RestApi()
abstract class DirectMsgThreadService {
  factory DirectMsgThreadService(Dio dio) => _DirectMsgThreadService(dio);

  @GET('http://localhost:3000/directhread/{directMsgid}')
  Future<DirectMessageThread> getAllThread(
      @Path() int directMsgid, @Header('Authorization') String token);

  @POST('http://localhost:3000/directthreadmsg')
  Future<String> sentThread(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);

  @GET('http://localhost:3000/starthread')
  Future<void> starThread(
      @Query('s_user_id') int receiveId,
      @Query('user_id') int currentUserid,
      @Query('id') int threadId,
      @Query('s_direct_message_id') int directMessageId,
      @Header('Authorization') String token);

  @GET('http://localhost:3000/unstarthread')
  Future<void> unStarThread(
      @Query('s_direct_message_id') int directMsgId,
      @Query('s_user_id') int receiveId,
      @Query('id') int threadId,
      @Query('user_id') int userId,
      @Header('Authorization') String token);

  @GET('http://localhost:3000/delete_directthread')
  Future<void> deleteThread(
      @Query('s_direct_message_id') int directMsgId,
      @Query('s_user_id') int receiveUserId,
      @Query('id') int threadId,
      @Header('Authorization') String token);
}
