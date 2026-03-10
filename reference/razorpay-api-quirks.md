# Razorpay API Quirks & Undocumented Behavior

This reference documents every Razorpay API quirk discovered through production use. These are NOT in the official docs.

## SDK Type Mismatches

### `subscriptions.cancel()` — Second Parameter
```typescript
// Razorpay docs say: cancel(subscriptionId, cancel_at_cycle_end)
// TypeScript SDK types suggest: cancel(subscriptionId, { cancel_at_cycle_end: boolean })
// What actually works:
await razorpay.subscriptions.cancel(id, true);   // Boolean, not object
await razorpay.subscriptions.cancel(id, false);  // Immediate cancel
```

### `customers.create()` — `fail_existing` Field
```typescript
// TypeScript expects: 0 | 1 | boolean
// But literal 0 doesn't satisfy the type checker
// Fix: explicit cast
await razorpay.customers.create({
  email: "user@example.com",
  fail_existing: 0 as 0 | 1,  // 0 = upsert (return existing customer)
});
```

## Webhook Behavior

### At-Least-Once Delivery
Razorpay does NOT guarantee exactly-once delivery. The same event can be delivered 2-5 times if:
- Your handler takes > 5 seconds to respond
- Your handler returns non-2xx
- Network issues between Razorpay and your server

**Mitigation**: Track `lastEventId` in your database.

### Event ID Location
```
Header:  x-razorpay-event-id
Payload: event.id
```
These SHOULD be the same but can differ in edge cases. Prefer the header.

### Subscription ID Location (varies by event type)
```
subscription events: event.payload.subscription.entity.id
payment events:      event.payload.payment.entity.subscription_id
invoice events:      event.payload.invoice.entity.subscription_id
```
Some events (standalone payments, orders) have NO subscription_id — return 200 and skip.

### Current Period End (three field names)
```
entity.current_period_end   (most common)
entity.current_end          (some events)
entity.end_at               (older API versions)
```
All are Unix timestamps in SECONDS (not milliseconds). Convert: `new Date(value * 1000)`.

## Signature Verification

### Two Different Secrets
- **Webhook signature**: Uses `RAZORPAY_WEBHOOK_SECRET`
- **Payment verification**: Uses `RAZORPAY_KEY_SECRET`
These are DIFFERENT values. Using the wrong one = silent signature mismatch.

### Two Different Signature Formats
```
Order flow:   HMAC-SHA256(key_secret, "order_id|payment_id")
Invoice flow: HMAC-SHA256(key_secret, "invoice_id|receipt|status|payment_id")
```

### Raw Body Required for Webhooks
```typescript
// WRONG — JSON.parse then JSON.stringify changes whitespace
const body = await request.json();
const raw = JSON.stringify(body);

// CORRECT — use raw string for HMAC
const raw = await request.text();
const body = JSON.parse(raw);
```

## Customer API

### Phone Number Handling
- Razorpay rejects phone numbers with formatting characters
- Strip everything except digits and `+`: `phone.replace(/[^\d+]/g, "")`
- If phone is null/undefined, OMIT the `contact` field entirely (don't pass empty string)

### `notify_info` Object
- Only include if you have at least one field (email or phone)
- Empty object `{}` causes API errors
- Build conditionally:
```typescript
const notifyInfo = {
  ...(email ? { notify_email: email } : {}),
  ...(phone ? { notify_phone: phone.replace(/[^\d+]/g, "") } : {}),
};
// Only include in subscription.create if Object.keys(notifyInfo).length > 0
```

## Subscription States

```
created → authenticated → active → (charged repeatedly)
                                  ↓
                              cancelled (at cycle end)
                              completed (all cycles done)
                              halted (payment failures)
                              paused (manual)
```

### State Transition Gotchas
- `subscription.pending` can arrive AFTER `subscription.activated` — don't downgrade
- `payment.authorized` can arrive AFTER `subscription.authenticated` — use as fallback activation
- `subscription.charged` is for RENEWALS, not initial payment
- `subscription.completed` means all `total_count` cycles are done — not a cancellation

## Error Handling

### Error Shape Inconsistency
```typescript
// Some endpoints return:
{ error: { code: "BAD_REQUEST_ERROR", description: "..." } }

// Others return:
{ statusCode: 400, error: { ... } }

// Handle both:
const errorCode = err.error?.code || err.statusCode;
const errorMsg = err.error?.description || err.message;
```

### Cancelling Already-Cancelled Subscriptions
- Returns `BAD_REQUEST_ERROR` with description mentioning "already cancelled"
- Treat this as success (idempotent cancel)
- Wrap in try/catch and check error code

## Plan Management

### Plan IDs Are Environment-Specific
- Test mode plans (`plan_test_xxx`) don't exist in live mode
- Live mode plans (`plan_live_xxx`) don't exist in test mode
- You need separate plan IDs for test and production

### No Reverse Lookup API
There is no Razorpay API to look up which plan corresponds to a plan ID. You must maintain a bidirectional mapping in your env vars or database.

### `total_count` is Max Renewals
- Monthly plan with `total_count: 60` = runs for up to 5 years
- Yearly plan with `total_count: 5` = runs for up to 5 years
- This is a maximum, not a commitment

## GST Notes

### SAC Code for SaaS
Use `998314` (Information technology design and development services) for Indian SaaS companies.

### Tax-Inclusive Plans
When creating plans with `tax_inclusive: true`, the `amount` field is the total customer pays (including GST). To calculate the breakout:
```
base = amount / 1.18
gst = amount - base
cgst = gst / 2
sgst = gst - cgst  (handles odd paise rounding)
```
