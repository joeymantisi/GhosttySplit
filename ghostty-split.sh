#!/usr/bin/env bash
# Launch multiple Claude instances in Ghostty splits, each in its own directory
#
# ============================================================================
# CONFIGURATION — Edit these values to customize your layout
# ============================================================================

# Number of splits (panes) to create. Each gets its own Claude instance.
SPLIT_COUNT=3

# Directories for each split. Array length must match SPLIT_COUNT.
# Each pane will cd into its directory before launching claude.
SPLIT_DIRS=(
  "$HOME/Project/MyProject1"
  "$HOME/Project/MyProject2"
  "$HOME/Project/MyProject3"
)

# Split direction: "split-right" for horizontal (side-by-side columns)
#                  "split-down"  for vertical (stacked rows)
SPLIT_DIRECTION="split-right"

# Navigation keys matching the split direction:
#   For "split-right" use Left/Right
#   For "split-down"  use Up/Down
NAV_BACK="Left"
NAV_FORWARD="Right"

# Timing (seconds) — increase if splits aren't initializing reliably
SPLIT_DELAY=0.4      # wait after creating a split
NAV_DELAY=0.15        # wait after navigating between panes
TYPE_DELAY=0.8        # wait for shell to initialize before typing
KEYSTROKE_DELAY=8     # ms between keystrokes when typing commands

# ============================================================================
# END CONFIGURATION
# ============================================================================

set -euo pipefail

DEST="com.mitchellh.ghostty"
WIN="/com/mitchellh/ghostty/window/1"
METHOD="org.gtk.Actions.Activate"

# ---------- dependency checks ----------
missing=()
command -v xdotool  &>/dev/null || missing+=(xdotool)
command -v gdbus    &>/dev/null || missing+=(libglib2.0-bin)
command -v ghostty  &>/dev/null || missing+=(ghostty)
command -v claude   &>/dev/null || missing+=(claude-code)

if (( ${#missing[@]} )); then
  echo "Error: missing dependencies — ${missing[*]}"
  echo ""
  echo "Install with:"
  for dep in "${missing[@]}"; do
    case "$dep" in
      xdotool)        echo "  sudo apt install xdotool" ;;
      libglib2.0-bin) echo "  sudo apt install libglib2.0-bin   # provides gdbus" ;;
      ghostty)        echo "  See https://ghostty.org/docs/install" ;;
      claude-code)    echo "  npm install -g @anthropic-ai/claude-code" ;;
    esac
  done
  exit 1
fi

# ---------- validate config ----------
if (( ${#SPLIT_DIRS[@]} != SPLIT_COUNT )); then
  echo "Error: SPLIT_DIRS has ${#SPLIT_DIRS[@]} entries but SPLIT_COUNT is $SPLIT_COUNT."
  echo "They must match."
  exit 1
fi

for dir in "${SPLIT_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Error: directory does not exist — $dir"
    exit 1
  fi
done

# ---------- helpers ----------
gsplit() {
  gdbus call --session --dest="$DEST" --object-path "$WIN" \
    --method "$METHOD" "$1" "[]" "{}" >/dev/null 2>&1
  sleep "$SPLIT_DELAY"
}

nav() {
  xdotool key "ctrl+alt+$1"
  sleep "$NAV_DELAY"
}

type_cmd() {
  local dir="$1"
  sleep "$TYPE_DELAY"
  xdotool type --delay "$KEYSTROKE_DELAY" "cd $dir && claude"
  xdotool key Return
  sleep 0.3
}

# ---------- build layout ----------
# Pane 1 (the original terminal) will be handled last via exec.

for (( i = 1; i < SPLIT_COUNT; i++ )); do
  if (( i == 1 )); then
    # First new split: created from pane 1
    gsplit "$SPLIT_DIRECTION"
    type_cmd "${SPLIT_DIRS[$i]}"

    # Navigate back to pane 1 so subsequent splits insert adjacent to it
    nav "$NAV_BACK"
  else
    # Create split to the right/below pane 1
    gsplit "$SPLIT_DIRECTION"
    type_cmd "${SPLIT_DIRS[$i]}"

    # Navigate back to pane 1
    for (( j = 0; j < i; j++ )); do
      nav "$NAV_BACK"
    done
  fi
done

# ---------- equalize splits ----------
sleep 0.5
gdbus call --session --dest="$DEST" --object-path "$WIN" \
  --method "$METHOD" "equalize_splits" "[]" "{}" >/dev/null 2>&1
sleep 0.3

# ---------- launch claude in pane 1 ----------
cd "${SPLIT_DIRS[0]}" || exit 1
exec claude
