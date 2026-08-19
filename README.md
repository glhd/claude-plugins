# Claude Code Plugins

This is a central repo for Claude Code plugins in the Claude marketplace.

Add it once:

```shell
/plugin marketplace add glhd/claude-plugins
```

Then install what you want.

## Plugins

| Plugin                             | What it does                                              |
|------------------------------------|-----------------------------------------------------------|
| [plain-prose](plugins/plain-prose) | Plain-language prose rules + periodic reminders to agent. |

### Plain Prose

```shell
/plugin install plain-prose@glhd-plugins
```

The [plain-prose](plugins/plain-prose) plugin adds two things:

1. A "Plain Prose" [output style](https://code.claude.com/docs/en/output-styles) that you can use to encourage simpler language from Claude. It is a combination of
   [George Orwell's 6 rules](https://sites.duke.edu/scientificwriting/orwells-6-rules/) and a handful of instructions about keeping output focussed.
   See [plain-prose.md](plugins/plain-prose/output-styles/plain-prose.md)
   for full content.
2. A [UserPromptSubmit hook](https://code.claude.com/docs/en/hooks#userpromptsubmit) that occasionally injects reminders like "Before you answer: what could come out without losing meaning?" into your
   ongoing Claude interactions to keep it on-track.

The combination of the two is meant to keep Claude (especially Opus 5) from veering into content that's full of jargon and needlessly technical/complex phrasing.
