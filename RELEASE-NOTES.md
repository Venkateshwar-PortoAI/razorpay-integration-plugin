# Release Notes

## Unreleased

- **Getting Started:** `help` — List all Razorpay commands and when to use each; suggest next step for new users.

---

## v1.0.0 — Initial Release

### Skills (14)

**Build**
- `setup` — SDK install, env vars, DB schema, plan config via API
- `subscription` — Hosted checkout, monthly/yearly, trials via `start_at`, offer codes
- `webhook` — Signature verification, 12+ events, idempotency, optimistic locking
- `plan-change` — Deferred cancellation pattern (zero downtime)
- `one-time-payment` — Orders API + JS SDK checkout + HMAC verification
- `refund` — Full/partial refunds, webhooks, status tracking
- `customer-portal` — Cancel flow with save offers, pause/resume, invoice download

**Operate**
- `admin` — Query Razorpay API directly via curl
- `metrics` — MRR, churn, ARPU, revenue dashboard
- `dunning` — Failed payment recovery, grace periods, dunning emails

**Ship & Migrate**
- `local-testing` — ngrok, test cards, webhook registration
- `go-live` — Auto-capture check, security hardening, production checklist
- `stripe-migration` — Concept mapping, parallel running, gradual cutover
- `debug` — Auto-capture diagnosis, edge runtime fix, reconciliation patterns

### Agents (9)
- `razorpay-setup` — Fully autonomous: asks for keys, installs SDK, creates plans via API, runs migrations
- `razorpay-subscription` — Builds checkout flow, auto-chains to webhook builder
- `razorpay-webhook` — 12 events, optimistic locking, offers to test
- `razorpay-one-time-payment` — Orders + JS SDK + HMAC
- `razorpay-invoice` — GST invoices via Razorpay Invoice API
- `razorpay-db-schema` — Detects ORM, generates tables, runs migration
- `razorpay-test-webhook` — Sends payloads with valid signatures, shows pass/fail
- `razorpay-diagnostics` — Checks env, credentials, code, webhook health
- `razorpay-code-audit` — Security + reliability audit with file:line fixes

### Documented Gotchas (24+)
- `authenticated` ≠ `activated` (only activated confirms payment)
- Webhook signatures require raw body (`request.text()`)
- Razorpay doesn't handle GST — Invoice API is separate
- Subscriptions can't be overwritten — both coexist
- Auto-capture silently off in production
- Edge runtime breaks `crypto.createHmac`
- No proration on plan changes
- SDK TypeScript types lie (`cancel(id, true)`, `fail_existing: 0 as 0 | 1`)
- And 16 more in the reference guide

### Infrastructure
- Session-start hook loads plugin context automatically
- Marketplace.json for plugin registry
- `.env.example` with all required vars
- Animated terminal demos in README
