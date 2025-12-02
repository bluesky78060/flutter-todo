import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/category_repository.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

/// Export service for exporting todos as CSV or PDF formats
class ExportService {
  final TodoRepository _todoRepository;
  final CategoryRepository _categoryRepository;

  ExportService(
    this._todoRepository,
    this._categoryRepository,
  );

  /// Export todos as CSV file and share it
  Future<bool> exportAsCSV() async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // Fetch todos and categories
      final todosResult = await _todoRepository.getTodos();
      final categoriesResult = await _categoryRepository.getCategories();

      final todos = todosResult.fold(
        (failure) => <Todo>[],
        (todosList) => todosList,
      );

      final categories = categoriesResult.fold(
        (failure) => <Category>[],
        (categoriesList) => categoriesList,
      );

      // Create category lookup map
      final categoryMap = <int, String>{};
      for (final category in categories) {
        categoryMap[category.id] = category.name;
      }

      // Prepare CSV data with headers
      final List<List<dynamic>> csvData = [
        [
          'ID',
          '제목',
          '설명',
          '상태',
          '마감일',
          '카테고리',
          '생성일',
        ],
      ];

      // Add todo rows
      for (final todo in todos) {
        final status = todo.isCompleted ? '완료' : '미완료';
        final dueDate = todo.dueDate != null
            ? DateFormat('yyyy-MM-dd').format(todo.dueDate!)
            : '';
        final createdDate = DateFormat('yyyy-MM-dd').format(todo.createdAt);
        final categoryName = todo.categoryId != null
            ? categoryMap[todo.categoryId] ?? '미분류'
            : '미분류';

        csvData.add([
          todo.id,
          todo.title,
          todo.description,
          status,
          dueDate,
          categoryName,
          createdDate,
        ]);
      }

      // Convert to CSV string (UTF-8 encoded)
      final csvString = const ListToCsvConverter(fieldDelimiter: ',')
          .convert(csvData);

      // Save to file
      final file = await _saveFile('todo_export', 'csv', csvString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Todo Backup - ${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Export todos as PDF file and share it
  Future<bool> exportAsPDF() async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // Fetch todos and categories
      final todosResult = await _todoRepository.getTodos();
      final categoriesResult = await _categoryRepository.getCategories();

      final todos = todosResult.fold(
        (failure) => <Todo>[],
        (todosList) => todosList,
      );

      final categories = categoriesResult.fold(
        (failure) => <Category>[],
        (categoriesList) => categoriesList,
      );

      // Create category lookup map
      final categoryMap = <int, Category>{};
      for (final category in categories) {
        categoryMap[category.id] = category;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add header
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => [
            // Title
            pw.Text(
              'Todo Backup',
              style: pw.TextStyle(
                fontSize: AppColors.scaledFontSize(24),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Export date
            pw.Text(
              'Exported: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: AppColors.scaledFontSize(10)),
            ),
            pw.SizedBox(height: 16),

            // Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '요약',
                    style: pw.TextStyle(
                      fontSize: AppColors.scaledFontSize(14),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('총 할 일: ${todos.length}'),
                  pw.Text('완료: ${todos.where((t) => t.isCompleted).length}'),
                  pw.Text(
                    '완료율: ${todos.isEmpty ? '0' : ((todos.where((t) => t.isCompleted).length / todos.length) * 100).toStringAsFixed(1)}%',
                  ),
                  pw.Text('카테고리: ${categories.length}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Todos table
            if (todos.isNotEmpty) ...[
              pw.Text(
                '할 일 목록',
                style: pw.TextStyle(
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['제목', '상태', '마감일', '카테고리'],
                data: todos.map((todo) {
                  final status = todo.isCompleted ? '✓' : '';
                  final dueDate = todo.dueDate != null
                      ? DateFormat('yyyy-MM-dd').format(todo.dueDate!)
                      : '-';
                  final categoryName = todo.categoryId != null
                      ? categoryMap[todo.categoryId]?.name ?? '-'
                      : '-';

                  return [
                    todo.title.length > 30
                        ? '${todo.title.substring(0, 30)}...'
                        : todo.title,
                    status,
                    dueDate,
                    categoryName,
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: AppColors.scaledFontSize(10),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ] else ...[
              pw.Text('할 일 없음'),
            ],
          ],
        ),
      );

      // Save to file
      final bytes = await pdf.save();
      final file = await _saveBinaryFile('todo_export', 'pdf', bytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Todo Backup - ${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save text file to device
  Future<File> _saveFile(String name, String extension, String content) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${name}_$timestamp.$extension';
    final filePath = '${directory!.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);
    return file;
  }

  /// Save binary file (e.g., PDF) to device
  Future<File> _saveBinaryFile(
    String name,
    String extension,
    List<int> bytes,
  ) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${name}_$timestamp.$extension';
    final filePath = '${directory!.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
