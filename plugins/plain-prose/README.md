# plain-prose

Plain-language prose rules for Claude Code, plus a hook that repeats them as the
conversation grows.

Two parts, used separately or together:

1. **An output style** — Orwell's six rules for prose, and a rule to lead with
   the action. Opt in; nothing changes until you turn it on.
2. **A `UserPromptSubmit` hook** — drops a one-line reminder into context every
   so often, because long conversations drift back toward padding.

The rules cover prose only: docs, PR text, commit messages, chat replies. Code,
identifiers, and API names stay exact.

## Install

```
/plugin marketplace add glhd/claude-plugins
/plugin install plain-prose@glhd-plugins
```

## Turn on the output style

```
/output-style Plain Prose
```

The plugin never sets this for you. Your own `outputStyle` setting wins until
you run the command.

## Requirement: jq

The hook needs [jq](https://jqlang.github.io/jq/download/) to read the hook
payload and measure the transcript. Without jq it sends no nudges. It says so
once a day and stays quiet otherwise.

Everything else works without jq. The output style is a plain file.

## Settings

Set these in your environment or in `env` in your Claude Code settings.

| Variable | Default | What it does |
| --- | --- | --- |
| `STYLE_NUDGE_TOKENS` | `1200` | Prose tokens the assistant must write before the next nudge. |
| `STYLE_NUDGE_TURNS` | `12` | Prompts that force a nudge even if the token count has not moved. |
| `STYLE_NUDGE_PROMPTS` | built-in list | Your own nudges, one per line. Replaces all seven defaults. |

Whichever threshold comes first fires the nudge, then both counters reset. Raise
both to nudge less; lower both to nudge more.

Custom nudges:

```bash
export STYLE_NUDGE_PROMPTS='Cut the preamble.
Numbers and units, not adjectives.'
```

Blank lines are dropped. If the variable holds nothing usable, the defaults stand.

## How the hook counts

It reads the session transcript and adds up the assistant's text blocks —
thinking, tool calls, and tool results do not count. It divides characters by
four for a token estimate. State lives in one small file per session under
`$CLAUDE_PLUGIN_DATA` (or `~/.claude/state` when that is unset), and files older
than a week are deleted.

Compaction shrinks the transcript. The hook re-anchors instead of waiting for
the count to climb back.

## Test the hook by hand

```bash
echo '{"session_id":"test","transcript_path":""}' \
  | bash plugins/plain-prose/scripts/style-nudge.sh
```

The first eleven runs print nothing: there is no transcript to measure, so the
turn counter has to reach `STYLE_NUDGE_TURNS`. The twelfth prints JSON holding
one nudge. Delete `~/.claude/state/style-nudge-test` to start over.

## License

MIT. Copyright (c) 2026 Chris Morrell.
