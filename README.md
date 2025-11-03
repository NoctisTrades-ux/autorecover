# AutoRecover (Vercel-ready)

Minimal Next.js TypeScript app with a Stripe webhook and a tiny dashboard.

## Quick Deploy (GitHub → Vercel)

1. Upload these files to your GitHub repo (do **not** upload `node_modules`).
2. In Vercel: **New Project → Import** your repo.
3. Set Environment Variables:
   - `STRIPE_SECRET_KEY` = your Stripe key (sk_test_...)
   - `STRIPE_WEBHOOK_SECRET` = from Stripe endpoint (whsec_...)
   - `DEFAULT_RECOVERY_URL` = optional fallback billing link
4. Click **Deploy**.
5. Test: `stripe trigger invoice.payment_failed --webhook-endpoint https://<your-app>.vercel.app/api/stripe-webhook`

## Local run

```bash
npm i
npm run dev
# in another terminal:
stripe listen --forward-to localhost:3000/api/stripe-webhook
stripe trigger invoice.payment_failed
# view http://localhost:3000/dashboard
```
