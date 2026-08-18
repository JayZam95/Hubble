import re

with open('lib/features/marketplace/presentation/screens/create_listing_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import_statement = "import '../../../../core/providers/category_provider.dart';"
if import_statement not in code:
    code = code.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + import_statement)

# Remove hardcoded _categories
code = code.replace('''  static const List<String> _categories = [
    // Products
    'Electronics & Mobile', 'Clothing & Apparel', 'Home & Furniture', 'Food & Groceries',
    'Vehicles', 'Property & Rentals', 'Entertainment & Hobbies', 'Toys & Games', 
    'Health & Beauty', 'Hardware & Tools', 'Office & Stationery',
    // Services
    'Plumbing', 'Electrical', 'Carpentry', 'Cleaning', 
    'Tutoring', 'Web Development', 'Graphic Design', 'Photography',
    'Event Planning', 'Delivery & Moving', 'Consulting', 'Personal Training',
    'Other Products', 'Other Services'
  ];''', '')

# In `build`, read the categories
build_categories = '''
    final categoriesAsync = ref.watch(appCategoriesProvider);
    final List<String> availableCategories = categoriesAsync.valueOrNull != null 
        ? [...categoriesAsync.value!.retailCategories, ...categoriesAsync.value!.serviceCategories]
        : [];
'''

if 'categoriesAsync' not in code:
    code = code.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n' + build_categories)

# Replace _categories in Autocomplete
code = code.replace('return _categories;', 'return availableCategories;')
code = code.replace('return _categories.where((String option) {', 'return availableCategories.where((String option) {')

with open('lib/features/marketplace/presentation/screens/create_listing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
