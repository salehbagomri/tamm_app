// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib/core/widgets');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  int updatedCount = 0;
  for (var file in files) {
    String content = file.readAsStringSync();
    if (content.contains('AppColors.')) {
      
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('AppColors.')) {
          lines[i] = lines[i].replaceAll('const ', '');
        }
      }
      content = lines.join('\n');
      
      content = content.replaceAll('AppColors.', 'context.colors.');
      
      if (!content.contains('tamm_colors.dart')) {
        final lines2 = content.split('\n');
        int lastImportIndex = -1;
        for (int i = 0; i < lines2.length; i++) {
          if (lines2[i].trimLeft().startsWith('import ')) {
            lastImportIndex = i;
          }
        }
        if (lastImportIndex != -1) {
          lines2.insert(lastImportIndex + 1, "import 'package:tamm_app/core/theme/tamm_colors.dart';");
        } else {
          lines2.insert(0, "import 'package:tamm_app/core/theme/tamm_colors.dart';");
        }
        content = lines2.join('\n');
      }
      
      file.writeAsStringSync(content);
      updatedCount++;
    }
  }
  print('Updated core/widgets: ' + updatedCount.toString() + ' files.');
}
