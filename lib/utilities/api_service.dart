import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend_gaas/utilities/login_model.dart';

class APIService {
  Future<LoginResponseModel> login(LoginRequestModel requestModel) async {
    String url = "http://127.0.0.1:5000/login";

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
