#!/usr/bin/env bash
# SessionStart hook for Razorpay Integration Plugin
# Reminds Claude about available Razorpay skills when a session starts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cat <<'PROMPT'
<razorpay-plugin-loaded>
Razorpay Integration Plugin is active (14 skills, 9 agents).

When the user asks about payments, billing, subscriptions, webhooks, or Razorpay:
- Use the relevant /razorpay:* skill (setup, subscription, webhook, plan-change, one-time-payment, refund, customer-portal, admin, metrics, dunning, local-testing, go-live, stripe-migration, debug)
- Spawn the relevant razorpay-* agent for autonomous work
- Reference the razorpay-api-quirks reference for SDK gotchas

Key gotchas to always remember:
- subscription.authenticated ≠ subscription.activated (only activated = payment confirmed)
- Use request.text() for webhook signatures, NOT request.json()
- Razorpay does NOT handle GST — calculate and invoice separately via Invoice API
- Subscriptions can't be overwritten — both old and new coexist
- One-time payments (Orders API + JS SDK) ≠ subscriptions (Subscriptions API + hosted checkout)
</razorpay-plugin-loaded>
PROMPT
