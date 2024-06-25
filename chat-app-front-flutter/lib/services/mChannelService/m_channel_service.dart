import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'm_channel_service.g.dart';

@RestApi()
abstract class MChannelService {
  factory MChannelService(Dio dio) => _MChannelService(dio);

  @POST('http://192.168.2.79:3000/m_channels')
  Future<void> createMChannel(
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @DELETE('http://192.168.2.79:3000/m_channels/{channelID}')
  Future<void> deleteChannel(
      @Part() int channelID, @Header('Authorization') String token);

  @PATCH('http://localhost:3000/m_channels/{channelId}')
  Future<String> updateChannel(@Path() int channelId,
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @GET('http://localhost:3000/channeluserjoin')
  Future<String> joinChannel(@Query('user_id') int userID,@Query('channel_id') int channelId,
      @Header('Authorization') String token);
  
  
}
