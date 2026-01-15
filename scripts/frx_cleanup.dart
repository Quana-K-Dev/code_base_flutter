#!/usr/bin/env dart

// -----------------------------------------------------------------------------
// USAGE:
//   dart run scripts/frx_cleanup.dart                    # Run for all modules
//   dart run scripts/frx_cleanup.dart reset              # Run for reset module only
//   dart run scripts/frx_cleanup.dart auth               # Run for auth module only
//   # or if executable:
//   ./scripts/frx_cleanup.dart
//   ./scripts/frx_cleanup.dart reset
//
// This script scans Dart files in the lib/ directory for freezed classes
// with @frx annotation and removes unnecessary frx imports and part statements
// according to project rules.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Script to clean up @frx annotations from freezed classes
/// Rules:
/// 1. Scan all freezed classes with @frx annotation
/// 2. For classes in part of 'parent.dart' AND no fromJson factory: remove part 'xxx.g.dart' and frx import from parent.dart
/// 3. For direct files AND no fromJson factory: remove frx import and part 'xxx.g.dart'

class FrxCleanup {
  static const String _frxImport ="import 'package:frx_annotation/frx_annotation.dart';";
  static const String _frxAnnotation = '@frx';

  /// Main entry point
  static Future<void> main(List<String> args) async {
    debugPrintSynchronously('🔍 Scanning for @frx annotations...');
    
    // Check if module parameter is provided
    String? targetModule;
    if (args.isNotEmpty) {
      targetModule = args[0];
      debugPrintSynchronously('🎯 Targeting module: $targetModule');
    }
    
    final List<String> dartFiles = await _findDartFiles(targetModule);
    final List<FrxClassInfo> frxClasses = await _scanFrxClasses(dartFiles);

    debugPrintSynchronously('📊 Found ${frxClasses.length} classes with @frx annotation to process');
    
    final classesToProcess = frxClasses; // Process all classes with @frx annotation
    
    if (classesToProcess.isEmpty) {
      debugPrintSynchronously('✅ No classes needed cleanup. All done!');
      return;
    }

    debugPrintSynchronously('🧹 Processing ${classesToProcess.length} classes with @frx annotation...');
    
    for (final FrxClassInfo classInfo in classesToProcess) {
      await _processFrxClass(classInfo);
    }

    debugPrintSynchronously('✅ Cleanup completed!');
  }
  
  /// Find all Dart files in the project (optionally filtered by module)
  static Future<List<String>> _findDartFiles([String? targetModule]) async {
    final List<String> dartFiles = <String>[];
    
    await for (final FileSystemEntity entity in Directory('lib').list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // If target module is specified, only include files from that module
        if (targetModule != null) {
          if (entity.path.contains('/modules/$targetModule/')) {
            dartFiles.add(entity.path);
          }
        } else {
          dartFiles.add(entity.path);
        }
      }
    }
    
