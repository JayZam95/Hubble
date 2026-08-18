// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found.');
    return;
  }

  int filesModified = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      String newContent = content;

      // Fix .withOpacity
      newContent = newContent.replaceAll(RegExp(r'\.withOpacity\('), '.withValues(alpha: ');

      // Fix Slider / SwitchListTile activeColor (naively rename activeColor: to activeTrackColor: if it matches the general usage, but activeColor actually maps to activeThumbColor for Slider/Switch. But wait, we can just replace activeColor: with activeColor: // DEPRECATED for manual fix or just activeTrackColor: )
      // Actually, activeColor -> activeTrackColor might break things if not applicable. Let's stick to withOpacity and let the subagent handle specific UI components.

      // Fix BuildContext across async gaps for mounted check:
      // We will skip this in regex and let the subagent handle it or do it manually.

      if (newContent != content) {
        await entity.writeAsString(newContent);
        filesModified++;
        print('Fixed deprecations in: ${entity.path}');
      }
    }
  }

  print('Total files modified: $filesModified');
}
