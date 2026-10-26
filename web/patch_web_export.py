"""Apply BONK's iPhone Response compatibility fix after a Godot Web export."""
from pathlib import Path
import re
import sys


def patch(source: str) -> str:
    if '// BONK byte loader v3' in source and "fetch(file, { cache: 'no-store' })" in source:
        return source
    markers = ('\t// BONK byte loader v2', '\t// BONK buffered Response fallback')
    previous_marker = next((marker for marker in markers if marker in source), None)
    start = source.index(previous_marker) if previous_marker else source.index('\tfunction getTrackedResponse(response, load_status) {')
    end = source.index('\n\tfunction loadFetch(', start)
    replacement = Path(__file__).with_name('tracked_response.js').read_text(encoding='utf-8')
    source = source[:start] + '\n'.join('\t' + line for line in replacement.splitlines()) + '\n' + source[end:]

    # Support stock exports and upgrade the previous patch. Validate all edits
    # before writing anything, so an upstream loader change cannot corrupt it.
    pattern = r'const tr = (?:await )?getTrackedResponse\(response, tracker\[file\]\);\s*if \(raw\) \{\s*return Promise.resolve\(tr\);\s*\}\s*return tr.arrayBuffer\(\);'
    source, count = re.subn(pattern, 'return getTrackedResponse(response, tracker[file]);', source)
    if count != 1 and source.count('return getTrackedResponse(response, tracker[file]);') != 1:
        raise ValueError('Godot download loader changed; review compatibility patch')

    stock_fetch = 'return fetch(file).then(function (response) {'
    uncached_fetch = "return fetch(file, { cache: 'no-store' }).then(function (response) {"
    if uncached_fetch not in source:
        if source.count(stock_fetch) != 1:
            raise ValueError('Godot fetch call changed; review cache-bypass patch')
        source = source.replace(stock_fetch, uncached_fetch, 1)

    stock = "const cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });"
    previous = "const cloned = (response.headers.get('content-type') || '').split(';')[0].trim() === 'application/wasm'\n\t\t\t\t\t\t\t\t? response\n\t\t\t\t\t\t\t\t: new Response(await response.arrayBuffer(), { 'headers': [['content-type', 'application/wasm']] });"
    normalized = 'const cloned = response;'
    if normalized not in source:
        old = previous if previous in source else stock
        if source.count(old) != 1:
            raise ValueError('Godot MIME normalization changed; review compatibility patch')
        source = source.replace(old, normalized, 1)

    direct_instantiate = '\t\t\t\tWebAssembly.instantiate(r, imports).then(done);'
    if direct_instantiate not in source:
        start = source.index("\t\t\t\tif (typeof (WebAssembly.instantiateStreaming) !== 'undefined') {")
        end = source.index('\n\t\t\t\tr = null;', start)
        source = source[:start] + direct_instantiate + source[end:]
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
