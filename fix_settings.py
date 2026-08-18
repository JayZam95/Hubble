import re

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import_statement = "import '../../admin/presentation/screens/category_admin_screen.dart';"
if import_statement not in code:
    code = code.replace("import 'manage_listings_screen.dart';", "import 'manage_listings_screen.dart';\n" + import_statement)

admin_tile = '''
          if (currentUser?.email == 'johnmutentwa.jr@gmail.com')
            _buildSettingsTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin: Manage Categories',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CategoryAdminScreen()),
                );
              },
            ),
'''

if 'Admin: Manage Categories' not in code:
    code = code.replace("          const SizedBox(height: 24),\n          // Legal Section", admin_tile + "          const SizedBox(height: 24),\n          // Legal Section")

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
