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
gif [options] input_video output.gif

Options:
  -l <seconds>  Target length of the output GIF in seconds (speeds up the
                video to fit the target length)
  -s <seconds>  Start time in the video
  -e <seconds>  End time in the video
  -h            Show this help message
```

The `.gif` extension is added to the output name automatically if you leave it off.

## Examples

```bash
gif video.mp4 output                    # Convert entire video at normal speed
gif -s 5 video.mp4 output               # Start at 5 seconds, normal speed
gif -l 3 video.mp4 output               # Speed up entire video to a 3 second gif
gif -s 5 -e 15 -l 3 video.mp4 output    # Clip 00:05–00:15 into a 3 second gif
```

## What it does

Output GIFs are 720px wide (aspect ratio preserved), 10 fps, and use a
per-clip generated color palette (`palettegen` + `paletteuse` with lanczos
scaling) for noticeably better quality than a naive conversion. Clipping and
speed-up happen before the GIF encode, so only the frames you want are
processed.
