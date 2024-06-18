import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';


part 'api_controller_services.g.dart';

@RestApi(baseUrl: 'http://localhost:3000')
abstract class LoginService {
  factory LoginService(Dio dio) => _LoginService(dio);

  @POST('/login')
  Future<int?> loginUser(@Body() Map<String, dynamic> body);

  @GET('/logout')
  Future<void> logoutUser(@Header('Authorization') String token);
}
