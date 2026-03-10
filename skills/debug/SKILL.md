---
description: Debug common Razorpay integration issues — webhook failures, signature mismatches, subscription state problems, SDK quirks. Use when the user says "webhook not working", "signature failing", "razorpay broken", "payment not going through", or needs to troubleshoot any Razorpay integration problem.
argument-hint: "[webhook|signature|subscription|payment]"
---

# Razorpay Debugging Guide

Common issues and their solutions, organized by symptom.

## Webhook Not Firing

**Check these in order:**

1. **Webhook URL registered**: Dashboard → Settings → Webhooks → Verify URL is correct
2. **HTTPS required**: Razorpay won't call HTTP endpoints (except localhost in test mode)
3. **Events enabled**: Check which events are checked in webhook settings
4. **Response timeout**: Razorpay expects 2xx within 5 seconds. If your handler takes longer, it times out and retries.
5. **Check webhook logs**: Dashboard → Settings → Webhooks → Click on webhook → View delivery attempts

**Test locally with ngrok:**
```bash
ngrok http 3000
# Copy the https URL → Register as webhook URL in Razorpay Dashboard
```

## Signature Verification Failing

**Most common causes:**

1. **Using wrong secret**: Webhook signature uses `RAZORPAY_WEBHOOK_SECRET`. Payment verification uses `RAZORPAY_KEY_SECRET`. They are DIFFERENT values.

2. **Parsing body as JSON first**: Signature is computed on the RAW string body. If you parse to JSON and re-stringify, whitespace changes break the signature.
   ```typescript
   // WRONG
   const body = await request.json();
   const raw = JSON.stringify(body);  // May differ from original!

   // CORRECT
   const raw = await request.text();
   const body = JSON.parse(raw);
   ```

3. **Invoice signature format wrong**: Order flow and invoice flow have different signature payloads:
   ```
   Order:   HMAC(secret, "order_id|payment_id")
   Invoice: HMAC(secret, "invoice_id|receipt|status|payment_id")
   ```

4. **Optional fields undefined**: Invoice `receipt` and `status` may be undefined. Use `?? ""`:
   ```typescript
   const payload = `${invoiceId}|${receipt ?? ""}|${status ?? ""}|${paymentId}`;
   ```

## Duplicate Webhook Events

**Symptom**: Same subscription activated twice, duplicate GST invoices, double access grants.

**Root cause**: Razorpay uses at-least-once delivery. If your handler doesn't return 200 within 5 seconds, it retries.

**Fix**: Track `lastEventId` in your subscription table and skip duplicates:
```typescript
const eventId = request.headers.get("x-razorpay-event-id") || event.id;
if (subscription.lastEventId === eventId) {
  return new Response("Already processed", { status: 200 });
}
```

## Subscription Stuck in "created" Status

**Symptom**: Subscription created but never activates.

**Cause**: User opened checkout but never completed payment.

**Fix**: Implement stale pending cleanup:
```typescript
// Before creating new subscription, check for stale ones
const existing = await getSubscriptionByUserId(userId);
if (existing?.status === "created" && isOlderThan1Hour(existing.createdAt)) {
  // Cancel stale subscription on Razorpay
  await razorpay.subscriptions.cancel(existing.razorpaySubscriptionId, false);
}
```

## `subscriptions.cancel()` TypeScript Error

**Symptom**: TypeScript complains about second parameter type.

**Fix**: The second parameter is a boolean, not an object:
```typescript
// WRONG
await razorpay.subscriptions.cancel(id, { cancel_at_cycle_end: true });

// CORRECT
await razorpay.subscriptions.cancel(id, true);  // cancel at cycle end
await razorpay.subscriptions.cancel(id, false); // cancel immediately
```

## `customers.create()` TypeScript Error with `fail_existing`

**Symptom**: TypeScript expects `0 | 1` but won't accept the number.

**Fix**: Explicit cast:
```typescript
await razorpay.customers.create({
  email: user.email,
  fail_existing: 0 as 0 | 1,  // Upsert — return existing customer
});
```

## Payment Succeeds But Access Not Granted

**Debug steps:**

1. **Check webhook delivery**: Razorpay Dashboard → Webhooks → Delivery attempts
2. **Check event type**: Was it `subscription.authenticated` or `subscription.activated`? Handle both.
3. **Check idempotency**: Is `lastEventId` causing a skip? Look at DB.
4. **Check signature**: Was 400 returned? Check webhook logs for response body.
5. **Check event order**: `payment.authorized` may arrive before `subscription.activated`. Handle `payment.authorized` as fallback activation.

