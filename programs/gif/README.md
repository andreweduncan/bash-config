# gif

Create a GIF from a video, straight from the terminal. One self-contained
script — drop it anywhere and run it. Works on **Pop!OS / Ubuntu / Debian**,
Fedora, Arch, and macOS.

## Requirements

The only dependency is **ffmpeg** (which also provides `ffprobe`):

```bash
sudo apt install ffmpeg
```

That's it — no shell config, no other tools. If ffmpeg is missing, the script
tells you exactly how to install it and exits cleanly.

## Install

Copy the `gif` script somewhere on your `PATH` and make it executable:

```bash
install -m 755 gif ~/.local/bin/gif
```

`~/.local/bin` is already on the `PATH` on a default Pop!OS setup. Then, from a
new terminal:

```bash
gif -h
```

If you'd rather not put it on your `PATH`, you can always run it directly:
`./gif video.mp4 out.gif`.

## Usage

```
gif [options] input_video

Options:
  -o <path>     Output GIF path (default: input path with a .gif extension)
  -l <seconds>  Target length of the output GIF in seconds (speeds up the
                video to fit the target length)
  -s <seconds>  Start time in the video
  -e <seconds>  End time in the video
  -f            Overwrite the output if it already exists (skip the prompt)
  -h            Show this help message
```

Only the input video is required. With no `-o`, the GIF is written **next to the
input** with the same name and a `.gif` extension (e.g. `clip.mov` → `clip.gif`).
When you do pass `-o`, the `.gif` extension is added automatically if you leave
it off.

If the output already exists, `gif` asks before overwriting (or errors out when
run non-interactively). Pass `-f` to overwrite without prompting.

## Examples

```bash
gif video.mp4                              # Convert entire video, writes video.gif alongside it
gif -o out.gif video.mp4                   # Save to a specific path
gif -s 5 video.mp4                         # Start at 5 seconds, normal speed
gif -l 3 video.mp4                         # Speed up entire video to a 3 second gif
gif -s 5 -e 15 -l 3 -o clip.gif video.mp4  # Clip 00:05–00:15 into a 3 second gif
```

## What it does

Output GIFs are 720px wide (aspect ratio preserved), 10 fps, and use a
per-clip generated color palette (`palettegen` + `paletteuse` with lanczos
scaling) for noticeably better quality than a naive conversion. Clipping and
speed-up happen before the GIF encode, so only the frames you want are
processed.
