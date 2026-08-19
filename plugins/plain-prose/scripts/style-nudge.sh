#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  # jq reads the hook payload and the transcript; without it there is nothing to
  # count. Say so once a day, then stay quiet.
  notice="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/state}/style-nudge-jq-missing"
  mkdir -p "${notice%/*}" 2>/dev/null || exit 0
  find "$notice" -mtime +0 -delete 2>/dev/null || true
  if [[ ! -e "$notice" ]] && : > "$notice" 2>/dev/null; then
    printf '%s\n' '{"systemMessage":"plain-prose: jq is not installed, so the style nudges are off. Install jq (https://jqlang.github.io/jq/download/) to turn them on."}'
  fi
  exit 0
fi

EVERY_TOKENS=${STYLE_NUDGE_TOKENS:-1200}
EVERY_TURNS=${STYLE_NUDGE_TURNS:-12}

NUDGES=(
  "Plain prose here: short words over long, active over passive, nothing kept that can be cut."
  "Before you answer: any term of art here that an everyday word would carry just as well?"
  "Plain prose puts the action first, numbers multi-step work, and cuts tangents."
  "Before you answer: what could come out without losing meaning?"
  "Plain language covers prose only. Code, identifiers, and API names stay exact."
  "Skip the preamble and the metaphor. Don't restate the question — answer it."
  "Terseness has a limit: if the request was for an explanation or a walkthrough, give the full one."
)

# STYLE_NUDGE_PROMPTS replaces the list above. One nudge per line; blank lines
# are dropped. If it holds nothing usable, the defaults stand.
if [[ -n "${STYLE_NUDGE_PROMPTS:-}" ]]; then
  custom=()
  while IFS= read -r line; do
    [[ -n "${line//[[:space:]]/}" ]] && custom+=("$line")
  done <<<"$STYLE_NUDGE_PROMPTS"
  (( ${#custom[@]} > 0 )) && NUDGES=("${custom[@]}")
fi

input=$(cat)

session=$(jq -r '.session_id // ""' <<<"$input")
[[ -z "$session" || "$session" == "null" ]] && session="unknown"
transcript=$(jq -r '.transcript_path // ""' <<<"$input")

dir="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/state}"; mkdir -p "$dir"
state="$dir/style-nudge-$session"

find "$dir" -name 'style-nudge-*' -type f -mtime +7 -delete 2>/dev/null || true

# Prose the reader actually sees: assistant text blocks only. Excludes thinking,
# tool calls, and tool results (those are user-role and carry no usage anyway).
# Each content block is its own transcript line sharing one message.id, so dedup
# on uuid — dedup on message.id keeps only the leading thinking line and counts
# nothing.
prose_tokens() {
  [[ -n "$transcript" && -f "$transcript" ]] || return 0
  jq -r 'select(.isSidechain != true and .message.role == "assistant")
         | [(.uuid // .message.id),
            ([.message.content[]? | select(.type == "text") | .text] | join(" ") | length)]
         | @tsv' "$transcript" 2>/dev/null \
    | awk -F'\t' '!seen[$1]++ {s+=$2} END {print int(s/4)}'
}

size=$(prose_tokens || true)
size=${size:-0}

marked=-1; fired=0; turns=0
if [[ -f "$state" ]]; then
  read -r marked fired turns < "$state" || true
fi
marked=${marked:--1}; fired=${fired:-0}; turns=${turns:-0}
turns=$((turns + 1))

if (( size <= 0 )); then
  if (( turns < EVERY_TURNS )); then
    printf '%s %s %s\n' "$marked" "$fired" "$turns" > "$state"
    exit 0
  fi
  # Fire on turns alone. Anchor at 0 if there's no waterline yet, so a
  # schema change degrades to turn-based instead of going silent.
  (( marked < 0 )) && marked=0
  size=$marked
fi

# First real reading sets the waterline.
if (( marked < 0 )); then
  printf '%s %s %s\n' "$size" "$fired" "$turns" > "$state"
  exit 0
fi

grown=$((size - marked))

# Compaction can shrink the transcript. Re-anchor instead of waiting for it
# to climb back to a stale mark.
if (( grown < 0 )); then
  printf '%s %s %s\n' "$size" "$fired" "$turns" > "$state"
  exit 0
fi

if (( grown < EVERY_TOKENS )) && (( turns < EVERY_TURNS )); then
  printf '%s %s %s\n' "$marked" "$fired" "$turns" > "$state"
  exit 0
fi

seed=$(cksum <<<"$session" | cut -d' ' -f1)
idx=$(( (seed + fired) % ${#NUDGES[@]} ))

printf '%s %s %s\n' "$size" "$((fired + 1))" 0 > "$state"

jq -n --arg ctx "${NUDGES[$idx]}" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