## Plan Change Not Working

**Debug steps:**

1. **Check `notes.replacesSubscription`**: Is the old subscription ID in the new subscription's notes?
2. **Check webhook**: Is `subscription.activated` being received for the new subscription?
3. **Check auto-creation**: If subscription isn't in DB, does your webhook handler auto-create from notes?
4. **Check old sub cancellation**: Is `razorpay.subscriptions.cancel(oldId, true)` being called in the webhook?

## Razorpay SDK Quirks Reference

| Quirk | Workaround |
|-------|-----------|
| `cancel(id, boolean)` typed as object | Use `true` or `false` directly |
| `fail_existing: 0` type mismatch | Cast: `0 as 0 \| 1` |
| `notify_info` fails with empty object | Only include if fields are present |
| `contact` field rejects empty string | Omit field entirely if no phone |
| `current_period_end` vs `current_end` | Try both, plus `end_at` |
| Webhook event ID in header vs payload | Prefer `x-razorpay-event-id` header |
| Error shape varies by endpoint | Check both `.error.code` and `.statusCode` |

## Quick Diagnostic Commands

```bash
# Check if webhook endpoint is reachable
curl -X POST https://your-app.com/api/billing/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
# Should return 400 (missing signature), NOT 404 or 500

# Verify Razorpay credentials work
curl -u rzp_test_key:rzp_test_secret \
  https://api.razorpay.com/v1/plans
# Should return plan list, NOT 401

# Check subscription status
curl -u rzp_test_key:rzp_test_secret \
  https://api.razorpay.com/v1/subscriptions/sub_xxxxx
```

## Mock Webhook Payloads for Local Testing

Use these sample payloads to test your webhook handler locally without triggering real Razorpay events.

### subscription.activated

Sent when a new subscription is successfully activated after first payment.

```json
{
  "event": "subscription.activated",
  "payload": {
    "subscription": {
      "entity": {
        "id": "sub_test123",
        "plan_id": "plan_test456",
        "customer_id": "cust_test789",
        "status": "active",
        "current_period_end": 1700000000,
        "notes": { "userId": "user_123", "planKey": "pro_monthly" }
      }
    },
    "payment": {
      "entity": {
        "id": "pay_test111",
        "amount": 99900,
        "currency": "INR",
        "subscription_id": "sub_test123"
      }
    }
  }
}
```

### subscription.charged

Sent on each successful renewal payment.

```json
{
  "event": "subscription.charged",
  "payload": {
    "subscription": {
      "entity": {
        "id": "sub_test123",
        "plan_id": "plan_test456",
        "customer_id": "cust_test789",
        "status": "active",
        "current_period_end": 1702592000,
        "paid_count": 2,
        "notes": { "userId": "user_123", "planKey": "pro_monthly" }
      }
    },
    "payment": {
      "entity": {
        "id": "pay_test222",
        "amount": 99900,
        "currency": "INR",
        "subscription_id": "sub_test123",
        "method": "card"
      }
    }
  }
}
```

### payment.failed

Sent when a payment attempt fails (e.g., insufficient funds, card declined).

```json
{
  "event": "payment.failed",
  "payload": {
    "payment": {
      "entity": {
        "id": "pay_test333",
        "amount": 99900,
        "currency": "INR",
        "status": "failed",
        "subscription_id": "sub_test123",
        "error_code": "BAD_REQUEST_ERROR",
        "error_description": "Payment processing failed because of insufficient balance",
        "error_reason": "insufficient_funds"
      }
    }
  }
}
```

### Testing with curl

```bash
# Test webhook locally (skip signature verification in test mode or use a known test secret)
curl -X POST http://localhost:3000/api/billing/webhook \
  -H "Content-Type: application/json" \
  -H "x-razorpay-event-id: evt_test_001" \
  -H "x-razorpay-signature: <generate with your webhook secret>" \
  -d '<payload>'
```

### Generating a test signature

```bash
# Generate test signature
echo -n '<raw-json-payload>' | openssl dgst -sha256 -hmac "your_webhook_secret"
```

Replace `<raw-json-payload>` with the exact JSON string you pass as the `-d` body (no trailing newline). Use the hex output as the `x-razorpay-signature` header value.
