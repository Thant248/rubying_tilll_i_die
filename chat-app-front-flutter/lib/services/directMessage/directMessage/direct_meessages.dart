import 'package:dio/dio.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:retrofit/http.dart';

part 'direct_meessages.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio) => _ApiService(dio);

  @GET("http://127.0.0.1:3000/m_users/{userId}")
  Future<DirectMessages> getAllDirectMessages(
      @Path("userId") int userId, @Header('Authorization') String token);

  @POST('http://127.0.0.1:3000/directmsg')
  Future<void> sendMessage(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);

  @GET('http://127.0.0.1:3000/star')
  Future<void> directStarMsg(
      @Query("s_user_id") int s_user_id,
      @Query("id") int messageId,
      @Query("user_id") int currentUserId,
      @Header('Authorization') String token);

  @GET('http://127.0.0.1:3000/unstar')
  Future<void> directUnStarMsg(
      @Query("id") int starId, @Header('Authorization') String token);

  @GET('http://127.0.0.1:3000/delete_directmsg')
  Future<void> deleteMessage(
      @Query("id") int msgId, @Header('Authorization') String token);
}
