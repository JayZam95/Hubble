import re

with open('lib/features/profile/presentation/screens/provider_setup_wizard_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import_statement = "import '../../../../core/providers/category_provider.dart';"
if import_statement not in code:
    code = code.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + import_statement)

# We need to replace the hardcoded arrays with fetches from appCategoriesProvider.
# Instead of hardcoding, we just extract them in build() or step2().
# Wait, this is a ConsumerStatefulWidget, so we can watch the provider in `build` or read it.

# Let's see the _buildStep2 signature. It doesn't have access to context? It does, it's a method inside State.
code = code.replace('final List<String> _storeCategories = [\n      "Clothing & Apparel",\n      "Electronics & Gadgets",\n      "Groceries & Food",\n      "Home & Furniture",\n      "Health & Beauty Products",\n      "Sports & Outdoors",\n      "Hardware & Tools",\n      "Other Retail"\n    ];', '')
code = code.replace('final List<String> _serviceCategories = [\n      "Plumbing & Home Repair",\n      "Education & Tutoring",\n      "Business Consulting",\n      "Technology Support",\n      "Medical & Healthcare",\n      "Creative & Design",\n      "Beauty & Wellness",\n      "Transport & Delivery",\n      "Events & Entertainment",\n      "Other Service"\n    ];', '')

code = code.replace("Widget _buildStep2(bool isDark) {", "Widget _buildStep2(bool isDark, AppCategories appCategories) {")
code = code.replace("final categories = _businessType == 'shop' ? _storeCategories : _serviceCategories;", "final categories = _businessType == 'shop' ? appCategories.retailCategories : appCategories.serviceCategories;")

code = code.replace("_buildStep2(isDark),", "ref.watch(appCategoriesProvider).when(\n                        data: (cats) => _buildStep2(isDark, cats),\n                        loading: () => const Center(child: CircularProgressIndicator()),\n                        error: (e, st) => Center(child: Text('Error loading categories')),\n                      ),")

# Also the Next button clears category if invalid. We need to use `ref.read` to check.
next_button_replacement = '''
                        if (_businessType != null) {
                          final currentCats = ref.read(appCategoriesProvider).valueOrNull;
                          if (currentCats != null) {
                            if (_businessType == 'shop' && !currentCats.retailCategories.contains(_category)) {
                              _category = null;
                            } else if (_businessType == 'individual' && !currentCats.serviceCategories.contains(_category)) {
                              _category = null;
                            }
                          }
                          _nextPage();
                        }
'''

# The original logic:
orig_logic = '''if (_businessType != null) {
                          // Clear category if business type changes
                          if (_businessType == 'shop' && !_storeCategories.contains(_category)) {
                            _category = null;
                          } else if (_businessType == 'individual' && !_serviceCategories.contains(_category)) {
                            _category = null;
                          }
                          _nextPage();
                        }'''

code = code.replace(orig_logic, next_button_replacement.strip())


with open('lib/features/profile/presentation/screens/provider_setup_wizard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
