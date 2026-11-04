# pastebot-diff

The script behind `comp`. Run `comp` (or this script directly) to compare the
two most recently copied clippings in [Pastebot 2](https://tapbots.com/pastebot/)'s
main history. They open as a diff in Cursor: older on the left, newest on the right.

```bash
comp                      # Diff the last two clippings
comp --wait               # Wait for the diff to close, then delete its temporary files
comp --editor code        # Use the `code` command instead of Cursor
```

It reads Pastebot's database in read-only mode and does not change the system
clipboard. It compares text, including the plain-text representation of rich
text. Images and multi-item clippings produce an error instead of being skipped.

Cursor is preferred automatically, even when its `cursor` shell command isn't on
the `PATH`. If Cursor isn't installed, it falls back to `code`.

Files go into a new private temporary directory on each run. They stay there
after the diff opens by default. Add `--wait` to keep the command running until
you close the diff and delete the files afterward.

Requires Python 3 and uses only its standard library. Verified against Pastebot
2.4.8. Pastebot's storage format is undocumented, so a future app update could
require adjusting the script.
