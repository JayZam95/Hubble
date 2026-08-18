import json
import os

brain_dir = r'C:\Users\OAK-Fi\.gemini\antigravity\brain'
files_to_recover = {
    'push_notification_service.dart': r'lib\core\services\push_notification_service.dart',
    'chat_screen.dart': r'lib\features\chat\presentation\screens\chat_screen.dart',
    'chat_background_view.dart': r'lib\features\chat\presentation\widgets\chat_background_view.dart',
    'map_screen.dart': r'lib\features\marketplace\presentation\screens\map_screen.dart'
}

recovered = {k: '' for k in files_to_recover.keys()}
timestamps = {k: '' for k in files_to_recover.keys()}

for root, dirs, files in os.walk(brain_dir):
    for f in files:
        if f == 'transcript_full.jsonl':
            t_path = os.path.join(root, f)
            with open(t_path, 'r', encoding='utf-8') as tf:
                for line in tf:
                    try:
                        data = json.loads(line)
                        if data.get('type') == 'TOOL_RESPONSE':
                            content = data.get('content', '')
                            if 'File Path: `file://' in content:
                                for basename, rel_path in files_to_recover.items():
                                    if basename in content and rel_path.replace('\\', '/') in content:
                                        # Parse
                                        lines = content.split('\n')
                                        source_lines = []
                                        parsing = False
                                        for l in lines:
                                            if l.startswith('1: '):
                                                parsing = True
                                            if 'The above content shows the entire' in l or 'The above content does NOT show the entire' in l:
                                                parsing = False
                                            if parsing:
                                                idx = l.find(': ')
                                                if idx != -1:
                                                    source_lines.append(l[idx+2:])
                                        
                                        if len(source_lines) > 5:
                                            # Found a version! We keep the LAST one since transcripts are chronological
                                            recovered[basename] = '\n'.join(source_lines)
                                            # print(f"Found {basename} in {t_path}")
                    except Exception as e:
                        pass

# Also try to extract from write_to_file calls!
for root, dirs, files in os.walk(brain_dir):
    for f in files:
        if f == 'transcript_full.jsonl':
            t_path = os.path.join(root, f)
            with open(t_path, 'r', encoding='utf-8') as tf:
                for line in tf:
                    try:
                        data = json.loads(line)
                        if data.get('type') == 'PLANNER_RESPONSE':
                            tool_calls = data.get('tool_calls', [])
                            for tc in tool_calls:
                                if tc.get('function', {}).get('name') == 'default_api:write_to_file':
                                    args_str = tc.get('function', {}).get('arguments', '{}')
                                    args = json.loads(args_str)
                                    target = args.get('TargetFile', '')
                                    for basename in files_to_recover.keys():
                                        if basename in target:
                                            recovered[basename] = args.get('CodeContent', '')
                    except:
                        pass

for k, v in recovered.items():
    if v:
        with open(files_to_recover[k], 'w', encoding='utf-8') as out:
            out.write(v)
        print(f'{k}: Recovered {len(v.split(chr(10)))} lines.')
    else:
        print(f'{k}: NOT FOUND in logs.')
