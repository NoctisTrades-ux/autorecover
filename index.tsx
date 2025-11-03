import Link from "next/link";

export default function Home() {
  return (
    <main style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h1>AutoRecover</h1>
      <p>Stripe webhook endpoint is at <code>/api/stripe-webhook</code>.</p>
      <p>See the <Link href="/dashboard">Dashboard</Link> to view demo stats after a failed payment event.</p>
      <ol>
        <li>Set env vars on Vercel</li>
        <li>Use Stripe CLI to trigger: <code>invoice.payment_failed</code></li>
        <li>Refresh the dashboard</li>
      </ol>
    </main>
  );
}
