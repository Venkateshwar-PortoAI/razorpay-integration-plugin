<div align="center">

# Razorpay Integration Plugin for Claude Code

**The only Razorpay plugin that knows what the docs don't tell you.**

Production-grade billing patterns extracted from a real SaaS handling thousands of paying subscribers.

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-14-green.svg)](#skills)
[![Agents](https://img.shields.io/badge/agents-9-purple.svg)](#agents)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

[Install](#install) | [Skills](#skills) | [Agents](#agents) | [Quirks Reference](#razorpay-sdk-quirks-quick-reference)

</div>

---

> **Why this exists:** Razorpay's docs look simple. Then you hit webhook race conditions, signature mismatches on parsed JSON, TypeScript SDK type errors, GST invoicing that subscriptions don't handle, and plan changes that cause downtime. This plugin embeds all those hard-won lessons directly into Claude Code so you never have to discover them yourself.

---

## Install

```bash
git clone https://github.com/Venkateshwar-PortoAI/razorpay-integration-plugin.git
claude --plugin-dir ./razorpay-integration-plugin
```

Or via plugin marketplace:
```bash
/plugin install razorpay
```

## What Can You Do?

Just describe what you need. Claude handles the rest.

```
You:    "Set up Razorpay in my Next.js app"
Claude:  Asks for test keys -> installs SDK -> creates DB schema ->
         creates plans via API -> runs migration -> builds checkout flow

You:    "What's my MRR?"
Claude:  Queries your Razorpay account -> calculates MRR, churn, ARPU

You:    "My webhook signature is failing"
Claude:  Auto-diagnoses: you're using request.json() instead of
         request.text() -> fixes it

You:    "Refund payment pay_xxxxx"
Claude:  Issues refund via Razorpay API -> done
```

---

## Skills

### Build

| | Skill | Command | What it does |
|---|-------|---------|-------------|
| :hammer: | **Setup** | `/razorpay:setup` | SDK, env vars, DB schema, plan config — asks for keys and does everything |
| :repeat: | **Subscription** | `/razorpay:subscription` | Hosted checkout, customer upsert, popup fallback, visibility polling |
| :satellite: | **Webhook** | `/razorpay:webhook` | Signature verification, 12+ events, idempotency, optimistic locking |
| :arrows_counterclockwise: | **Plan Change** | `/razorpay:plan-change` | Upgrade/downgrade with deferred cancellation (zero downtime) |
| :credit_card: | **One-Time Payment** | `/razorpay:one-time-payment` | Orders, JS SDK checkout, HMAC verification, day passes |
| :back: | **Refund** | `/razorpay:refund` | Full/partial refunds, refund webhooks, status tracking |
| :bust_in_silhouette: | **Customer Portal** | `/razorpay:customer-portal` | Self-service billing, cancel flow, invoice download, payment update |

### Operate

| | Skill | Command | What it does |
|---|-------|---------|-------------|
| :mag: | **Admin** | `/razorpay:admin` | Query payments, subscriptions, invoices, refunds directly via API |
| :chart_with_upwards_trend: | **Metrics** | `/razorpay:metrics` | MRR, churn rate, ARPU, revenue dashboard, plan breakdown |
| :rotating_light: | **Dunning** | `/razorpay:dunning` | Failed payment recovery, grace periods, dunning emails |

### Ship & Migrate

| | Skill | Command | What it does |
|---|-------|---------|-------------|
| :test_tube: | **Local Testing** | `/razorpay:local-testing` | Test keys, ngrok, webhook registration, test cards, e2e flow |
| :rocket: | **Go-Live** | `/razorpay:go-live` | Security hardening, production checklist, compliance, monitoring |
| :truck: | **Stripe Migration** | `/razorpay:stripe-migration` | Concept mapping, event mapping, parallel running, gradual cutover |
| :wrench: | **Debug** | `/razorpay:debug` | Common issues, SDK quirks, mock payloads, diagnostic commands |

---

## Agents

Agents are autonomous workers that Claude spawns. They detect your stack, make decisions, write code, and chain into the next step.

### Builders

| | Agent | What it does |
|---|-------|-------------|
| :green_circle: | **razorpay-setup** | Asks for keys -> installs SDK -> creates env, singleton, DB schema, plans via API -> offers to build full billing flow |
| :blue_circle: | **razorpay-subscription** | Builds complete checkout flow -> auto-chains to webhook builder |
| :purple_circle: | **razorpay-webhook** | Builds production handler with 12 events -> offers to test with sample payloads |
| :large_blue_circle: | **razorpay-one-time-payment** | Builds order creation + JS SDK checkout + HMAC verification |
| :yellow_circle: | **razorpay-invoice** | Creates GST invoices via Razorpay Invoice API with CGST/SGST line items |
| :white_circle: | **razorpay-db-schema** | Detects ORM (Drizzle/Prisma/SQL) -> generates all billing tables -> runs migration |

### Testers & Reviewers

| | Agent | What it does |
|---|-------|-------------|
| :red_circle: | **razorpay-test-webhook** | Sends real payloads with valid signatures, tests idempotency, shows pass/fail |
| :red_circle: | **razorpay-diagnostics** | Checks env, credentials, code mistakes, webhook health — fully autonomous |
| :orange_circle: | **razorpay-code-audit** | Security, reliability, production readiness audit with file:line fixes |

---

## Things Razorpay Won't Tell You

> These are the gotchas that cost us weeks. Now they're in the plugin so they cost you zero.

### Subscriptions don't handle GST

Razorpay charges the plan amount as-is. It does **not** add GST, break out CGST/SGST, or generate tax invoices. You must:
- Calculate GST yourself (18% for SaaS, SAC code 998314)
- Create invoices via **Razorpay Invoice API** with separate line items (base, CGST, SGST)
- Subscription payments ≠ invoices — they're independent API entities

### Subscriptions can't be overwritten

When a user changes plans, both old and new subscriptions exist simultaneously in Razorpay. The old one must be explicitly cancelled. Your DB must support multiple subscriptions per user.

### Webhook signatures break on parsed JSON

```typescript
// WRONG — signature computed on raw string, not re-serialized JSON
const body = await request.json();
const raw = JSON.stringify(body); // whitespace differs!

// CORRECT
const raw = await request.text();
const body = JSON.parse(raw);
```

### The SDK types lie

```typescript
// TypeScript says this is wrong. It works.
await razorpay.subscriptions.cancel(id, true);

// TypeScript says this is fine. It fails.
await razorpay.customers.create({ fail_existing: 0 });
// Fix: fail_existing: 0 as 0 | 1
```

### Events arrive out of order

`subscription.pending` can arrive **after** `subscription.activated`. If you naively update status, you'll downgrade an active user. Always check current status before writing.

---

## SDK Quirks Quick Reference

| Problem | Solution |
|---------|----------|
| `subscriptions.cancel(id, ?)` — TS expects object | Use boolean: `cancel(id, true)` |
| `customers.create({ fail_existing: 0 })` — type error | Cast: `0 as 0 \| 1` |
| `current_period_end` field name varies | Try: `current_period_end` -> `current_end` -> `end_at` |
| Webhook signature on parsed JSON fails | Use `request.text()`, NOT `request.json()` |
| Invoice signature with missing fields | Use `?? ""` for optional fields in HMAC payload |
| `notify_info` with empty object errors | Only include if email/phone exist |
| Phone number with formatting chars | Strip: `.replace(/[^\d+]/g, "")` |
| Subscriptions don't generate GST invoices | Create via Invoice API with line items |
| Multiple subscriptions per user coexist | Old ones aren't deleted — check for ANY active |

---

## Tech Stack

Built for **Next.js** (App Router) but the patterns work with any Node.js backend:

| | |
|---|---|
| **Frameworks** | Next.js, Express, Fastify, Hono |
| **ORMs** | Drizzle, Prisma, raw SQL |
| **Auth** | Clerk, NextAuth, Lucia, custom |
| **Languages** | TypeScript, JavaScript |

---

## Contributing

Found a Razorpay gotcha we missed? PRs welcome. The goal is to document every production edge case so no one else has to discover them the hard way.

---

<div align="center">

**Built by [PortoAI](https://portoai.co)**

AI-powered financial assistant for Indian investors

[Website](https://portoai.co) | [GitHub](https://github.com/Venkateshwar-PortoAI)

MIT License

</div>
