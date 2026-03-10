# Razorpay Integration Plugin for Claude Code

Production-grade Razorpay payment integration patterns for Next.js. Battle-tested in production with real paying subscribers.

Stop fighting Razorpay's undocumented quirks. This plugin gives Claude the patterns that actually work — webhook idempotency, signature verification, plan change without downtime, popup-blocked fallbacks, and GST invoice math.

## Install

```bash
# Clone and load locally
git clone https://github.com/Venkateshwar-PortoAI/razorpay-integration-plugin.git
claude --plugin-dir ./razorpay-integration-plugin
```

Or via plugin marketplace:
```bash
/plugin install razorpay
```

## Skills

### Build
| Skill | Command | Description |
|-------|---------|-------------|
| **Setup** | `/razorpay:setup` | SDK, env vars, database schema, plan configuration |
| **Subscription** | `/razorpay:subscription` | Hosted checkout, customer upsert, popup fallback, polling |
| **Webhook** | `/razorpay:webhook` | Signature verification, 12+ events, idempotency, optimistic locking |
| **Plan Change** | `/razorpay:plan-change` | Upgrade/downgrade with deferred cancellation (zero downtime) |
| **One-Time Payment** | `/razorpay:one-time-payment` | Orders, invoices, HMAC verification, day passes |
| **Refund** | `/razorpay:refund` | Full/partial refunds, refund webhooks, status tracking |
| **Customer Portal** | `/razorpay:customer-portal` | Self-service billing page, cancel flow, invoice download, payment update |

### Operate
| Skill | Command | Description |
|-------|---------|-------------|
| **Admin** | `/razorpay:admin` | Query payments, subscriptions, invoices, refunds directly via API |
| **Metrics** | `/razorpay:metrics` | MRR, churn rate, ARPU, revenue dashboard, plan breakdown |
| **Dunning** | `/razorpay:dunning` | Failed payment recovery, grace periods, dunning emails, churn prevention |

### Ship & Migrate
| Skill | Command | Description |
|-------|---------|-------------|
| **Local Testing** | `/razorpay:local-testing` | Test keys, ngrok setup, webhook registration, test cards |
| **Go-Live** | `/razorpay:go-live` | Security hardening, production checklist, compliance, monitoring |
| **Stripe Migration** | `/razorpay:stripe-migration` | Concept mapping, event mapping, parallel running, gradual migration |
| **Debug** | `/razorpay:debug` | Common issues, SDK quirks, mock payloads, diagnostic commands |

## Usage

Start a Claude Code session and use the skills:

```
# Build
/razorpay:setup                    # Set up from scratch
/razorpay:subscription             # Add subscription billing
/razorpay:webhook subscriptions    # Build webhook handler
/razorpay:plan-change              # Add plan upgrade/downgrade
/razorpay:one-time-payment order   # Add one-time purchase
/razorpay:refund partial           # Add refund handling
/razorpay:customer-portal          # Build self-service billing page

# Operate
/razorpay:admin payments           # Check payment status via API
/razorpay:metrics mrr              # Calculate your MRR
/razorpay:dunning                  # Set up failed payment recovery

# Ship & Migrate
/razorpay:local-testing            # Set up local testing with ngrok
/razorpay:go-live checklist        # Production readiness check
/razorpay:stripe-migration         # Migrate from Stripe
/razorpay:debug webhook            # Fix webhook issues
```

Or let Claude invoke them automatically — just describe what you need:

```
"I need to add Razorpay subscription billing to my Next.js app"
"My webhook signature verification is failing"
"How do I handle plan upgrades without downtime?"
"What's my MRR right now?"
"Set up dunning emails for failed payments"
"I'm migrating from Stripe to Razorpay"
"Build me a customer billing portal"
```

## Agents

Agents are autonomous workers that Claude spawns to build or review your code.

### Builders (write code)
| Agent | What it builds |
|-------|---------------|
| `razorpay-setup` | Installs SDK, creates env, singleton client, DB schema, plan config |
| `razorpay-subscription` | Full checkout flow — API route + component + polling |
| `razorpay-webhook` | Production webhook handler with 12 events + optimistic locking |
| `razorpay-one-time-payment` | Order creation + JS SDK checkout + HMAC verification |
| `razorpay-invoice` | GST calculation, invoice storage, download endpoints |
| `razorpay-db-schema` | Full billing schema for Drizzle / Prisma / raw SQL |

### Testers & Reviewers
| Agent | What it does |
|-------|-------------|
| `razorpay-test-webhook` | Sends real test payloads with valid signatures to your local endpoint |
| `razorpay-diagnostics` | Checks env vars, credentials, code mistakes, webhook health |
| `razorpay-code-audit` | Security, reliability, and production readiness audit |

## What Makes This Different

These aren't docs rewritten by AI. These are patterns extracted from a production billing system handling real money:

- **14 skills + 9 agents** covering the full billing lifecycle — build, test, ship, operate, migrate
- **Webhook idempotency** with `lastEventId` tracking and optimistic locking
- **Deferred cancellation** for plan changes — old subscription stays active until new one pays
- **Dunning & recovery** — grace periods, email sequences, involuntary churn prevention
- **Revenue metrics** — MRR, churn, ARPU calculated from your Razorpay data
- **Admin commands** — query your Razorpay account directly from Claude with curl
- **Stripe migration** — concept mapping, parallel running, gradual cutover
- **Customer portal** — self-service billing page (Razorpay doesn't have a built-in one)
- **Production hardening** — security checklist, rate limiting, compliance, monitoring
- **12 webhook events** handled with race condition guards
- **GST invoice math** with CGST/SGST breakout (required for Indian businesses)
- **Razorpay SDK TypeScript quirks** documented and solved
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
