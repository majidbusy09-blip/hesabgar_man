// ===== main.dart =====
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core.dart';
import 'features.dart';
import 'checks.dart' show CheckDetailPage;
import 'notifications.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotifications.instance.init();
  AppNotifications.instance.onNotificationTap = _handleNotifPayload;
  // اگر اپ از اعلان سرد شروع شده
  final launch = AppNotifications.pendingPayload;
  if (launch != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotifPayload(launch);
    });
  }
  runApp(const HesabgarManApp());
}

void _handleNotifPayload(String payload) {
  if (payload.startsWith('check:')) {
    final id = payload.substring(6);
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      AppNotifications.pendingPayload = payload;
      return;
    }
    // تأخیر کوتاه تا UI آماده شود
    Future.microtask(() {
      nav.push(
        MaterialPageRoute(
          builder: (_) => CheckDetailPage(checkId: id),
        ),
      );
    });
  }
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
            navigatorKey: appNavigatorKey,
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
