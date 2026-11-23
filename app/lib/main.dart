import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/academic_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/news_provider.dart';
import 'providers/session_provider.dart';
import 'screens/splash_screen.dart';
import 'services/n8n_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SessionProvider session = SessionProvider();
  await session.load();
  runApp(UnabApp(session: session));
}

class UnabApp extends StatelessWidget {
  const UnabApp({super.key, required this.session});

  final SessionProvider session;

  @override
  Widget build(BuildContext context) {
    final N8nService service = N8nService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(service, session),
        ),
        ChangeNotifierProvider<CalendarProvider>(
          create: (_) => CalendarProvider(service, session),
        ),
        ChangeNotifierProvider<AcademicProvider>(
          create: (_) => AcademicProvider(service, session),
        ),
        ChangeNotifierProvider<NewsProvider>(
          create: (_) => NewsProvider(service),
        ),
      ],
      child: MaterialApp(
        title: 'UNAB Apoyo Académico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
