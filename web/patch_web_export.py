"""Apply BONK's iPhone Response compatibility fix after a Godot Web export."""
from pathlib import Path
import re
import sys


def patch(source: str) -> str:
    if '// BONK byte loader v2' in source:
        return source
    previous_marker = '\t// BONK buffered Response fallback'
    start = source.index(previous_marker) if previous_marker in source else source.index('\tfunction getTrackedResponse(response, load_status) {')
    end = source.index('\n\tfunction loadFetch(', start)
    replacement = Path(__file__).with_name('tracked_response.js').read_text(encoding='utf-8')
    source = source[:start] + '\n'.join('\t' + line for line in replacement.splitlines()) + '\n' + source[end:]

    # Support stock exports and upgrade the previous patch. Validate all edits
    # before writing anything, so an upstream loader change cannot corrupt it.
    pattern = r'const tr = (?:await )?getTrackedResponse\(response, tracker\[file\]\);\s*if \(raw\) \{\s*return Promise.resolve\(tr\);\s*\}\s*return tr.arrayBuffer\(\);'
    source, count = re.subn(pattern, 'return getTrackedResponse(response, tracker[file]);', source)
    if count != 1:
        raise ValueError('Godot download loader changed; review compatibility patch')

    stock = "const cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });"
    previous = "const cloned = (response.headers.get('content-type') || '').split(';')[0].trim() === 'application/wasm'\n\t\t\t\t\t\t\t\t? response\n\t\t\t\t\t\t\t\t: new Response(await response.arrayBuffer(), { 'headers': [['content-type', 'application/wasm']] });"
    old = previous if previous in source else stock
    if source.count(old) != 1:
        raise ValueError('Godot MIME normalization changed; review compatibility patch')
    source = source.replace(old, 'const cloned = response;', 1)

    start = source.index("\t\t\t\tif (typeof (WebAssembly.instantiateStreaming) !== 'undefined') {")
    end = source.index('\n\t\t\t\tr = null;', start)
    source = source[:start] + '\t\t\t\tWebAssembly.instantiate(r, imports).then(done);' + source[end:]
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
