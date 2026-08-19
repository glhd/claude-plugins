# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [semver](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [plain-prose 0.1.0] - 2026-08-19

### Added

- `Plain Prose` output style: Orwell's six rules for prose, plus a rule to lead
  with the action. Opt in with `/output-style Plain Prose`.
- `UserPromptSubmit` hook that adds one style reminder to context after the
  assistant writes `STYLE_NUDGE_TOKENS` (1200) of prose or after
  `STYLE_NUDGE_TURNS` (12) prompts, whichever lands first.
- `STYLE_NUDGE_PROMPTS` to replace the built-in reminders with your own.
