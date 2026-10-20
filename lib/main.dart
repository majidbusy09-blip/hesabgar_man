// ===== main.dart =====
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core.dart';
import 'features.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HesabgarManApp());
}

class HesabgarManApp extends StatelessWidget {
  const HesabgarManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          if (themeProvider.loading) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return MaterialApp(
            title: 'حسابگر من',
            debugShowCheckedModeBanner: false,
            locale: const Locale('fa', 'IR'),
            supportedLocales: const [Locale('fa', 'IR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: themeProvider.theme,
            home: const BrandSplash(child: MainScaffold()),
          );
        },
      ),
    );
  }
}
