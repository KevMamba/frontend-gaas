//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

import 'package:flutter_sound_web/flutter_sound_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
  FlutterSoundPlugin.registerWith(registry.registrarFor(FlutterSoundPlugin));
  SharedPreferencesPlugin.registerWith(registry.registrarFor(SharedPreferencesPlugin));
  registry.registerMessageHandler();
}
