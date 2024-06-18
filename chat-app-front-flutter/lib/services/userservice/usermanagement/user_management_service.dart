import 'package:dio/dio.dart';
import 'package:flutter_frontend/model/user_management.dart';
import 'package:retrofit/http.dart';

part 'user_management_service.g.dart';

@RestApi()
abstract class UserManagementService {
  factory UserManagementService(Dio dio) => _UserManagementService(dio);

  @GET('http://localhost:3000/usermanage')
  Future<UserManagement> getAllUser(@Header('Authorization') String token);

  @GET('http://localhost:3000/update')
  Future<String> deactivateUser(
      @Query('id') int userID, @Header('Authorization') String token);
}
