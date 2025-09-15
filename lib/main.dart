import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
import 'package:surgeon_control_panel/screen/home.dart';
import 'package:video_player/video_player.dart';

// Localization Service
class LocalizationService extends Translations {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  final Map<String, Map<String, String>> _translations = {};
  Locale _locale = const Locale('en');

  Future<void> init() async {
    try {
      for (final lang in ['en', 'hi', 'ar']) {
        final jsonStr = await rootBundle.loadString(
          'assets/la/$lang.json',
        ); //assets\la\ar.json
        final Map<String, dynamic> data = json.decode(jsonStr);
        _translations[lang] = data.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      debugPrint('Error loading translations: $e');
      _translations['en'] = {};
      _translations['hi'] = {};
      _translations['ar'] = {};
    }
  }

  void setLocale(Locale locale) {
    _locale = locale;
    Get.updateLocale(locale);
  }

  Locale get locale => _locale;

  @override
  Map<String, Map<String, String>> get keys => _translations;

  String t(String key, {Map<String, String>? params}) {
    var text = _translations[_locale.languageCode]?[key] ?? key;
    params?.forEach((p, v) => text = text.replaceAll('{$p}', v));
    return text;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  // Initialize localization
  await LocalizationService.instance.init();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => StopwatchProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      locale: LocalizationService.instance.locale,
      fallbackLocale: const Locale('en'),
      translations: LocalizationService.instance,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('ar'), // Arabic
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/wiespl_indro.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
    _controller.setLooping(false);

    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _controller.value.isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