    return dartFiles;
  }

  /// Scan for classes with @frx annotation
  static Future<List<FrxClassInfo>> _scanFrxClasses(List<String> dartFiles) async {
    final List<FrxClassInfo> frxClasses = <FrxClassInfo>[];

    // Regex để tìm các class freezed có annotation @frx
    final frxClassRegex = RegExp(
      r'@frx\s*.*?class\s+([a-zA-Z0-9_]+)\s+with\s+_\$([a-zA-Z0-9_]+)',
      dotAll: true, // Cho phép '.' khớp với cả ký tự xuống dòng
    );

    for (final String filePath in dartFiles) {
      final File file = File(filePath);
      final String content = await file.readAsString();

      if (!content.contains(_frxAnnotation)) continue;

      final bool isPartOf = content.contains('part of');
      final String? parentFile = isPartOf ? _findParentFile(content, filePath) : null;
      
      final matches = frxClassRegex.allMatches(content);

      for (final Match match in matches) {
        final className = match.group(1);
        if (className == null) continue;

        // Cải thiện việc kiểm tra fromJson: tìm chính xác factory
        final hasFromJson = _hasFromJsonFactory(content, className);
        final usesRiverpod = _usesRiverpod(content);
        
        frxClasses.add(FrxClassInfo(
          filePath: filePath,
          className: className,
          hasFromJson: hasFromJson,
          usesRiverpod: usesRiverpod,
          isPartOf: isPartOf,
          parentFile: parentFile,
        ));

        debugPrintSynchronously('  📍 Found: $className in $filePath (Has fromJson: $hasFromJson, Is part of: $isPartOf)');
      }
    }
    
    return frxClasses;
  }

  /// Check if class has fromJson factory (chính xác hơn)
  static bool _hasFromJsonFactory(String content, String className) {
    // Tìm chính xác "factory ClassName.fromJson(...)"
    final fromJsonRegex = RegExp('factory\\s+$className\\.fromJson\\s*\\(');
    return fromJsonRegex.hasMatch(content);
  }

  /// Check if class uses Riverpod (có @riverpod annotation)
  static bool _usesRiverpod(String content) {
    return content.contains('@riverpod');
  }

  /// Find parent file from part of declaration
  static String? _findParentFile(String content, String childFilePath) {
    final RegExp partOfRegex = RegExp("part of\\s+['\"]([^'\"]+)['\"]");
    final Match? match = partOfRegex.firstMatch(content);
    
    if (match == null) return null;
    
    final String parentFileName = match.group(1)!;
    // Resolve đường dẫn của file cha dựa trên vị trí file con
    final String childDir = File(childFilePath).parent.path;
    return '$childDir/$parentFileName';
  }


  /// Process frx class based on rules
  static Future<void> _processFrxClass(FrxClassInfo classInfo) async {
    await _removeFrxAnnotation(classInfo.filePath);
    debugPrintSynchronously('  -> Removed @frx annotation from ${classInfo.filePath}');

    // Với part files, cần kiểm tra @riverpod trong file cha
    bool removePartStatement;
    if (classInfo.isPartOf && classInfo.parentFile != null) {
      // Đọc nội dung file cha để kiểm tra @riverpod
      final File parentFile = File(classInfo.parentFile!);
      if (await parentFile.exists()) {
        final String parentContent = await parentFile.readAsString();
        final bool parentUsesRiverpod = _usesRiverpod(parentContent);
        removePartStatement = !classInfo.hasFromJson && !parentUsesRiverpod;
      } else {
        removePartStatement = !classInfo.hasFromJson && !classInfo.usesRiverpod;
      }
    } else {
      // Với direct files, sử dụng logic cũ
      removePartStatement = !classInfo.hasFromJson && !classInfo.usesRiverpod;
    }

    if (classInfo.isPartOf && classInfo.parentFile != null) {
      // Lấy tên file con (bao gồm cả .dart), thay .dart bằng .g.dart
      final childFileName = File(classInfo.filePath).uri.pathSegments.last;
      final partName = childFileName.replaceAll('.dart', '.g.dart');
      await _performCleanup(classInfo.parentFile!, partName, removePartStatement: removePartStatement);
      
      // Cũng xóa part statement của chính file cha nếu có
      final parentFileName = File(classInfo.parentFile!).uri.pathSegments.last;
      final parentPartName = parentFileName.replaceAll('.dart', '.g.dart');
      await _performCleanup(classInfo.parentFile!, parentPartName, removePartStatement: removePartStatement);
    } else {
      // Với direct files, chuyển đổi className thành snake_case + .g.dart
      final fileName = File(classInfo.filePath).uri.pathSegments.last;
      final partName = fileName.replaceAll('.dart', '.g.dart');
      await _performCleanup(classInfo.filePath, partName, removePartStatement: removePartStatement);
    }
  }

  /// Remove all lines containing @frx annotation from a file
  static Future<void> _removeFrxAnnotation(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    final newLines = lines.where((line) => !line.trim().contains('@frx')).toList();
    if (newLines.length != lines.length) {
      await file.writeAsString(newLines.join('\n'));
    }
  }

  /// Performs the actual file cleanup by removing frx import and the relevant part statement (not @frx annotation).
  static Future<void> _performCleanup(String filePath, String partNameOrClass, {bool removePartStatement = true}) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      debugPrintSynchronously('    ⚠️  File not found, skipping: $filePath');
      return;
    }
    String content = await file.readAsString();
    String originalContent = content;

    // 1. Remove frx import
    content = content.replaceFirst('$_frxImport\n', '');

    // 2. Remove part statement for this partNameOrClass (only if removePartStatement = true)
    if (removePartStatement) {
      // Nếu là part of, partNameOrClass là 'xxx.g.dart', nếu không là className
      final partRegex = RegExp(
        "^\\s*part\\s+['\"]${RegExp.escape(partNameOrClass)}['\"];\\s*\$",
        multiLine: true,
      );
      content = content.replaceAll(partRegex, '');
    }

    if (content != originalContent) {
      await file.writeAsString(content);
      debugPrintSynchronously('    ✅ Updated $filePath');
    } else {
      debugPrintSynchronously('    🤔 No changes needed for $filePath regarding part $partNameOrClass.');
    }
  }
}

/// Information about a class with @frx annotation
class FrxClassInfo {
  final String filePath;
  final String className;
  final bool hasFromJson;
  final bool usesRiverpod;
  final bool isPartOf;
  final String? parentFile;

  FrxClassInfo({
    required this.filePath,
    required this.className,
    required this.hasFromJson,
    required this.usesRiverpod,
    required this.isPartOf,
    this.parentFile,
  });
}

/// Run the script
void main(List<String> args) => FrxCleanup.main(args);