"""Downloads the Noto Animated Emoji used as emotes and shrinks them.

Source: https://googlefonts.github.io/noto-emoji-animation/ (Google, CC BY 4.0).
Output: assets/emotes/<id>.webp, 96 px animated WebP.
Run: python3 tool/make_emotes.py
"""
import io
import pathlib
import urllib.request

from PIL import Image

EMOTES = {
    'clap': '1f44f',
    'laugh': '1f602',
    'wow': '1f62e',
    'huff': '1f624',
    'thumbs': '1f44d',
    'pray': '1f64f',
    'think': '1f914',
    'fire': '1f525',
}
SIZE = 96
OUT = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'emotes'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, code in EMOTES.items():
        url = f'https://fonts.gstatic.com/s/e/notoemoji/latest/{code}/512.webp'
        data = urllib.request.urlopen(url).read()
        src = Image.open(io.BytesIO(data))
        frames, durations = [], []
        for i in range(src.n_frames):
            src.seek(i)
            frames.append(src.convert('RGBA').resize((SIZE, SIZE), Image.LANCZOS))
            durations.append(src.info.get('duration', 40) or 40)
        path = OUT / f'{name}.webp'
        frames[0].save(
            path, save_all=True, append_images=frames[1:], duration=durations,
            loop=0, quality=60, method=6, lossless=False,
        )
        print(name, len(frames), path.stat().st_size)


if __name__ == '__main__':
    main()
