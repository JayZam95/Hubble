// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final file = File('lib/features/settings/presentation/screens/settings_screen.dart');
  var content = file.readAsStringSync();
  
  final target = '''
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProviderMode = user.role == UserRole.provider || user.role == UserRole.shop;

    return Scaffold(
''';

  final replacement = '''
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProviderMode = user.role == UserRole.provider || user.role == UserRole.shop;

    try {
      return Scaffold(
''';

  final target2 = '''
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
''';

  final replacement2 = '''
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
    } catch (e, stack) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crash Debug')),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText('CRASH: \\\n\\n', style: const TextStyle(color: Colors.red, fontSize: 12)),
            )
          )
        )
      );
    }
  }
''';

  content = content.replaceAll(target, replacement);
  content = content.replaceAll(target2, replacement2);
  
  file.writeAsStringSync(content);
  print('Patched successfully');
}
