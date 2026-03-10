# Contributing

Thanks for your interest in improving the Razorpay Integration Plugin for Claude Code!

## Ways to Contribute

- **Add a gotcha** — Found a Razorpay quirk not documented here? That's the most valuable contribution.
- **Improve a skill** — Better code patterns, missing edge cases, clearer instructions.
- **Add a new skill** — Cover a Razorpay feature we haven't addressed yet.
- **Add a new agent** — Automate a workflow that devs do repeatedly.
- **Fix a bug** — Typos, broken references, incorrect API usage.

## Project Structure

```
skills/           → 14 skill directories, each with a SKILL.md
agents/           → 9 agent definitions (.md files)
hooks/            → Session-start hook for auto-loading context
reference/        → API quirks and gotcha documentation
assets/           → SVG demos, social preview, logos
.claude-plugin/   → Plugin manifest (plugin.json)
```

## Adding a Skill

1. Create a directory under `skills/` (e.g., `skills/my-feature/`)
2. Add a `SKILL.md` following the existing format:
   - Clear title and description
   - Step-by-step instructions Claude can follow
   - Code examples with inline comments
   - **Gotchas section** — this is what makes the plugin valuable
3. Update `RELEASE-NOTES.md`

## Adding an Agent

1. Create a `.md` file under `agents/` (e.g., `agents/razorpay-my-agent.md`)
2. Define the agent's autonomous workflow — what it detects, builds, and validates
3. Include decision logic (if X, do Y) so Claude can work without asking
4. Update `RELEASE-NOTES.md`

## Adding a Gotcha

If you just want to document a gotcha without building a full skill:

1. Add it to `reference/razorpay-api-quirks.md`
2. Include: what happens, why it's surprising, and the fix
3. If it relates to an existing skill, add it to that skill's gotchas section too

## Pull Request Guidelines

- **One concern per PR** — don't mix a new skill with gotcha fixes
- **Test with real Razorpay API** if your change involves API calls (use test mode)
- **Include the gotcha** — if you're fixing something non-obvious, document why
- Keep code examples consistent with the existing style (Next.js App Router, TypeScript)

## Commit Messages

```
feat: Add UPI payment skill
fix: Correct webhook signature verification for edge runtime
docs: Add auto-capture gotcha to go-live checklist
```

## Code of Conduct

Be respectful and constructive. We're all here because Razorpay integration is harder than it should be.

## Questions?

Open an issue — there are no dumb questions when it comes to payment integrations.
