import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:flutter_frontend/model/confirm.dart';

part 'confirm_invitation_service.g.dart';

@RestApi()
abstract class ConfirmInvitationService {
  factory ConfirmInvitationService(Dio dio) => _ConfirmInvitationService(dio);

  @POST('http://localhost:3000/confirm_login')
  Future<void> invitationConfirm(@Body() Map<String, dynamic> requestBody);

  @GET('http://localhost:3000/confirminvitation')
  Future<Confirm> getConfirmData(@Query('channelid') int channelid,
      @Query('email') String email, @Query('workspaceid') int workspaceid);
}
