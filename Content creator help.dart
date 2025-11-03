
// --- In-memory Storage (demo only) ---
const recoverStats = {
  totalRecovered: 0,
  retries: 0,
  failedPayments: [] as {
    invoiceId: string;
    customerEmail: string;
    recoveryLink: string;
    retries: number;
    recovered: boolean;
  }[],
};
type FailedPayment = typeof recoverStats.failedPayments[number];

// --- Primitive In-Memory Retry Queue ---
const retryQueue = new Map<string, NodeJS.Timeout>();

function scheduleRetries(invoiceId: string, customerEmail: string, recoveryLink: string) {
  const retryDelays = [6 * 60 * 60 * 1000, 12 * 60 * 60 * 1000, 24 * 60 * 60 * 1000]; // ms
  // For test/dev, use short timeouts: e.g. [5000, 10000, 20000] for 5s, 10s, 20s
  const isDev = process.env.NODE_ENV !== "production";
  const delays = isDev ? [5000, 10000, 20000] : retryDelays;

  function retryHandler(attempt: number) {
    const payment = recoverStats.failedPayments.find(fp => fp.invoiceId === invoiceId);
    if (!payment || payment.recovered) return;

    payment.retries += 1;
    recoverStats.retries += 1;
    console.log(`[AutoRecover] Retrying payment for invoice ${invoiceId} (Attempt ${payment.retries}/3)`);

    // Simulate attempt
    // If you want to support real retrying, call Stripe API here (e.g. stripe.invoices.pay(invoiceId))
    const success = false;

    if (success) {
      payment.recovered = true;
      recoverStats.totalRecovered += 1;
      console.log(`[AutoRecover] Payment recovered for invoice ${invoiceId}`);
    } else if (payment.retries < 3) {
      retryQueue.set(
        invoiceId,
        setTimeout(() => retryHandler(payment.retries), delays[payment.retries])
      );
    } else {
      // All retries failed
      sendDiscordDM(customerEmail, recoveryLink);
      sendEmail(customerEmail, recoveryLink);
      console.log(`[AutoRecover] All retries failed for invoice ${invoiceId}. Buyer notified.`);
    }
  }

  retryQueue.set(
    invoiceId,
    setTimeout(() => retryHandler(1), delays[0])
  );
}

// --- Notification Function Stubs ---
function sendDiscordDM(email: string, link: string) {
  console.log(`[AutoRecover] Discord DM sent to: ${email} with recovery link: ${link}`);
}
function sendEmail(email: string, link: string) {
  console.log(`[AutoRecover] Email sent to: ${email} with recovery link: ${link}`);
}

// --- Dashboard ---
app.get("/dashboard", (_req, res) => {
  res.send(`
    <h1>AutoRecover Dashboard</h1>
    <p><b>Total payments recovered:</b> ${recoverStats.totalRecovered}</p>
    <p><b>Total retry attempts:</b> ${recoverStats.retries}</p>
    <h2>Current Failed Payments</h2>
    <ul>
      ${
        recoverStats.failedPayments
          .map(
            p => `<li>
              Invoice: ${p.invoiceId}<br>
              Email: ${p.customerEmail}<br>
              Retries: ${p.retries}<br>
              Status: ${p.recovered ? 'Recovered' : (p.retries >= 3 ? 'Failed, notified' : 'Pending') }<br>
              <a href="${p.recoveryLink}" target="_blank">Recovery Link</a>
            </li>`
          ).join("")
      }
    </ul>
    <h3>Quick Start Test Instructions</h3>
    <pre>
npm i
npm run dev

# New terminal:
stripe listen --forward-to localhost:3000/webhook/stripe
stripe trigger invoice.payment_failed
    </pre>
  `);
});

// --- Stripe Webhook: Payment Failed Logic ---
app.post("/webhook/stripe", express.raw({ type: "application/json" }), async (req, res) => {
  try {
    const sig = req.headers["stripe-signature"] as string;
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || "";
    const event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);

    if (event.type === "invoice.payment_failed") {
      const invoice = event.data.object as any;
      let customerEmail = invoice.customer_email || invoice.customer;
      if (!customerEmail) {
        customerEmail = "unknown@example.com";
      }
      const recoveryLink = `https://dashboard.stripe.com/invoices/${invoice.id}/pay`;
      if (!recoverStats.failedPayments.find(f => f.invoiceId === invoice.id)) {
        recoverStats.failedPayments.push({
          invoiceId: invoice.id,
          customerEmail,
          recoveryLink,
          retries: 0,
          recovered: false,
        });
        scheduleRetries(invoice.id, customerEmail, recoveryLink);
      }
    }
    res.json({ received: true });
  } catch (err: any) {
    console.error("Stripe signature verification failed:", err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
  }
});

// --- Whop Webhook stub (For completeness) ---
app.post("/webhook/whop", express.json(), (req, res) => {
  const event = req.body;
  console.log("Received Whop webhook:", event);
  // TODO: Add Whop failed payment processing
  res.status(200).json({ received: true });
});





