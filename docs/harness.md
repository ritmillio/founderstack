# What each agent gets

Skills here are written in capability verbs ("ask with options", "spawn a
subagent"), not one harness's tool names. This table maps the verbs. When an
agent lacks a capability, the skill says so and does that step by hand; it
never claims the step ran.

| Capability | Claude Code | Codex CLI | Cursor | Gemini CLI |
|---|---|---|---|---|
| Find and load skills | `~/.claude/skills`, `.claude/skills`, or the plugin | `~/.codex/skills`, `.codex/skills` (or `.agents/skills`) | `~/.cursor/skills`, `.cursor/skills` | `~/.gemini/skills`, `.gemini/skills` |
| Start a skill by name | `/name` (plugin: `/founderstack:name`) or the Skill tool | ask for it by name | `/name` | ask for it by name |
| Read another skill when it cannot be invoked | read its `SKILL.md` | same | same | same |
| Ask the user with options | `AskUserQuestion` | ask in the reply with numbered options | its question tool | ask in the reply with numbered options |
| Spawn a subagent | the Agent tool | not built in: do the step inline, say so | its subagents | not built in: inline |
| Wait on a background process | Monitor, or a background Bash with notification | a background shell, check when it exits | a background terminal | a background shell |
| Browser for a live drive | Claude in Chrome, or Playwright MCP | Playwright if installed | its browser tools | Playwright if installed |
| Other vendors for `council` | `codex exec`, `gemini -p` if installed | `claude -p`, `gemini -p` if installed | its model picker | `claude -p`, `codex exec` if installed |

Bundled scripts need the skill's own folder. Every skill that ships a script
resolves `$SKILL_DIR` at runtime (where its `SKILL.md` lives) instead of
assuming a plugin variable, because each harness puts the folder somewhere
else.
