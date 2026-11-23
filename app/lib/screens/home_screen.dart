import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/academic_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/news_provider.dart';
import '../providers/session_provider.dart';
import 'academic_screen.dart';
import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'news_screen.dart';

/// Contenedor principal con navegación inferior entre los cuatro módulos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final Set<int> _visited = <int>{0};

  static const List<String> _titles = <String>[
    'Asistente UNAB',
    'Calendario',
    'Mi avance',
    'Noticias',
  ];

  static const List<Widget> _screens = <Widget>[
    ChatScreen(),
    CalendarScreen(),
    AcademicScreen(),
    NewsScreen(),
  ];

  Future<void> _confirmSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Quieres salir? Se borrarán el código del estudiante y la '
          'conversación actual.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    context.read<ChatProvider>().reset();
    context.read<CalendarProvider>().reset();
    context.read<AcademicProvider>().reset();
    context.read<NewsProvider>().reset();
    await context.read<SessionProvider>().signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _confirmClearChat() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nuevo chat'),
        content: const Text(
          'Se iniciará una conversación nueva y se conservará tu sesión.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empezar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ChatProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _titles[_index],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 1),
            Text(
              'Hola, ${session.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: <Widget>[
          if (_index == 0)
            IconButton(
              tooltip: 'Nuevo chat',
              onPressed: _confirmClearChat,
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: List<Widget>.generate(_screens.length, (int index) {
          if (!_visited.contains(index)) return const SizedBox.shrink();
          return _screens[index];
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) {
          setState(() {
            _index = index;
            _visited.add(index);
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Académico',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Noticias',
          ),
        ],
      ),
    );
  }
}
