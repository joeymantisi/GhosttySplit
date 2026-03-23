# GhosttySplit

A configurable bash script that opens a Ghostty terminal, splits it into multiple panes, and launches Claude Code in each pane pointed at a specified directory.

## Dependencies

The following must be installed for the script to work:

| Dependency | Purpose | Install |
|---|---|---|
| **ghostty** | Terminal emulator with split support | [ghostty.org/docs/install](https://ghostty.org/docs/install) |
| **xdotool** | Simulates keyboard input to type commands into panes | `sudo apt install xdotool` |
| **gdbus** (libglib2.0-bin) | Sends D-Bus commands to Ghostty to create splits | `sudo apt install libglib2.0-bin` |
| **claude** (Claude Code) | The CLI launched in each pane | `npm install -g @anthropic-ai/claude-code` |

## Configuration

Edit the top of `ghostty-split.sh` to set:

- **`SPLIT_COUNT`** — number of panes to create (default: 3)
- **`SPLIT_DIRS`** — array of directories, one per pane; length must equal `SPLIT_COUNT`
- **`SPLIT_DIRECTION`** — `"split-right"` for side-by-side columns, `"split-down"` for stacked rows
- **`NAV_BACK` / `NAV_FORWARD`** — navigation keys matching the split direction (`Left`/`Right` or `Up`/`Down`)
- **Timing values** — increase delays if panes aren't initializing reliably on slower machines

## Usage

```bash
chmod +x ghostty-split.sh
./ghostty-split.sh
```

Run from inside a Ghostty terminal window. The script will split the current window and launch `claude` in each pane.

## How it works

1. The script uses `gdbus` to tell Ghostty to create splits via its D-Bus interface.
2. After each split is created, `xdotool` types `cd <dir> && claude` into the new pane.
3. Once all splits are created, it equalizes their sizes with a keybinding.
4. The original pane (pane 1) launches Claude last via `exec claude`.

## Customization tips

- To run a different command instead of `claude`, edit the `type_cmd` function and the final `exec` line.
- To add a pause between split launches (e.g. to reduce CPU load), increase `SPLIT_DELAY`.
- The script navigates back to pane 1 after each split creation to keep the layout predictable — the navigation logic auto-scales with `SPLIT_COUNT`.
