import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_protector/screen_protector.dart';

class SecurePdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const SecurePdfViewer({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  State<SecurePdfViewer> createState() => _SecurePdfViewerState();
}

class _SecurePdfViewerState extends State<SecurePdfViewer> {
  String? localPath;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;
  bool isReady = false;
  String errorMessagePDF = '';

  @override
  void initState() {
    super.initState();
    _loadPdf();
    _preventScreenshots();
  }

  @override
  void dispose() {
    _allowScreenshots();
    _cleanupTempFile();
    super.dispose();
  }

  // Prevent screenshots and screen recording
  Future<void> _preventScreenshots() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (_) {}
  }

  Future<void> _allowScreenshots() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {}
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      print('=== PDF DOWNLOAD DEBUG ===');
      print('PDF URL: ${widget.pdfUrl}');
      print('File Name: ${widget.fileName}');
      print('URL Length: ${widget.pdfUrl.length}');

      // Request storage permission first
      await _requestStoragePermission();

      // Download PDF to temporary file
      final response = await http.get(Uri.parse(widget.pdfUrl));

      print('PDF Response Status: ${response.statusCode}');
      print('PDF Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        print('PDF Downloaded: ${bytes.length} bytes');

        // Try multiple approaches to save the file
        String? filePath = await _savePdfFile(bytes);

        if (filePath != null) {
          setState(() {
            localPath = filePath;
            isLoading = false;
          });
        } else {
          throw Exception('فشل في حفظ الملف محلياً');
        }
      } else if (response.statusCode == 403) {
        // URL expired or access denied
        print('PDF Access Denied/Expired: ${response.statusCode}');
        print('PDF Response Body: ${response.body}');
        throw Exception('انتهت صلاحية رابط الملف أو تم رفض الوصول');
      } else {
        print('PDF Download Failed: ${response.statusCode}');
        print('PDF Response Body: ${response.body}');
        throw Exception('فشل في تحميل الملف: ${response.statusCode}');
      }
    } catch (e) {
      print('PDF Download Exception: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'فشل في تحميل الملف: $e';
      });
    }
  }

  Future<void> _cleanupTempFile() async {
    if (localPath != null) {
      try {
        final file = File(localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error cleaning up temp file: $e');
      }
    }
  }

  Future<void> _requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        print('Storage permission denied');
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  Future<String?> _savePdfFile(Uint8List bytes) async {
    try {
      // Method 1: Try getTemporaryDirectory
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.fileName}.pdf');
        await tempFile.writeAsBytes(bytes);
        print('PDF Saved to temp directory: ${tempFile.path}');
        return tempFile.path;
      } catch (e) {
        print('Temp directory failed: $e');
      }

      // Method 2: Try getApplicationDocumentsDirectory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final appFile = File('${appDir.path}/${widget.fileName}.pdf');
        await appFile.writeAsBytes(bytes);
        print('PDF Saved to app directory: ${appFile.path}');
        return appFile.path;
      } catch (e) {
        print('App directory failed: $e');
      }

      // Method 3: Try external storage
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final externalFile =
              File('${externalDir.path}/${widget.fileName}.pdf');
          await externalFile.writeAsBytes(bytes);
          print('PDF Saved to external directory: ${externalFile.path}');
          return externalFile.path;
        }
      } catch (e) {
        print('External directory failed: $e');
      }

      return null;
    } catch (e) {
      print('All save methods failed: $e');
      return null;
    }
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Cannot launch URL: $uri');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الرابط في المتصفح'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error opening in browser: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح الرابط: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (isReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الملف...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadPdf,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('فتح في المتصفح'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'إذا استمرت المشكلة، جرب فتح الملف في المتصفح',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (localPath == null) {
      return const Center(
        child: Text(
          'لم يتم العثور على الملف',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
          isReady = true;
        });
      },
      onViewCreated: (PDFViewController pdfViewController) {
        // PDF viewer is ready
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          hasError = true;
          errorMessage = 'خطأ في عرض الملف: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          hasError = true;
          errorMessage = 'خطأ في الصفحة $page: $error';
        });
      },
    );
  }
}
