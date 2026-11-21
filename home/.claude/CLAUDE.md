# Global agent instructions (Alejandro)

These apply to every Claude Code session on this machine, across all repositories.

## Git commits — co-authorship

Whenever you create a git commit on my behalf, append a `Co-authored-by:`
trailer identifying the model that did the work, so my history reflects that a
Claude model (via Claude Code) co-authored it.

- Add a blank line after the commit message body, then the trailer(s).
- Use the model you are actually running as. Format:

  ```
  Co-authored-by: Claude <noreply@anthropic.com>
  ```

- Keep any other trailers (e.g. co-authors from pairing) as well.
- This applies to normal commits, amends, and squashes you author.

Example commit:

```
fix(api): handle empty payload in webhook handler

Guard against a missing body before parsing so the handler returns 400
instead of throwing.

Co-authored-by: Claude <noreply@anthropic.com>
```

## Confluence — never write to spaces I don't own without approval

Do NOT create, edit, comment on, move, or otherwise modify Confluence content in
any space other than my personal space
(`~712020bc488c2f7a784048a35a3f18f3c696e3`, "Alejandro Gomez") unless I have
explicitly directed or approved it in the current conversation.

- This covers all shared/team spaces (e.g. PM, ENG, and any client/program
  space) and includes pages, blog posts, footer/inline comments, and page moves.
- My personal space is fine to use freely for drafts and working docs.
- If a task seems to call for writing to another space, first ask me and get an
  explicit yes, naming the target space, before doing it.
- Reading/searching any space is fine; only writing is gated.

## Slack — read only

Never send, draft, schedule, react to, or edit anything in Slack. Search and
read only. The write tools are also denied in settings.

## Browser screenshots — save to file, don't attach inline

When using the chrome-devtools `take_screenshot` tool, always pass `filePath`
(e.g. under `/tmp/claude/`) so the image is written to disk instead of being
attached to the conversation. An inline image that gets rejected stays in the
session history and breaks every later request.

- Prefer `take_snapshot` (text/a11y tree) or `evaluate_script` for checking
  layout and content; only screenshot when a visual is truly needed.
- Tell me the saved path so I can open it myself.

## pstack

Before following any pstack skill (`poteto-mode`, `how`, `why`, `arena`, `swarm`, `interrogate`, `reflect`, `recall`, `architect`, `no-comments`, `setup-pstack`, `principle-*`, and the others from `cursor/plugins`), read `~/.claude/skills/pstack-compat/SKILL.md`. It maps pstack's Cursor tools, paths, models, and skill references to Claude Code.
