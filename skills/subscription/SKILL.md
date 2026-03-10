---
name: subscription
description: Create Razorpay subscription checkout — hosted checkout flow, customer upsert, pending dedup, popup-blocked fallback. Use when implementing subscription billing or recurring payments.
argument-hint: "[monthly|yearly|setup]"
---

# Razorpay Subscription Creation

Build a production-grade subscription creation flow. This handles customer creation, duplicate prevention, hosted checkout, and popup-blocked fallback.

Base directory for reference files: ${CLAUDE_SKILL_DIR}

## Architecture: Hosted Checkout (Not JS SDK)

Use Razorpay's hosted checkout (`short_url`) instead of the JS SDK popup. Why:
- Works on all browsers (no popup blockers)
- No client-side SDK bundle needed
- Razorpay handles the entire payment UI
- Mobile-friendly by default

## API Route: Create Subscription

```typescript
// app/api/billing/create-subscription/route.ts
import { razorpay } from "@/lib/razorpay";
import { planIdFor, totalCountFor } from "@/lib/billing/plans";

export async function POST(request: Request) {
  // 1. Authenticate user (your auth system)
  const user = await getAuthenticatedUser(request);
  if (!user) return new Response("Unauthorized", { status: 401 });

  const { planKey } = await request.json();

  // 2. Check for pending subscription (prevent duplicates)
  const existing = await getSubscriptionByUserId(user.id);
  if (existing) {
    const isPending = ["created", "authenticated", "pending"].includes(existing.status);
    const isRecent = Date.now() - existing.createdAt.getTime() < 3600_000; // 1 hour

    if (isPending && isRecent) {
      // Return existing checkout URL — user may have abandoned and returned
      return Response.json({
        shortUrl: null, // Cannot retrieve short_url after creation
        subscriptionId: existing.razorpaySubscriptionId,
        error: "Subscription already pending. Complete existing checkout or wait 1 hour.",
      }, { status: 409 });
    }

    if (isPending && !isRecent) {
      // Stale pending — cancel on Razorpay (best-effort)
      try {
        await razorpay.subscriptions.cancel(existing.razorpaySubscriptionId, false);
      } catch {
        // Ignore — may already be cancelled
      }
    }
  }

  // 3. Create or reuse Razorpay customer
  //    fail_existing: 0 = return existing customer if email matches (upsert)
  const customer = await razorpay.customers.create({
    name: user.name || "Customer",
    email: user.email,
    ...(user.phone ? { contact: user.phone.replace(/[^\d+]/g, "") } : {}),
    fail_existing: 0 as 0 | 1,  // TypeScript SDK quirk — needs explicit cast
  });

  // 4. Create subscription
  const planId = planIdFor(planKey);
  const subscription = await razorpay.subscriptions.create({
    plan_id: planId,
    total_count: totalCountFor(planKey),
    quantity: 1,
    customer_notify: 1,
    notes: {
      userId: user.id,
      planKey,
    },
    ...(user.email ? {
      notify_info: {
        notify_email: user.email,
        ...(user.phone ? { notify_phone: user.phone.replace(/[^\d+]/g, "") } : {}),
      },
    } : {}),
  });

  // 5. Save to database
  await createSubscriptionRecord({
    userId: user.id,
    planKey,
    razorpaySubscriptionId: subscription.id,
    razorpayPlanId: planId,
    razorpayCustomerId: customer.id,
    status: "created",
  });

  // 6. Return hosted checkout URL
  return Response.json({
    shortUrl: subscription.short_url,
    subscriptionId: subscription.id,
  });
}
```

## Client-Side: Popup + Fallback + Polling

```typescript
// components/checkout-button.tsx
"use client";
import { useState, useEffect } from "react";

export function CheckoutButton({ planKey }: { planKey: string }) {
  const [loading, setLoading] = useState(false);
  const [fallbackUrl, setFallbackUrl] = useState<string | null>(null);

  // Poll for activation when user returns from payment tab
  useEffect(() => {
    const handler = async () => {
      if (document.visibilityState !== "visible") return;
      const res = await fetch("/api/billing/status");
      const data = await res.json();
      if (data.active) {
        window.location.href = "/dashboard"; // Redirect on success
      }
    };
    document.addEventListener("visibilitychange", handler);
    return () => document.removeEventListener("visibilitychange", handler);
  }, []);

  const handleCheckout = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/billing/create-subscription", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ planKey }),
      });
      const data = await res.json();

      if (!data.shortUrl) {
        alert(data.error || "Failed to create checkout");
        return;
      }

      // Try opening in new tab
      const popup = window.open(data.shortUrl, "_blank");

      if (!popup || popup.closed) {
        // Popup was blocked — show fallback link
        setFallbackUrl(data.shortUrl);
      }
    } catch (error) {
      alert("Failed to start checkout");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <button onClick={handleCheckout} disabled={loading}>
        {loading ? "Creating checkout..." : "Subscribe"}
      </button>

      {fallbackUrl && (
        <div style={{ marginTop: 12, padding: 12, background: "#fef3c7", borderRadius: 8 }}>
          <p>Popup was blocked by your browser.</p>
          <a href={fallbackUrl} target="_blank" rel="noopener">
            Open payment page &rarr;
          </a>
        </div>
      )}
    </div>
  );
}
```

## Key Patterns

### Pending Subscription Dedup
- Check for existing `created|authenticated|pending` subscriptions
- If recent (< 1 hour): block duplicate creation (409)
- If stale (> 1 hour): cancel on Razorpay, allow new creation
- NEVER allow two active subscriptions for the same plan

### Customer Upsert
- `fail_existing: 0` returns existing customer if email matches
- Always strip phone formatting: `.replace(/[^\d+]/g, "")`
- Omit `contact` field entirely if phone is null (don't pass empty string)

### Popup-Blocked Detection
```javascript
const popup = window.open(url, "_blank");
if (!popup || popup.closed) {
  // Show fallback link
}
```

### Payment Completion Detection
Use `visibilitychange` event — fires when user switches back to your tab after completing payment in Razorpay's tab. Poll your status endpoint to check if webhook has activated the subscription.

## Gotchas

1. **`short_url` is one-time**: You cannot retrieve it after creation. If lost, create a new subscription.
2. **`fail_existing` TypeScript**: Cast `0 as 0 | 1` — Razorpay SDK types are wrong.
3. **`notify_info` conditional**: Only include if you have email/phone. Empty object causes errors.
4. **`total_count`**: Monthly = 60 (5 years), Yearly = 5. This is max renewals, not billing cycles.
5. **Customer without phone**: Omit the `contact` field entirely — don't pass null or empty string.

---

*Powered by [portoai.co](https://portoai.co) — battle-tested in production with thousands of Indian subscribers.*
