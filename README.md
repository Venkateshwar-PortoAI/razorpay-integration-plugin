# Razorpay Integration Plugin for Claude Code

Production-grade Razorpay payment integration patterns for Next.js. Battle-tested with thousands of paying subscribers at [portoai.co](https://portoai.co).

Stop fighting Razorpay's undocumented quirks. This plugin gives Claude the patterns that actually work — webhook idempotency, signature verification, plan change without downtime, popup-blocked fallbacks, and GST invoice math.

## Install

```bash
claude /plugin install github:venkatporto/razorpay-integration-plugin
```

Or test locally:
```bash
git clone https://github.com/venkatporto/razorpay-integration-plugin.git
claude --plugin-dir ./razorpay-integration-plugin
```

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **Setup** | `/razorpay:setup` | SDK, env vars, database schema, plan configuration |
| **Subscription** | `/razorpay:subscription` | Hosted checkout, customer upsert, popup fallback, polling |
| **Webhook** | `/razorpay:webhook` | Signature verification, 12+ events, idempotency, optimistic locking |
| **Plan Change** | `/razorpay:plan-change` | Upgrade/downgrade with deferred cancellation (zero downtime) |
| **One-Time Payment** | `/razorpay:one-time-payment` | Orders, invoices, HMAC verification, day passes |
| **Debug** | `/razorpay:debug` | Common issues, SDK quirks, diagnostic commands |

## Usage

Start a Claude Code session and use the skills:

```
/razorpay:setup                    # Set up from scratch
/razorpay:subscription             # Add subscription billing
/razorpay:webhook subscriptions    # Build webhook handler
/razorpay:plan-change              # Add plan upgrade/downgrade
/razorpay:one-time-payment order   # Add one-time purchase
/razorpay:debug webhook            # Fix webhook issues
```

Or let Claude invoke them automatically — just describe what you need:

```
"I need to add Razorpay subscription billing to my Next.js app"
"My webhook signature verification is failing"
"How do I handle plan upgrades without downtime?"
```

## What Makes This Different

These aren't docs rewritten by AI. These are patterns extracted from a production billing system handling real money:

- **Webhook idempotency** with `lastEventId` tracking and optimistic locking
- **Deferred cancellation** for plan changes — old subscription stays active until new one pays
- **Popup-blocked detection** with fallback link (real browsers block popups)
- **`visibilitychange` polling** to detect payment completion across tabs
- **12 webhook events** handled with race condition guards
- **GST invoice math** with CGST/SGST breakout (required for Indian businesses)
- **Razorpay SDK TypeScript quirks** documented and solved (`cancel()` params, `fail_existing` cast, `notify_info` conditionals)
- **Timing-safe signature comparison** using `crypto.timingSafeEqual()`

## Razorpay SDK Quirks (Quick Reference)

| Problem | Solution |
|---------|----------|
| `subscriptions.cancel(id, ?)` — TS expects object | Use boolean: `cancel(id, true)` |
| `customers.create({ fail_existing: 0 })` — type error | Cast: `0 as 0 \| 1` |
| `current_period_end` field name varies | Try: `current_period_end` → `current_end` → `end_at` |
| Webhook signature on parsed JSON fails | Use `request.text()`, NOT `request.json()` |
| Invoice signature with missing fields | Use `?? ""` for optional fields in HMAC payload |
| `notify_info` with empty object errors | Only include if email/phone exist |
| Phone number with formatting chars | Strip: `.replace(/[^\d+]/g, "")` |

## Tech Stack Compatibility

Built for **Next.js** (App Router) but the patterns work with any Node.js backend:
- Express / Fastify / Hono
- Drizzle / Prisma / raw SQL
- Any auth system (Clerk, NextAuth, custom)

## Contributing

Found a Razorpay gotcha we missed? PRs welcome. The goal is to document every production edge case so no one else has to discover them the hard way.

## License

MIT

---

Built by [PortoAI](https://portoai.co) — AI-powered financial assistant for Indian investors.
