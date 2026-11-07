import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app.dart';
import 'app_services.dart';
import 'data/content.dart';
import 'data/recitation.dart';

/// [audioBackend] replaces the audio player (the headless test device has no audio plugin).
Future<AppServices> bootstrap({http.Client? httpClient, AudioBackend Function()? audioBackend}) async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final content = await AppContent.load(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  return AppServices.create(
    content: content,
    prefs: prefs,
    httpClient: httpClient ?? http.Client(),
    audioBackend: audioBackend,
  );
}

Future<void> main() async {
  final services = await bootstrap();
  runApp(RattilApp(services: services));
}
