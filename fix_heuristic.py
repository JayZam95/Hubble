import re
import sys

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Find all occurrences of '//'
    idx = text.find('//')
    while idx != -1:
        # Check if it's part of a URL like 'https://' or 'http://'
        if text[idx-5:idx] in ('https', 'http:'):
            idx = text.find('//', idx + 2)
            continue
            
        # Also check if it's '://'
        if text[idx-1:idx] == ':':
            idx = text.find('//', idx + 2)
            continue

        # We found a comment. Where does it end?
        # Let's search forward for a common Dart keyword, or a semicolon, or an opening brace.
        # But we must be careful: the text itself might contain these keywords!
        # So we look for a sequence of 2 or more spaces followed by a keyword, or just 3+ spaces.
        # Remember: PowerShell joined with a single space. But indentation spaces were preserved!
        # So if the original code had indentation, there will be multiple spaces!
        
        # Let's try to find a pattern: "   " (3 spaces) or "    " (4 spaces) followed by something.
        end_idx = -1
        
        # Try to find 3+ spaces
        space_match = re.search(r'   +', text[idx+2:])
        if space_match:
            end_idx = idx + 2 + space_match.start()
        else:
            # If no multiple spaces, try to find the next valid dart keyword preceded by a space.
            # This is risky, but we can print it out.
            pass
            
        if end_idx != -1:
            # Replace '//' with '/*' and insert '*/' at end_idx
            text = text[:idx] + '/*' + text[idx+2:end_idx] + '*/' + text[end_idx:]
            idx = text.find('//', end_idx + 2)
        else:
            print(f"Could not find end of comment at {idx} in {path}")
            print(text[idx:idx+100])
            break

    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

files = [
    r'lib\core\services\push_notification_service.dart',
    r'lib\features\chat\presentation\screens\chat_screen.dart',
    r'lib\features\chat\presentation\widgets\chat_background_view.dart',
    r'lib\features\marketplace\presentation\screens\map_screen.dart'
]

for p in files:
    fix_file(p)
