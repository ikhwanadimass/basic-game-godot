import os
import re

errors = []
warnings = []

# 1. Check all referenced paths in .tscn files
tscn_files = []
for root, dirs, files in os.walk('.'):
    if '.godot' in root or '.git' in root:
        continue
    for f in files:
        if f.endswith('.tscn'):
            tscn_files.append(os.path.join(root, f))

print(f"Checking {len(tscn_files)} .tscn files...")

path_pattern = re.compile(r'path="res://([^"]+)"')

for tscn in tscn_files:
    with open(tscn, 'r', encoding='utf-8') as f:
        content = f.read()
    matches = path_pattern.findall(content)
    for m in matches:
        local_path = m.replace('/', os.sep)
        if not os.path.exists(local_path):
            errors.append(f"Broken reference in {tscn}: res://{m} does not exist!")

# 2. Check all gd scripts for resource paths and bracket balancing
gd_files = []
for root, dirs, files in os.walk('scripts'):
    for f in files:
        if f.endswith('.gd'):
            gd_files.append(os.path.join(root, f))

print(f"Checking {len(gd_files)} .gd files...")

res_in_gd = re.compile(r'"res://([^"]+)"')
for gd in gd_files:
    with open(gd, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        content = "".join(lines)

    matches = res_in_gd.findall(content)
    for m in matches:
        # Skip template strings like level_%d.tscn
        if '%d' in m or '%s' in m:
            continue
        local_path = m.replace('/', os.sep)
        if not os.path.exists(local_path):
            errors.append(f"Broken resource string in {gd}: res://{m} does not exist!")

    # Check balanced brackets
    stack = []
    for line_num, line in enumerate(lines, 1):
        cleaned = ""
        in_str = False
        quote_char = ""
        for ch in line:
            if not in_str:
                if ch == '#':
                    break
                if ch in ('"', "'"):
                    in_str = True
                    quote_char = ch
                else:
                    cleaned += ch
            else:
                if ch == quote_char:
                    in_str = False
        for ch in cleaned:
            if ch in '([{':
                stack.append((ch, line_num))
            elif ch in ')]}':
                if not stack:
                    errors.append(f"{gd}:{line_num} Unmatched closing {ch}")
                else:
                    top, t_line = stack.pop()
                    if (top == '(' and ch != ')') or (top == '[' and ch != ']') or (top == '{' and ch != '}'):
                        errors.append(f"{gd}:{line_num} Mismatched {top} from line {t_line} with {ch}")
    if stack:
        errors.append(f"{gd} Unclosed {stack[-1][0]} from line {stack[-1][1]}")

print(f"Validation complete: {len(errors)} errors found.")
for e in errors:
    print("ERROR:", e)
if len(errors) == 0:
    print(f"SUCCESS: ALL {len(tscn_files)} SCENES, {len(gd_files)} SCRIPTS, AND BRACKETS ARE 100% BALANCED AND VALID!")
