"""Fills in build/web/sw.js after `flutter build web`.

VERSION is a hash of every built file, so each release gets a new worker
and cache; PRECACHE lists the app shell (everything except the CanvasKit
variants, which are cached on first use, and source maps).

Run: python3 tool/make_sw.py [build/web]
"""
import hashlib
import json
import os
import sys

root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(__file__), '..', 'build', 'web')
SKIP_DIRS = {'canvaskit'}
SKIP_FILES = {'sw.js', 'flutter_service_worker.js', '.last_build_id'}

files = []
for d, dirs, names in os.walk(root):
    dirs[:] = sorted(x for x in dirs
                     if not (os.path.relpath(os.path.join(d, x), root) in SKIP_DIRS))
    for n in sorted(names):
        rel = os.path.relpath(os.path.join(d, n), root).replace(os.sep, '/')
        if n in SKIP_FILES or n.endswith('.map'):
            continue
        files.append(rel)

h = hashlib.sha256()
for d, _, names in sorted(os.walk(root)):
    for n in sorted(names):
        p = os.path.join(d, n)
        if n == 'sw.js':
            continue
        h.update(os.path.relpath(p, root).encode())
        with open(p, 'rb') as f:
            h.update(f.read())
version = h.hexdigest()[:16]

precache = ['./'] + [f for f in files if f != 'index.html']
sw = os.path.join(root, 'sw.js')
with open(sw, encoding='utf-8') as f:
    src = f.read()
if '__VERSION__' not in src:
    sys.exit('sw.js already filled in (rebuild first)')
src = src.replace("'__VERSION__'", json.dumps(version))
src = src.replace('__PRECACHE__', json.dumps(precache, ensure_ascii=False))
with open(sw, 'w', encoding='utf-8') as f:
    f.write(src)
# The deprecated Flutter worker is not used.
stub = os.path.join(root, 'flutter_service_worker.js')
if os.path.exists(stub):
    os.remove(stub)
print(f'sw.js: version {version}, {len(precache)} files precached')
