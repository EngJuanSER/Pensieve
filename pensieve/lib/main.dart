import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/theme_provider.dart';
import 'models/note_adapter.dart';
import 'models/document_adapter.dart';
import 'models/task_adapter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_manager_screen.dart';
import 'screens/document_library_screen.dart';
import 'screens/notes_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Archivo .env cargado correctamente');
  } catch (e) {
    debugPrint('❌ Error al cargar el archivo .env: $e');
  }

  await Hive.initFlutter();

  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(DocumentAdapter());
  Hive.registerAdapter(TaskAdapter());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Pensieve',
          theme: themeProvider.theme,
          home: const MainScreen(),  
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  static const List<Widget> widgetOptions = <Widget>[
    DashboardScreen(),
    TaskManagerScreen(),
    DocumentLibraryScreen(),
    NotesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 221, 195, 252),
      body: Center(
        child: widgetOptions.elementAt(selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: const Color.fromARGB(248, 164, 143, 189),
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color.fromARGB(248, 164, 143, 189),
            icon: Icon(Icons.task),
            label: 'Tareas',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color.fromARGB(248, 164, 143, 189),
            icon: Icon(Icons.library_books),
            label: 'Documentos',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color.fromARGB(248, 164, 143, 189),
            icon: Icon(Icons.note),
            label: 'Notas',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor:  const Color.fromARGB(255, 53, 45, 63),
        onTap: _onItemTapped,
      ),
    );
  }
}