import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/services/auth_service.dart';
import 'package:arbibot/services/api_service.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env.json
  final envString = await rootBundle.loadString('env.json');
  final env = json.decode(envString) as Map<String, dynamic>;

  // Initialize Supabase
  await Supabase.initialize(
    url: env['SUPABASE_URL'] as String,
    anonKey: env['SUPABASE_ANON_KEY'] as String,
  );

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // CRITICAL: Device orientation lock - DO NOT REMOVE
  if (!kIsWeb) {
    Future.wait([
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    ]).then((value) {
      runApp(MyApp(apiBaseUrl: env['API_BASE_URL'] as String));
    });
  } else {
    runApp(MyApp(apiBaseUrl: env['API_BASE_URL'] as String));
  }
}

class MyApp extends StatelessWidget {
  final String apiBaseUrl;
  const MyApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService(baseUrl: apiBaseUrl)),
      ],
      child: Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp(
          title: 'arbibot',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
        },
      ),
    );
  }
}
