import 'dart:core';
import 'package:frontend_gaas/components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_gaas/utilities/api_service.dart';
import 'package:frontend_gaas/components/constants.dart';
import 'package:frontend_gaas/components/ProgressHUD.dart';
import 'package:frontend_gaas/utilities/login_model.dart';
import 'main_functionality.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isApiCallProcess = false;
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  LoginRequestModel loginRequestModel;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    loginRequestModel = new LoginRequestModel();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: _uiSetup(context),
      inAsyncCall: isApiCallProcess,
      opacity: 0.3,
    );
  }

  bool showSpinner = false;
  String email;
  String password;

  @override
  Widget _uiSetup(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: globalFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('assets/images/Game1.jpg'),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                onSaved: (input) => loginRequestModel.email = input,
                onChanged: (value) {
                  email = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                    hintText: 'Enter your username.'),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextFormField(
                obscureText: true,
                textAlign: TextAlign.center,
                onSaved: (input) => loginRequestModel.password = input,
                onChanged: (value) {
                  password = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your password.',
                ),
              ),
              SizedBox(
                height: 24.0,
              ),
              RoundedButton(
                colour: Colors.red,
                title: 'Log In',
                onPressed: () {
                  if (validateAndSave()) {
                    print(loginRequestModel.toJson());

                    setState(() {
                      isApiCallProcess = true;
                    });

                    APIService apiService = new APIService();
                    apiService.login(loginRequestModel).then((value) {
                      if (value != null) {
                        setState(() {
                          isApiCallProcess = false;
                        });

                        if (value.status.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainFunctionality(),
                            ),
                          );
                          final snackBar =
                              SnackBar(content: Text("Login Successful"));
                          scaffoldKey.currentState.showSnackBar(snackBar);
                        } else {
                          final snackBar =
                              SnackBar(content: Text("Login Error"));
                          scaffoldKey.currentState.showSnackBar(snackBar);
                        }
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validateAndSave() {
    final form = globalFormKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}
