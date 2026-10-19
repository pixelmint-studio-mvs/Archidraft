"""
Remove dead duplicate handlers using exact line-number detection.
Works with CRLF line endings.
"""
import os
import re

path = os.path.join(os.path.dirname(__file__), '..', 'worker', 'src', 'index.ts')

with open(path, encoding='utf-8') as f:
    content = f.read()

# Normalize to LF for easier processing, then restore CRLF at end
crlf = '\r\n' in content
lines = content.splitlines(keepends=False)

print(f"Total lines: {len(lines)}")

def find_all_occurrences(marker):
    """Return 0-indexed line numbers where marker appears."""
    return [i for i, line in enumerate(lines) if marker.strip() in line.strip()]

# ─── Locate duplicate accept handler (second occurrence) ───
accept_lines = find_all_occurrences("app.post('/api/assignments/accept'")
print(f"accept handler lines (0-indexed): {accept_lines}")

if len(accept_lines) >= 2:
    dead_start = accept_lines[1]
    # Find end: next app. route after dead_start+3
    dead_end = None
    for i in range(dead_start + 3, min(dead_start + 200, len(lines))):
        stripped = lines[i].strip()
        if stripped.startswith('app.') or stripped.startswith('// Get activity') or stripped.startswith('// Get files'):
            dead_end = i
            break
    if dead_end:
        print(f"  Removing duplicate accept/reject/submit-drawing: lines {dead_start+1}–{dead_end}")
        del lines[dead_start:dead_end]
        print(f"  After removal: {len(lines)} lines")
    else:
        print("  Could not find end of dead block 1")

# ─── Second request-correction duplicate (third occurrence) ───
rc_lines = find_all_occurrences("app.post('/api/projects/request-correction'")
print(f"request-correction lines (0-indexed): {rc_lines}")
if len(rc_lines) >= 2:
    # The second and third occurrences at 402 and 919 - keep #1 (259) only
    # Actually keep #1 (259) since it has ENGINEER/ADMIN check, #2 (402) has CLIENT check
    # Both are needed for different roles, so keep them.
    # But if there's a 3rd one, remove it.
    if len(rc_lines) >= 3:
        dead_start = rc_lines[2]
        dead_end = None
        for i in range(dead_start + 3, min(dead_start + 60, len(lines))):
            if lines[i].strip().startswith('app.') and i > dead_start + 3:
                dead_end = i
                break
        if dead_end:
            print(f"  Removing 3rd request-correction duplicate: lines {dead_start+1}–{dead_end}")
            del lines[dead_start:dead_end]
            print(f"  After removal: {len(lines)} lines")

# ─── Output ───
eol = '\r\n' if crlf else '\n'
with open(path, 'w', encoding='utf-8') as f:
    f.write(eol.join(lines) + eol)

print(f"Done. Final lines: {len(lines)}")

# Print final route list
print("\nFinal routes:")
for i, line in enumerate(lines):
    if "app.post(" in line or "app.get(" in line:
        print(f"  {i+1}: {line.strip()[:80]}")
