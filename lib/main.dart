import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/store/storeitems.dart';
import 'package:surgeon_control_panel/provider/audioProvider.dart';
import 'package:surgeon_control_panel/provider/environment_state.dart';
import 'package:surgeon_control_panel/provider/home_provider.dart';
import 'package:surgeon_control_panel/provider/humidity_state.dart';
import 'package:surgeon_control_panel/provider/light_provider.dart';
import 'package:surgeon_control_panel/provider/or_status_provider.dart';
import 'package:surgeon_control_panel/provider/room_cleanliness_provider.dart';
import 'package:surgeon_control_panel/provider/temperature_state.dart';
import 'package:surgeon_control_panel/screen/cssd.dart';
import 'package:surgeon_control_panel/screen/entrance.dart';
import 'package:surgeon_control_panel/screen/home.dart';
import 'package:video_player/video_player.dart';
import 'provider/stopwatch_provider.dart';

/// ==========================
/// Localization Service
/// ==========================
class LocalizationService extends Translations {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  final Map<String, Map<String, String>> _translations = {};
  Locale _locale = const Locale('en');

  Future<void> init() async {
    try {
      for (final lang in ['en', 'hi', 'ar']) {
        final jsonStr = await rootBundle.loadString('assets/la/$lang.json');
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

/// ==========================
/// MAIN
/// ==========================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  await LocalizationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => LightProvider()),
        ChangeNotifierProvider(create: (context) => ORStatusProvider()),
        ChangeNotifierProvider(create: (context) => RoomCleanlinessProvider()),
        ChangeNotifierProvider(create: (context) => HumidityState()),
        ChangeNotifierProvider(create: (context) => TemperatureState()),
        ChangeNotifierProvider(create: (context) => EnvironmentState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString("uniqueCode");
    final mode = prefs.getString("mode");

    if (code != null && mode != null) {
      /// Return the appropriate screen based on the saved mode

      switch (mode) {
        case 'Main':
          return Home();
        case 'Entrance':
          return ORStatusMonitor();
        case 'Store':
          return HospitalStoreScreen();
        case 'CSSD':
          return CssdApp();
        default:
          return Home();
      }
    }
    return const SplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: LocalizationService.instance.locale,
          fallbackLocale: const Locale('en'),
          translations: LocalizationService.instance,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: snapshot.data!,
        );
      },
    );
  }
}

/// ==========================
/// Splash Screen
/// ==========================
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
          MaterialPageRoute(builder: (context) => const LoginPage()),
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

/// ==========================
/// Login Page
/// ==========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codeController = TextEditingController();
  String? _selectedMode;

  final List<String> _modes = ['Main', 'Entrance', 'Store', 'CSSD'];

  Future<void> _onLogin() async {
    if (_codeController.text.isEmpty || _selectedMode == null) {
      Get.snackbar(
        "Error",
        "Please enter code and select mode",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("uniqueCode", _codeController.text);
    await prefs.setString("mode", _selectedMode!);

    // Navigate to different screens based on the selected mode
    Widget nextScreen;
    switch (_selectedMode) {
      case 'Main':
        nextScreen = Home();
        break;
      case 'Entrance':
        nextScreen = ORStatusMonitor();
        break;
      case 'Store':
        nextScreen = HospitalStoreScreen();
        break;
      case 'CSSD':
        nextScreen = CssdApp();
        break;
      default:
        nextScreen = Home();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset("assets/bgi.jpg", fit: BoxFit.cover),

          // Semi-transparent overlay for readability
          Container(color: Colors.black.withOpacity(0.4)),

          // Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                color: Colors.white.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "LOGIN WITH WIESPL",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(184, 255, 255, 255),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Unique Code Field
                        TextField(
                          controller: _codeController,
                          style: const TextStyle(
                            color: Colors.black,
                          ), // input text in black
                          decoration: InputDecoration(
                            labelText: "Enter Unique Code", // label text
                            labelStyle: const TextStyle(
                              color: Colors.blueGrey,
                            ), // optional label color
                            prefixIcon: const Icon(
                              Icons.vpn_key,
                              color: Colors.blueGrey,
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(142, 255, 255, 255),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Mode Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedMode,
                          style: const TextStyle(
                            color: Colors.black,
                          ), // selected text in black
                          items: _modes
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(
                                    mode,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ), // dropdown items in black
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMode = val),
                          decoration: InputDecoration(
                            labelText: "Select Mode", // optional label
                            labelStyle: const TextStyle(color: Colors.blueGrey),
                            prefixIcon: const Icon(
                              Icons.settings_applications_outlined,
                              color: Colors.blueGrey,
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(158, 255, 255, 255),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color.fromARGB(
                                234,
                                0,
                                0,
                                0,
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(221, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
