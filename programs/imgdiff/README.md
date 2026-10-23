# imgdiff

`imgdiff` (in `custom_commands.sh`) highlights the pixels that differ between two
images. This folder holds its helper, `imgalign`, which lines two images up first
when they don't match exactly: screenshots taken a little differently (scrolled,
cropped, a different window size, or a Retina and a non-Retina screen), or a
"spot the difference" pair.

```bash
imgdiff before.png after.png        # same size: compared as they are
imgdiff shot1.png shot2.png         # different sizes: lined up automatically
imgdiff -f cam1.png cam2.png        # ignore small colour shifts like camera noise (-f alone: 10%)
imgdiff -a -f 10% left.jpg right.jpg   # line up same-size images too; ignore small colour shifts
imgdiff -f 10% puzzle.png           # one image holding both pictures: split, then compared
```

## One image holding both pictures

Given a single image, like a spot-the-difference puzzle, `imgdiff` finds the two
copies of the picture inside it, side by side or one above the other, with or
without a divider, titles or a frame. It splits between them and compares the two
halves.

It only splits when the two copies are clear. One image is more often a mistake
(the second image left off) than a puzzle, so otherwise it stops and suggests
either adding the second image or searching harder with `imgdiff --split`.

The copies are found by matching the image's points against themselves: in a
puzzle, almost every match agrees on one offset (the distance from one copy to
the other), across most of the picture. Repeated letters in a text screenshot
also match each other, but on many small, scattered offsets, so they're refused.
Every plausible split is tried (at a plain divider between the copies, or at the
seam) and the one where the halves overlap most is kept.

## How lining up works

`imgalign` finds distinctive points (corners, text, edges) in both images with
OpenCV's SIFT, matches them, and fits the shift (plus any scale or rotation) that
maps image2 onto image1. A plain shift is snapped to whole pixels, so screenshots
aren't resampled and still compare pixel-exactly. If too few points match, it falls
back to phase correlation, which finds a plain shift, and gives up if that result
is weak (the images probably don't show the same thing).

It then crops both images to the area they share and writes them as two same-size
images, which `imgdiff` compares with ImageMagick. Titles or margins around only
one of the pictures stay in that area, so they show up in red.

## Requirements

- ImageMagick: `brew install imagemagick`
- uv, for lining up: `brew install uv`

`imgalign` is a self-contained [uv script](https://docs.astral.sh/uv/guides/scripts/):
its dependencies (OpenCV and NumPy) are listed at the top of the file, and uv
installs them into a cached environment on the first run (about 15 seconds, once).
It can also be run on its own:

```bash
programs/imgdiff/imgalign image1.png image2.png aligned1.png aligned2.png
programs/imgdiff/imgalign --split puzzle.png first.png second.png
```
