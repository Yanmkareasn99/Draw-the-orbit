"""Encode the captured BONK trailer and mix its original music with gameplay SFX.

Requires imageio-ffmpeg (or pass --ffmpeg PATH). Run from the project root.
"""
from pathlib import Path
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg')
parser.add_argument('--width', type=int, default=2160)
args = parser.parse_args()
if args.ffmpeg:
    ffmpeg = args.ffmpeg
else:
    import imageio_ffmpeg
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

out = Path('artifacts/trailer')
destination = out / ('BONK_Trailer_4K_60s.mp4' if args.width == 2160 else 'BONK_Trailer_60s.mp4')
audio = (
    '[0:a]volume=0.9[sfx];'
    '[1:a]volume=0.56,afade=t=out:st=59.85:d=0.4[music];'
    '[sfx][music]amix=inputs=2:duration=first:normalize=0,'
    'alimiter=limit=0.95:level=false,loudnorm=I=-14:TP=-1:LRA=9[audio]'
)
command = [ffmpeg, '-y', '-hide_banner', '-ss', str(1 / 30),
           '-i', str(out / 'capture_highres.avi'), '-stream_loop', '-1',
           '-i', 'audio/bgm.ogg', '-filter_complex', audio,
           '-map', '0:v:0', '-map', '[audio]', '-t', '60.25',
           '-vf', 'scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv420p',
           '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
           '-pix_fmt', 'yuv420p', '-colorspace', 'bt709', '-color_primaries', 'bt709',
           '-color_trc', 'bt709', '-color_range', 'tv', '-r', '30', '-c:a', 'aac', '-b:a', '192k',
           '-ar', '48000', '-movflags', '+faststart', str(destination)]
with (out / 'encode.log').open('w', encoding='utf-8') as log:
    subprocess.run(command, stdout=log, stderr=log, check=True)

if args.width == 2160:
    with (out / 'encode_1080.log').open('w', encoding='utf-8') as log:
        subprocess.run([ffmpeg, '-y', '-hide_banner', '-i', str(destination), '-vf', 'scale=1080:1920:flags=lanczos',
                        '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-c:a', 'copy',
                        '-movflags', '+faststart', str(out / 'BONK_Trailer_60s.mp4')], stdout=log, stderr=log, check=True)

for second, name in [(59.0, 'BONK_Trailer_Poster.jpg'), (59.3, 'BONK_Trailer_CTA.jpg')]:
    subprocess.run([ffmpeg, '-y', '-v', 'error', '-ss', str(second), '-i', str(destination),
                    '-frames:v', '1', '-q:v', '2', str(out / name)], check=True)

print(f'Encoded {destination} ({destination.stat().st_size / 1024**2:.1f} MiB)')
