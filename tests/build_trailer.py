"""Rebuild the staged trailer without modifying the playable project's settings.

python tests/build_trailer.py --godot /path/to/godot
Requires imageio-ffmpeg for the final MP4 encode.
"""
from pathlib import Path
import argparse
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--godot', default=shutil.which('godot'))
parser.add_argument('--width', type=int, default=2160, choices=[1080, 2160])
args = parser.parse_args()
if not args.godot:
    parser.error('Pass --godot with the path to your Godot executable.')

root = Path(__file__).resolve().parents[1]
out = root / 'artifacts/trailer'
project = out / 'render_project'
project.mkdir(parents=True, exist_ok=True)
for folder in ['scripts', 'audio', 'assets/fonts']:
    shutil.copytree(root / folder, project / folder, dirs_exist_ok=True)
(project / 'assets/icons').mkdir(parents=True, exist_ok=True)
shutil.copy2(root / 'assets/icons/bonk-icon-512.png', project / 'assets/icons/bonk-icon-512.png')
(project / 'tests').mkdir(exist_ok=True)
for name in ['trailer_capture.gd', 'trailer_overlay.gd', 'trailer_timeline.gd']:
    shutil.copy2(root / 'tests' / name, project / 'tests' / name)
shutil.copy2(root / 'main.tscn', project / 'main.tscn')
config = (root / 'project.godot').read_text(encoding='utf-8')
height = args.width * 16 // 9
for key, old, new in [('viewport_width', 390, args.width), ('viewport_height', 844, height),
                      ('window_width_override', 390, args.width), ('window_height_override', 844, height)]:
    config = config.replace(f'{key}={old}', f'{key}={new}')
(project / 'project.godot').write_text(config, encoding='utf-8')
# Render the 360x640 composition at native 3x or 6x resolution.
view = (root / 'scripts/game_view.gd').read_text(encoding='utf-8')
view = view.replace('func screen_size() -> Vector2:\n\treturn get_viewport_rect().size',
                    'func screen_size() -> Vector2:\n\treturn g.layout_size')
(project / 'scripts/game_view.gd').write_text(view, encoding='utf-8')
# Production viewport normalization caps very large windows for interactive play.
# The capture uses a fixed logical composition instead, including deferred resizes.
game = (root / 'scripts/game.gd').read_text(encoding='utf-8')
start = game.index('func configure_viewport() -> void:')
end = game.index('func update_layout(', start)
game = game[:start] + 'func configure_viewport() -> void:\n\tupdate_layout(Vector2(360, 640))\n\n' + game[end:]
# Offline recording must keep running when the render window loses focus.
start = game.index('func _notification(what: int) -> void:')
end = game.index('func cancel_sketch()', start)
game = game[:start] + 'func _notification(_what: int) -> void:\n\tpass\n\n' + game[end:]
(project / 'scripts/game.gd').write_text(game, encoding='utf-8')

def run_godot(arguments, log_name):
    with (out / log_name).open('w', encoding='utf-8') as log:
        subprocess.run([args.godot, '--path', str(project), *arguments],
                       cwd=root, stdout=log, stderr=subprocess.STDOUT, check=True)
    if 'SCRIPT ERROR' in (out / log_name).read_text(encoding='utf-8'):
        raise RuntimeError(f'Script error; inspect {out / log_name}')

run_godot(['--headless', '--editor', '--import'], 'import.log')
run_godot(['--resolution', f'{args.width}x{height}', '--rendering-method', 'gl_compatibility',
           '--fixed-fps', '30', '--disable-vsync', '--write-movie', str(out / 'capture_highres.avi'),
           '--script', 'res://tests/trailer_capture.gd'], 'capture1080.log')
subprocess.run([sys.executable, str(root / 'tests/trailer_edit.py'), '--width', str(args.width)], cwd=root, check=True)
