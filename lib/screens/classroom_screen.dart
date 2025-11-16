import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/note_card.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/secure_pdf_viewer.dart';
import '../widgets/youtube_player_widget.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ClassroomScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassroomScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  // Default section: ملاحظات
  int _currentIndex = 0;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoadingVideos = false;
  bool _isLoadingNotes = false;
  bool _isLoadingFiles = false;
  bool _isLoadingTasks = false;
  bool _videosLoaded = false;
  bool _notesLoaded = false; // Track if notes have been loaded
  bool _filesLoaded = false; // Track if files have been loaded
  bool _tasksLoaded = false; // Track if tasks have been loaded
  // Notes filter: 0=All, 1=Last day, 2=Last week, 3=Last month
  int _notesFilter = 0;

  // Track expansion state for video and exam cards
  final Map<String, bool> _expandedStates = {};
  // Cache for submission status per taskId to avoid repeated calls
  final Map<String, bool> _taskSubmissionStatus = {};

  // Glass card helper used by files, videos, and exams
  Widget _glassCard({
    required bool isExpanded,
    required Widget child,
    bool enableBlur = true,
    String? decorSeed,
  }) {
    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF0A84FF).withOpacity(0.25)
              : Colors.black.withOpacity(0.10),
          width: isExpanded ? 1.5 : 1.2,
        ),
        boxShadow: [
          // Soft ambient shadow to lift the glass off the background
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 32,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          // Subtle rim light to enhance the glass edge
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );

    Widget decoratedContent = content;

    // Optional decorative overlay (circles and cap icon), seeded for variety
    if (decorSeed != null) {
      decoratedContent = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: _CardDecor(seed: decorSeed),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: enableBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: decoratedContent,
            )
          : decoratedContent,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load data asynchronously without blocking the UI
    Future.microtask(() {
      _loadNotes(); // Load notes when entering the class
    });
  }

  Future<void> _loadVideos() async {
    if (_isLoadingVideos) return;
    if (mounted) setState(() => _isLoadingVideos = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('=== LOADING VIDEOS ===');
      print('ClassId: ${widget.classId}');
      print('Token available: ${token != null}');
      if (token != null) {
        print('Token preview: ${token.substring(0, 20)}...');
      }

      final videos = await _apiService.listVideos(
        classId: widget.classId,
        accessToken: token,
      );
      print('=== VIDEOS LOADED ===');
      print('Videos count: ${videos.length}');
      print('Videos data: $videos');
      if (mounted) {
        setState(() {
          _videos = videos;
          _videosLoaded = true;
        });
      }
    } catch (e) {
      print('=== ERROR LOADING VIDEOS ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _loadNotes() async {
    print('Loading notes for classId: ${widget.classId}');
    setState(() => _isLoadingNotes = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final notes = await _apiService.getClassNotes(
        classId: widget.classId,
        accessToken: token,
      );
      print('Notes loaded: ${notes.length} notes');
      print('Notes data: $notes');
      setState(() {
        _notes = notes;
        _notesLoaded = true;
      });
    } catch (e) {
      print('Error loading notes: $e');
    } finally {
      setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadFiles() async {
    print('Loading files for classId: ${widget.classId}');
    setState(() => _isLoadingFiles = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final files = await _apiService.getClassFiles(
        classId: widget.classId,
        accessToken: token,
      );
      print('Files loaded: ${files.length} files');
      print('Files data: $files');
      setState(() {
        _files = files;
        _filesLoaded = true;
      });
    } catch (e) {
      print('Error loading files: $e');
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  Future<void> _loadTasks() async {
    print('Loading tasks for classId: ${widget.classId}');
    setState(() => _isLoadingTasks = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final tasks = await _apiService.getClassTasks(
        classId: widget.classId,
        accessToken: token,
      );
      print('Tasks loaded: ${tasks.length} tasks');
      print('Tasks data: $tasks');
      setState(() {
        _tasks = tasks;
        _tasksLoaded = true;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  // Build filtered items for current section based on the search query
  Widget _buildCurrentSectionList() {
    final String q = _searchController.text.trim();

    List<Map<String, dynamic>> items;
    if (_currentIndex == 0) {
      // الملاحظات (حائط ملاحظات - قراءة فقط)
      if (_isLoadingNotes) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }

      // Convert API notes to the expected format
      print('Processing ${_notes.length} notes from API');
      items = _notes.map((note) {
        print('Processing note: $note');
        // Parse createdAt to format timestamp
        String timestamp = 'غير محدد';
        if (note['createdAt'] != null) {
          try {
            final date = DateTime.parse(note['createdAt']);
            timestamp =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        final processedNote = {
          'title': 'ملاحظة',
          'content': note['msg'] ?? 'لا يوجد محتوى',
          'timestamp': timestamp,
        };
        print('Processed note: $processedNote');
        return processedNote;
      }).toList();
      print('Final items count: ${items.length}');

      // Sort: newest first (timestamp format: HH:mm yyyy-MM-dd)
      int parseTwo(String s) => int.tryParse(s) ?? 0;
      DateTime parseTs(String? ts) {
        if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
        try {
          final parts = ts.split(' '); // [HH:mm, yyyy-MM-dd]
          if (parts.length != 2) return DateTime.fromMillisecondsSinceEpoch(0);
          final time = parts[0].split(':');
          final date = parts[1].split('-');
          if (time.length != 2 || date.length != 3) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
          final hour = parseTwo(time[0]);
          final minute = parseTwo(time[1]);
          final year = int.tryParse(date[0]) ?? 1970;
          final month = parseTwo(date[1]);
          final day = parseTwo(date[2]);
          return DateTime(year, month, day, hour, minute);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }

      // Apply time filter
      DateTime now = DateTime.now();
      Duration window;
      if (_notesFilter == 1) {
        window = const Duration(days: 1);
      } else if (_notesFilter == 2) {
        window = const Duration(days: 7);
      } else if (_notesFilter == 3) {
        window = const Duration(days: 30);
      } else {
        window = Duration.zero; // all
      }

      if (window != Duration.zero) {
        final cutoff = now.subtract(window);
        items = items
            .where((m) => parseTs(m['timestamp'] as String?).isAfter(cutoff))
            .toList();
      }

      items.sort((a, b) {
        final ta = parseTs(a['timestamp'] as String?);
        final tb = parseTs(b['timestamp'] as String?);
        return tb.compareTo(ta); // newest first
      });
    } else if (_currentIndex == 1) {
      // الملفات: استخدام البيانات من API
      if (_isLoadingFiles) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }
      items = _files
          .map((file) => {
                'id': file['id'],
                'title': file['name'] ?? 'ملف غير محدد',
                'content': file['description'] ?? 'لا يوجد وصف',
                'pdfUrl': file['pdfUrl'],
                'expiresAt': file['expiresAt'],
                'isExpired': file['isExpired'] ?? false,
                'expiresAtFormatted': file['expiresAtFormatted'],
              })
          .toList();
    } else if (_currentIndex == 2) {
      // الفيديوهات: استخدام البيانات من API
      if (_isLoadingVideos) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }

      if (_videos.isEmpty) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_collection_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد فيديوهات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض الفيديوهات هنا عندما يرفعها المعلم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadVideos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      items = _videos
          .map((video) => {
                'id': video['id'],
                'videoId': video['videoId'],
                'title': video['title'],
                'description': video['description'],
                'uploadedAt': video['uploadedAt'],
                'url': video['url'],
              })
          .toList();
    } else {
      // الامتحانات: استخدام البيانات من API
      if (_isLoadingTasks) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }
      items = _tasks
          .map((task) => {
                'id': task['id'],
                'title': task['title'] ?? 'امتحان غير محدد',
                'content': task['content'] ?? 'لا يوجد وصف',
                'pdfUrl': task['pdfUrl'],
                'expiresAt': task['expiresAt'],
                'isExpired': task['isExpired'] ?? false,
                'expiresAtFormatted': task['expiresAtFormatted'],
                'deadline': task['deadline'] ?? 'غير محدد',
                'pdf':
                    '${task['title']}.pdf', // For compatibility with existing UI
              })
          .toList();
    }

    if (q.isNotEmpty) {
      items = items
          .where((m) =>
              m['title']!.contains(q) ||
              m['content']!.contains(q) ||
              (m['deadline'] ?? '').toString().contains(q))
          .toList();
    }

    // Render lists per section
    if (_currentIndex == 0) {
      // Notes
      if (items.isEmpty) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ملاحظات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض الملاحظات هنا عندما ينشرها المعلم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadNotes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadNotes,
          color: const Color(0xFF0A84FF),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => NoteCard(
              title: items[index]['title']!,
              content: items[index]['content']!,
              timestamp: items[index]['timestamp'] as String?,
              showTitle: false,
              // Student view: keep actions hidden
            ),
          ),
        ),
      );
    } else if (_currentIndex == 1) {
      // Files: API data with PDF viewing
      if (items.isEmpty) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ملفات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض الملفات هنا عندما يرفعها المعلم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadFiles,
          color: const Color(0xFF0A84FF),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = items[index];
              final fileKey = 'file_${file['id']}';
              final isExpanded = _expandedStates[fileKey] ?? false;

              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.black12,
                  hoverColor: Colors.black12,
                ),
                child: _glassCard(
                  isExpanded: isExpanded,
                  enableBlur: false,
                  decorSeed: fileKey,
                  child: ExpansionTile(
                    collapsedIconColor: const Color(0xFF0A84FF),
                    iconColor: const Color(0xFF0A84FF),
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedStates[fileKey] = expanded;
                      });
                    },
                    title: Text(
                      file['title']!,
                      style: TextStyle(
                        color:
                            isExpanded ? const Color(0xFF0A84FF) : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['content']!,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13),
                          ),
                          if (file['isExpired'] == true) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'انتهت صلاحية الرابط',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (file['expiresAtFormatted'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Color(0xFF0A84FF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ينتهي: ${_formatExpirationDate(file['expiresAtFormatted'])}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.06), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: Color(0xFFE74C3C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${file['title']}.pdf',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A84FF),
                                    Color(0xFF007AFF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PDF',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Open PDF button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 42,
                          child: TextButton.icon(
                            onPressed: file['isExpired'] == true
                                ? () => _showExpiredDialog(file['title']!)
                                : () =>
                                    _openPdf(file['pdfUrl']!, file['title']!),
                            icon: Icon(
                              file['isExpired'] == true
                                  ? Icons.warning_amber_rounded
                                  : Icons.visibility,
                              color: file['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFF0A84FF),
                            ),
                            label: Text(
                              file['isExpired'] == true
                                  ? 'انتهت الصلاحية'
                                  : 'فتح الملف',
                              style: TextStyle(
                                color: file['isExpired'] == true
                                    ? Colors.orange
                                    : const Color(0xFF0A84FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: file['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFF0A84FF),
                              side: BorderSide(
                                  color: file['isExpired'] == true
                                      ? Colors.orange
                                      : const Color(0xFF0A84FF),
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Videos: expandable cards with video player
    if (_currentIndex == 2) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadVideos,
          color: const Color(0xFF0A84FF),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final video = items[index];
              return _buildVideoCard(video);
            },
          ),
        ),
      );
    }

    // Exams: expandable cards showing teacher PDF and a submit button
    if (items.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد امتحانات بعد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض الامتحانات هنا عندما ينشرها المعلم',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _loadTasks,
        color: const Color(0xFF0A84FF),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final exam = items[index];
            final examKey = 'exam_${exam['id']}';
            final isExpanded = _expandedStates[examKey] ?? false;

            return Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.black12,
                hoverColor: Colors.black12,
              ),
              child: _glassCard(
                isExpanded: isExpanded,
                enableBlur: false,
                decorSeed: examKey,
                child: ExpansionTile(
                  collapsedIconColor: const Color(0xFF0A84FF),
                  iconColor: const Color(0xFF0A84FF),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  onExpansionChanged: (expanded) async {
                    setState(() {
                      _expandedStates[examKey] = expanded;
                    });
                    if (expanded) {
                      await _checkAndCacheSubmissionStatus(exam['id']!);
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    exam['title']!,
                    style: TextStyle(
                      color:
                          isExpanded ? const Color(0xFF0A84FF) : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['content']!,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        if (exam['isExpired'] == true) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'انتهت صلاحية الامتحان',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else if (exam['expiresAtFormatted'] != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Color(0xFF0A84FF)),
                              const SizedBox(width: 6),
                              Text(
                                'ينتهي: ${_formatExpirationDate(exam['expiresAtFormatted'])}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Color(0xFF0A84FF)),
                              const SizedBox(width: 6),
                              Text(
                                'تاريخ النشر: ${exam['deadline']}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  children: [
                    // Instructions for PDF viewing
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0A84FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF0A84FF),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'انقر على ملف PDF لعرض الامتحان',
                              style: TextStyle(
                                color: const Color(0xFF0A84FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Teacher uploaded PDF (clickable to open)
                    GestureDetector(
                      onTap: exam['isExpired'] == true
                          ? () => _showExpiredDialog(exam['title']!)
                          : (_taskSubmissionStatus[exam['id']] == true
                              ? () => _showAlreadySubmittedDialog()
                              : () => _openPdf(
                                    exam['pdfUrl']!,
                                    exam['title']!,
                                  )),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: exam['isExpired'] == true
                              ? Colors.orange.withOpacity(0.1)
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: exam['isExpired'] == true
                                  ? Colors.orange.withOpacity(0.3)
                                  : const Color(0xFF0A84FF).withOpacity(0.2),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              exam['isExpired'] == true
                                  ? Icons.warning_amber_rounded
                                  : Icons.picture_as_pdf,
                              color: exam['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                exam['pdf']!,
                                style: TextStyle(
                                    color: exam['isExpired'] == true
                                        ? Colors.orange
                                        : Colors.black,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: exam['isExpired'] == true
                                        ? const LinearGradient(
                                            colors: [
                                              Colors.orange,
                                              Colors.deepOrange
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : (_taskSubmissionStatus[exam['id']] ==
                                                true
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF16A34A),
                                                  Color(0xFF22C55E),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF0A84FF),
                                                  Color(0xFF007AFF)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exam['isExpired'] == true
                                        ? 'منتهي'
                                        : (_taskSubmissionStatus[exam['id']] ==
                                                true
                                            ? 'تم التسليم'
                                            : 'عرض'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Submit exam button (student action)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 42,
                        child: TextButton.icon(
                          onPressed: exam['isExpired'] == true
                              ? () => _showExpiredExamDialog(exam['title']!)
                              : (_taskSubmissionStatus[exam['id']] == true
                                  ? () => _showAlreadySubmittedDialog()
                                  : () => _submitExamSolution(
                                        exam['id']!,
                                        exam['title']!,
                                      )),
                          icon: Icon(
                            exam['isExpired'] == true
                                ? Icons.warning_amber_rounded
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? Icons.check_circle_outline
                                    : Icons.add),
                            color: exam['isExpired'] == true
                                ? Colors.orange
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF0A84FF)),
                          ),
                          label: Text(
                            exam['isExpired'] == true
                                ? 'انتهت الصلاحية'
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? 'تم التسليم'
                                    : 'تسليم الاختبار'),
                            style: TextStyle(
                              color: exam['isExpired'] == true
                                  ? Colors.orange
                                  : (_taskSubmissionStatus[exam['id']] == true
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF0A84FF)),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: exam['isExpired'] == true
                                ? Colors.orange
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF0A84FF)),
                            side: BorderSide(
                                color: exam['isExpired'] == true
                                    ? Colors.orange
                                    : (_taskSubmissionStatus[exam['id']] == true
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF0A84FF)),
                                width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitles = ['الملاحظات', 'الملفات', 'الفيديوهات', 'الامتحانات'];

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0A84FF)),
            onPressed: () => context.pop(),
          ),
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              widget.className,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: const Color(0xFF0A84FF),
              ),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search bar (toggleable)
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'ابحث في ${sectionTitles[_currentIndex]}...',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF0A84FF)),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide:
                              BorderSide(color: Color(0xFF0A84FF), width: 1.2),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide:
                              BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                        ),
                        fillColor: const Color(0xFFF2F2F7),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ),
              if (_showSearch) const SizedBox(height: 8),
              // Removed notes filter chips per request
              // Content
              Expanded(child: _buildCurrentSectionList()),
            ],
          ),
        ),
        bottomNavigationBar: _buildGlassBottomBar(),
      ),
    );
  }

  Widget _buildGlassBottomBar() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.sticky_note_2_outlined,
                        Icons.sticky_note_2, 'الملاحظات'),
                    _navItem(1, Icons.folder_outlined, Icons.folder, 'الملفات'),
                    _navItem(2, Icons.video_collection_outlined,
                        Icons.video_collection, 'الفيديوهات'),
                    _navItem(3, Icons.assignment_outlined, Icons.assignment,
                        'الامتحانات'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool selected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0 && !_notesLoaded) {
          _loadNotes();
        } else if (index == 1 && !_filesLoaded) {
          _loadFiles();
        } else if (index == 2 && !_videosLoaded) {
          _loadVideos();
        } else if (index == 3 && !_tasksLoaded) {
          _loadTasks();
        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 44 : 36,
              height: selected ? 44 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? Colors.white : const Color(0xFF6B7280),
                size: selected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF6B7280),
              ),
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final videoKey = 'video_${video['id']}';
    final isExpanded = _expandedStates[videoKey] ?? false;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.black12,
        hoverColor: Colors.black12,
      ),
      child: _glassCard(
        isExpanded: isExpanded,
        enableBlur: false, // Avoid blur behind WebView to prevent GPU crashes
        decorSeed: videoKey,
        child: ExpansionTile(
          collapsedIconColor: const Color(0xFF0A84FF),
          iconColor: const Color(0xFF0A84FF),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStates[videoKey] = expanded;
            });
          },
          title: Text(
            video['title']!,
            style: TextStyle(
              color: isExpanded ? const Color(0xFF0A84FF) : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (video['description'] != null &&
                    video['description'].isNotEmpty)
                  Text(
                    video['description']!,
                    style:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                if (video['uploadedAt'] != null &&
                    video['uploadedAt'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Color(0xFF0A84FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateDdMmYyyy(video['uploadedAt']),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          children: [
            // YouTube player widget wrapped with glass styling container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Build player only when expanded, to avoid recreating on collapse
                    if (isExpanded)
                      YoutubePlayerWidget(
                        videoId: video['videoId'] ?? '',
                        title: video['title'] ?? 'فيديو',
                        autoPlay: false,
                        showControls: true,
                        aspectRatio: 16 / 9,
                      )
                    else
                      Container(color: Colors.white.withOpacity(0.1)),
                    // Fullscreen button overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _playVideoFullscreen(
                            video['videoId']!, video['title']!),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateDdMmYyyy(dynamic value) {
    try {
      if (value == null) return 'غير محدد';
      DateTime d;
      if (value is String) {
        d = DateTime.parse(value);
      } else if (value is int) {
        d = value > 2000000000
            ? DateTime.fromMillisecondsSinceEpoch(value)
            : DateTime.fromMillisecondsSinceEpoch(value * 1000);
      } else if (value is double) {
        final v = value.toInt();
        d = v > 2000000000
            ? DateTime.fromMillisecondsSinceEpoch(v)
            : DateTime.fromMillisecondsSinceEpoch(v * 1000);
      } else {
        return 'غير محدد';
      }
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return 'غير محدد';
    }
  }

  void _playVideoFullscreen(String videoId, String title) {
    // Open YouTube video in fullscreen mode within the app
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => YoutubePlayerFullscreen(
          videoId: videoId,
          title: title,
        ),
      ),
    );
  }

  void _openPdf(String pdfUrl, String fileName) {
    print('=== OPENING PDF ===');
    print('PDF URL: $pdfUrl');
    print('File Name: $fileName');
    print('URL Valid: ${Uri.tryParse(pdfUrl) != null}');

    // Try secure PDF viewer first (in-app viewing)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SecurePdfViewer(
          pdfUrl: pdfUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  String _formatExpirationDate(String? isoDate) {
    if (isoDate == null) return 'غير محدد';

    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} دقيقة';
      } else {
        return 'قريباً';
      }
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _showExpiredDialog(String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'انتهت صلاحية الرابط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'انتهت صلاحية رابط الملف "$fileName". يرجى تحديث الصفحة أو التواصل مع المعلم للحصول على رابط جديد.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadFiles(); // Refresh files to get new URLs
                },
                child: const Text(
                  'تحديث الملفات',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiredExamDialog(String examTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'انتهت صلاحية الامتحان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'انتهت صلاحية الامتحان "$examTitle". لم يعد بإمكانك تسليم الحل.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitExamSolution(String taskId, String examTitle) async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;

        if (filePath == null || filePath.isEmpty) {
          _showErrorDialog('خطأ في تحديد الملف',
              'لم يتم تحديد ملف صحيح. يرجى المحاولة مرة أخرى.');
          return;
        }

        // Validate file size before upload (10MB limit)
        final fileSize = file.size;
        if (fileSize > 10 * 1024 * 1024) {
          _showErrorDialog('حجم الملف كبير جداً',
              'حجم الملف يجب أن يكون أقل من 10 ميجابايت.');
          return;
        }

        // Validate file extension
        final fileName = file.name.toLowerCase();
        final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
        final fileExtension = fileName.split('.').last;

        if (!allowedExtensions.contains(fileExtension)) {
          _showErrorDialog('نوع الملف غير مدعوم',
              'الملفات المدعومة: PDF, DOC, DOCX, JPG, JPEG, PNG');
          return;
        }

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0A84FF)),
                    const SizedBox(height: 16),
                    const Text('جاري تسليم الحل...'),
                    const SizedBox(height: 8),
                    Text(
                      'الملف: ${file.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Get token from AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        if (token == null || token.isEmpty) {
          // Close loading dialog
          Navigator.of(context).pop();
          _showErrorDialog('خطأ في المصادقة', 'يرجى تسجيل الدخول مرة أخرى.');
          return;
        }

        // Get student ID from AuthProvider
        final studentId = authProvider.user?['id']?.toString() ??
            authProvider.user?['_id']?.toString() ??
            '';

        if (studentId.isEmpty) {
          // Close loading dialog
          Navigator.of(context).pop();
          _showErrorDialog('خطأ في المصادقة', 'معرف الطالب غير متوفر.');
          return;
        }

        // Submit the solution
        final submissionResult = await _apiService.submitTaskSolution(
          studentId: studentId,
          classId: widget.classId,
          taskId: taskId,
          filePath: filePath,
          accessToken: token,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (submissionResult['success'] == true) {
          _showSuccessDialog(
            'تم تسليم الحل بنجاح',
            submissionResult['message'] ?? 'تم تسليم حل الامتحان بنجاح',
          );
          // Mark as submitted locally
          _taskSubmissionStatus[taskId] = true;
          if (mounted) setState(() {});
        } else {
          _showErrorDialog(
            'فشل في تسليم الحل',
            submissionResult['message'] ?? 'حدث خطأ أثناء تسليم الحل',
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      _showErrorDialog('خطا في تسليم الامتحان', errorMessage);
    }
  }

  Future<void> _checkAndCacheSubmissionStatus(String taskId) async {
    try {
      // If already known, skip
      if (_taskSubmissionStatus.containsKey(taskId)) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final studentId = authProvider.user?['id']?.toString() ??
          authProvider.user?['_id']?.toString() ??
          '';

      if (token == null || token.isEmpty || studentId.isEmpty) return;

      final taskDetails = await _apiService.getTaskDetails(
        classId: widget.classId,
        taskId: taskId,
        accessToken: token,
      );

      if (taskDetails == null) return;

      final submittedStudents = (taskDetails['submittedStudents'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final isSubmitted = submittedStudents.contains(studentId);
      _taskSubmissionStatus[taskId] = isSubmitted;
    } catch (e) {
      // Silent fail; keep as not submitted
    }
  }

  void _showAlreadySubmittedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF0A84FF),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'تم التسليم مسبقاً',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'لقد قمت بتسليم هذا الامتحان مسبقاً، ولا يمكنك إعادة التسليم.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardDecor extends StatelessWidget {
  final String seed;
  const _CardDecor({required this.seed});

  @override
  Widget build(BuildContext context) {
    final int hash = seed.hashCode;
    int pick(int max, int shift) => ((hash >> shift).abs() % max);
    double rnd(double min, double max, int shift) {
      final span = max - min;
      final val = ((hash >> shift).abs() % 1000) / 1000.0;
      return min + val * span;
    }

    final int variant = pick(3, 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we occupy full size to avoid unlaid out errors
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        List<Widget> children = [];

        // Large soft radial circle (top-left)
        if (variant == 0 || variant == 2) {
          final double s1 = 90 + pick(20, 9).toDouble();
          final double y1 = (height * 0.5) - (s1 / 2) + rnd(-12, 12, 71);
          children.add(Positioned(
            top: y1,
            left: -rnd(8, 20, 7),
            child: Container(
              width: s1,
              height: s1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0A84FF).withOpacity(0.18),
                    const Color(0xFF0A84FF).withOpacity(0.00),
                  ],
                  radius: 0.9,
                ),
              ),
            ),
          ));
        }

        // Graduation cap (bottom-right)
        if (variant == 1 || variant == 2) {
          children.add(Positioned(
            right: rnd(6, 18, 13),
            bottom: rnd(6, 16, 15),
            child: Icon(
              Icons.school,
              size: 28 + pick(10, 17).toDouble(),
              color: const Color(0xFF0A84FF).withOpacity(0.12),
            ),
          ));
        }

        // Small blur accent (top-right)
        children.add(Positioned(
          right: rnd(10, 24, 19),
          top: rnd(8, 18, 21),
          child: Icon(
            Icons.blur_on,
            size: 16 + pick(8, 23).toDouble(),
            color: const Color(0xFF0A84FF).withOpacity(0.16),
          ),
        ));

        // NEW: thin rings near center-right (1-2 concentric)
        final double ringBaseX = width * (0.15 + (pick(30, 25) / 100));
        final double ringBaseY = height * (0.15 + (pick(30, 27) / 100));
        final int ringCount = 1 + pick(2, 53);
        for (int r = 0; r < ringCount; r++) {
          final double size = 36 + pick(12, 29 + r).toDouble() + r * 10;
          children.add(Positioned(
            right: ringBaseX - (r * 4),
            top: ringBaseY - (r * 4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0A84FF).withOpacity(0.10 - r * 0.02),
                  width: 1.2,
                ),
                boxShadow: [
                  if (r == 0)
                    BoxShadow(
                      color: const Color(0xFF0A84FF).withOpacity(0.08),
                      blurRadius: 10,
                    ),
                ],
              ),
            ),
          ));
        }

        // NEW: a few tiny glowing dots scattered
        final int dots = 2 + pick(3, 33);
        for (int i = 0; i < dots; i++) {
          children.add(Positioned(
            left: width * (0.1 + ((pick(80, 35 + i) % 80) / 100)),
            top: height * (0.1 + ((pick(80, 41 + i) % 80) / 100)),
            child: Container(
              width: 4 + (pick(4, 45 + i) / 2),
              height: 4 + (pick(4, 49 + i) / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A84FF).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withOpacity(0.20),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ));
        }

        // NEW: diagonal soft gradient sweep
        children.add(Transform.rotate(
          angle: -0.35,
          origin: Offset(width * 0.2, height * 0.1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width * 0.35,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ));

        // Removed corner highlight circles as requested

        // NEW: gloss arc painter (top edge)
        children.add(Positioned(
          left: width * 0.15,
          top: -6,
          child: CustomPaint(
            size: Size(width * 0.5, 20),
            painter: _GlossArcPainter(opacity: 0.08),
          ),
        ));

        return SizedBox(
          width: width,
          height: height,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

class _GlossArcPainter extends CustomPainter {
  final double opacity;
  _GlossArcPainter({this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.75, 0, size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
