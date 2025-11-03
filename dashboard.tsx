import { useEffect, useState } from "react";

type FailedPayment = {
  invoiceId: string;
  customerEmail: string;
  recoveryLink: string;
  retries: number;
  recovered: boolean;
};

type Stats = {
  totalRecovered: number;
  retries: number;
  failedPayments: FailedPayment[];
};

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    fetch("/api/recover-stats")
      .then(r => r.json())
      .then(setStats)
      .catch(() => {});
  }, []);

  if (!stats) return <main style={{ padding: 24, fontFamily: "sans-serif" }}>Loading…</main>;

  return (
    <main style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h1>AutoRecover Dashboard</h1>
      <p><b>Total payments recovered:</b> {stats.totalRecovered}</p>
      <p><b>Total retry attempts:</b> {stats.retries}</p>
      <h2>Current Failed Payments</h2>
      <ul>
        {stats.failedPayments.map(p => (
          <li key={p.invoiceId} style={{ marginBottom: 12 }}>
            <div><b>Invoice:</b> {p.invoiceId}</div>
            <div><b>Email:</b> {p.customerEmail}</div>
            <div><b>Retries:</b> {p.retries}</div>
            <div><b>Status:</b> {p.recovered ? "Recovered" : (p.retries >= 3 ? "Failed, notified" : "Pending")}</div>
            <div><a href={p.recoveryLink} target="_blank" rel="noreferrer">Recovery Link</a></div>
          </li>
        ))}
      </ul>
      <h3>Quick Start Test Instructions</h3>
      <pre>{`npm i
npm run dev

# another terminal:
stripe listen --forward-to localhost:3000/api/stripe-webhook
stripe trigger invoice.payment_failed`}</pre>
    </main>
  );
}
