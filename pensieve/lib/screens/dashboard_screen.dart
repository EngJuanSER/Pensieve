import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../components/theme_toggle_button.dart';
import '../models/task.dart';
import '../models/document.dart';
import '../models/note.dart';
import '../utils/file_utils.dart';
import '../components/controllers/task_controller.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Task> _recentTasks = [];
  List<Document> _recentDocuments = [];
  List<Note> _recentNotes = [];
  int _pendingTasksCount = 0;
  int _totalDocuments = 0;
  int _totalNotes = 0;
  final TaskController _taskController = TaskController();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _taskController.loadTasks();
      
      final tasksBox = await Hive.openBox<Task>('tasks');
      final documentsBox = await Hive.openBox<Document>('documents');
      final notesBox = await Hive.openBox<Note>('notes');

      if (mounted) {
        setState(() {
          _recentTasks = tasksBox.values
              .toList()
              .where((task) => !task.isCompleted)
              .toList()
            ..sort((a, b) => (a.dueDate ?? DateTime(9999))
                .compareTo(b.dueDate ?? DateTime(9999)));
          
          if (_recentTasks.length > 5) {
            _recentTasks = _recentTasks.sublist(0, 5);
          }
          _pendingTasksCount = tasksBox.values
              .where((task) => !task.isCompleted)
              .length;
          
          _recentDocuments = documentsBox.values.toList()
            ..sort((a, b) => 
                b.lastAccessed != null && a.lastAccessed != null
                  ? b.lastAccessed!.compareTo(a.lastAccessed!)
                  : b.addedAt.compareTo(a.addedAt));
          
          if (_recentDocuments.length > 4) {
            _recentDocuments = _recentDocuments.sublist(0, 4);
          }
          _totalDocuments = documentsBox.values.length;
          
          _recentNotes = notesBox.values.toList()
            ..sort((a, b) => 
                (b.modifiedAt ?? b.createdAt)
                .compareTo(a.modifiedAt ?? a.createdAt));
          
          if (_recentNotes.length > 4) {
            _recentNotes = _recentNotes.sublist(0, 4);
          }
          _totalNotes = notesBox.values.length;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF2D2D3A)
          : const Color.fromARGB(230, 221, 195, 252),
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E2C)
            : const Color.fromARGB(255, 177, 147, 204),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildQuickStatsSection(),
                    const SizedBox(height: 24),
                    _buildTasksSection(),
                    const SizedBox(height: 24),
                    _buildDocsAndNotesSection(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = '¡Buenos días!';
    } else if (hour < 18) {
      greeting = '¡Buenas tardes!';
    } else {
      greeting = '¡Buenas noches!';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenido a Pensieve, tu espacio digital para organizar tus ideas, documentos y tareas.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${now.day}/${now.month}/${now.year}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Tareas Pendientes',
            value: _pendingTasksCount.toString(),
            icon: Icons.task_alt,
            color: Colors.blue,
            onTap: () => _navigateToScreen(1), // Índice de TaskManagerScreen
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Documentos',
            value: _totalDocuments.toString(),
            icon: Icons.description,
            color: Colors.green,
            onTap: () => _navigateToScreen(2), 
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Notas',
            value: _totalNotes.toString(),
            icon: Icons.note,
            color: Colors.amber,
            onTap: () => _navigateToScreen(3), 
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value, 
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTasksSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximas Tareas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ver Todas'),
                  onPressed: () => _navigateToScreen(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No hay tareas pendientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_recentTasks.length, (index) {
                final task = _recentTasks[index];
                final isOverdue = task.dueDate != null && 
                                  task.dueDate!.isBefore(DateTime.now());
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(task.color).withOpacity(0.7),
                    child: Icon(
                      task.isCompleted ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: task.dueDate != null
                      ? Text(
                          'Vencimiento: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                          ),
                        )
                      : null,
                  trailing: task.isFavorite
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                  onTap: () {
                    _navigateToScreen(1);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDocsAndNotesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDocumentsSection(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNotesSection(),
        ),
      ],
    );
  }
  
  Widget _buildDocumentsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documentos Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ver Todos'),
                  onPressed: () => _navigateToScreen(2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentDocuments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No hay documentos recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _recentDocuments.length,
                  itemBuilder: (context, index) {
                    final document = _recentDocuments[index];
                    return InkWell(
                      onTap: () => _navigateToScreen(2),
                      borderRadius: BorderRadius.circular(8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: FileUtils.getColorForFileType(document.fileType).withOpacity(0.2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: _buildDocumentPreview(document),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    document.fileType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentPreview(Document document) {
    final extension = document.fileType.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension) &&
        document.path.isNotEmpty) {
      final file = File(document.path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDocumentIcon(document),
          ),
        );
      }
    }
    
    return _buildDocumentIcon(document);
  }
  
  Widget _buildDocumentIcon(Document document) {
    final IconData iconData = FileUtils.getIconForFileType(document.fileType);
    final Color color = FileUtils.getColorForFileType(document.fileType);
    
    return Center(
      child: Icon(
        iconData,
        size: 48,
        color: color,
      ),
    );
  }
  
  Widget _buildNotesSection() {
    const double standardFontSize = 14.0;
    final ScrollController notesScrollController = ScrollController();
    
    void _scrollLeft() {
      if (notesScrollController.hasClients) {
        final double scrollOffset = notesScrollController.offset - 250;
        notesScrollController.animateTo(
          scrollOffset < 0 ? 0 : scrollOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    void scrollRight() {
      if (notesScrollController.hasClients) {
        final double scrollOffset = notesScrollController.offset + 250;
        final double maxScrollExtent = notesScrollController.position.maxScrollExtent;
        notesScrollController.animateTo(
          scrollOffset > maxScrollExtent ? maxScrollExtent : scrollOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Notas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ver Todas'),
                  onPressed: () => _navigateToScreen(3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No hay notas recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: notesScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentNotes.length,
                      itemBuilder: (context, index) {
                        final note = _recentNotes[index];
                        return Container(
                          width: 250, 
                          margin: const EdgeInsets.only(right: 16.0),
                          child: InkWell(
                            onTap: () => _navigateToScreen(3),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(note.backgroundColor),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: const AssetImage('assets/images/lines_pattern.jpg'),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Color(note.backgroundColor).withOpacity(0.8),
                                    BlendMode.modulate,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: Color(note.textColor).withOpacity(0.8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(note.modifiedAt ?? note.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(note.textColor).withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (note.isFavorite)
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Color(note.textColor),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        note.content.isEmpty ? 'Nota vacía' : note.content,
                                        style: TextStyle(
                                          fontSize: standardFontSize,
                                          color: Color(note.textColor),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (note.tags.isNotEmpty) ...[
                                    const Divider(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: note.tags.map((tag) => Padding(
                                          padding: const EdgeInsets.only(right: 6.0),
                                          child: Chip(
                                            label: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(note.textColor),
                                              ),
                                            ),
                                            backgroundColor: Color(note.backgroundColor).withOpacity(0.7),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            labelPadding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: -4,
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black54.withOpacity(0.2)
                                : Colors.white70.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            color: Theme.of(context).primaryColor,
                            onPressed: _scrollLeft,
                            tooltip: 'Anterior',
                          ),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black54.withOpacity(0.2)
                                : Colors.white70.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            color: Theme.of(context).primaryColor,
                            onPressed: scrollRight,
                            tooltip: 'Siguiente',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _navigateToScreen(int index) {
    final bottomNavBar = context
        .findAncestorWidgetOfExactType<Scaffold>()
        ?.bottomNavigationBar as BottomNavigationBar?;

    if (bottomNavBar != null) {
      bottomNavBar.onTap?.call(index);
    }
  }
}