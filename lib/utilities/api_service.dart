import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend_gaas/utilities/login_model.dart';

class APIService {
  Future<LoginResponseModel> login(LoginRequestModel requestModel) async {
    String url = "https://54.175.183.221:5000/login";

    final response = await http.post(url, body: requestModel.toJson());
    if (response.statusCode == 200 || response.statusCode == 400) {
      return LoginResponseModel.fromJson(
        response.headers,
      );
    } else {
      throw Exception('Failed to load data!');
    }
  }
}
