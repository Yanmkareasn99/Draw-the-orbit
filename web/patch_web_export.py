"""Apply BONK's iPhone Response compatibility fix after a Godot Web export."""
from pathlib import Path
import re
import sys


def patch(source: str) -> str:
    marker = '// BONK buffered Response fallback'
    if marker in source:
        return source
    start = source.index('\tfunction getTrackedResponse(response, load_status) {')
    end = source.index('\n\tfunction loadFetch(', start)
    replacement = Path(__file__).with_name('tracked_response.js').read_text(encoding='utf-8')
    source = source[:start] + '\n'.join('\t' + line for line in replacement.splitlines()) + '\n' + source[end:]
    changes = [
        ('return fetch(file).then(function (response) {', 'return fetch(file).then(async function (response) {'),
        ('const tr = getTrackedResponse(response, tracker[file]);', 'const tr = await getTrackedResponse(response, tracker[file]);'),
        ('promise.then(function (response) {', 'promise.then(async function (response) {'),
        ("const cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });",
         "const cloned = (response.headers.get('content-type') || '').split(';')[0].trim() === 'application/wasm'\n"
         "\t\t\t\t\t\t\t\t? response\n"
         "\t\t\t\t\t\t\t\t: new Response(await response.arrayBuffer(), { 'headers': [['content-type', 'application/wasm']] });"),
    ]
    for old, new in changes:
        if source.count(old) != 1:
            raise ValueError(f'Godot loader changed; review compatibility patch: {old}')
        source = source.replace(old, new, 1)
    return source


if __name__ == '__main__':
    entry = Path(sys.argv[1] if len(sys.argv) > 1 else 'index.html').resolve()
    match = re.search(r'<script src="([^"]+\.js)"', entry.read_text(encoding='utf-8'))
    if not match:
        raise SystemExit('No exported engine script found in ' + str(entry))
    engine = (entry.parent / match.group(1)).resolve()
    if not engine.is_relative_to(entry.parent):
        raise SystemExit('Engine script must be inside the export directory')
    original = engine.read_text(encoding='utf-8')
    updated = patch(original)
    if updated != original:
        engine.write_text(updated, encoding='utf-8')
        print('Patched iPhone Response compatibility: ' + ascii(engine.name))
    else:
        print('Response compatibility patch already applied: ' + ascii(engine.name))
