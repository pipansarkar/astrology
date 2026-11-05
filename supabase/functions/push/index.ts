// Sends push notifications through Firebase Cloud Messaging (HTTP v1 API).
//
// Called only by the database (triggers and pg_cron, see
// supabase/migrations/*_push_notifications.sql), authenticated with the
// shared PUSH_SECRET header. Never called by the app.
//
// Secrets (supabase secrets set ...):
//   PUSH_SECRET                same value as the vault secret 'push_secret'
//   FIREBASE_SERVICE_ACCOUNT   the Firebase service-account JSON (one line)

import { createClient } from "npm:@supabase/supabase-js@2.49.4";

type Payload =
  | { type: "question_open"; question_id: string }
  | { type: "question_answered"; question_id: string }
  | { type: "daily_horoscope" };

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

const DAILY_TOPIC = "daily-horoscope";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_SECRET");
  if (!secret || req.headers.get("x-push-secret") !== secret) {
    return json({ error: "forbidden" }, 403);
  }

  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) return json({ skipped: "FIREBASE_SERVICE_ACCOUNT not set" });
  const sa = JSON.parse(raw) as ServiceAccount;

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }

  try {
    switch (payload.type) {
      case "daily_horoscope": {
        await send(sa, {
          topic: DAILY_TOPIC,
          notification: {
            title: "Your daily horoscope",
            body: "See what today's Moon brings for you.",
          },
          data: { type: "daily_horoscope" },
        });
        return json({ sent: "topic" });
      }

      case "question_open": {
        const q = await question(payload.question_id);
        if (!q || q.status !== "open") return json({ skipped: "not open" });
        const { data: astrologers } = await admin
          .from("astrologers")
          .select("user_id")
          .eq("active", true);
        const tokens = await tokensFor(
          (astrologers ?? []).map((a) => a.user_id),
        );
        const sent = await sendToTokens(sa, tokens, {
          notification: {
            title: "New question",
            body: truncate(q.question, 100),
          },
          data: { type: "question_open", question_id: q.id },
        });
        return json({ sent });
      }

      case "question_answered": {
        const q = await question(payload.question_id);
        if (!q || q.status !== "answered") {
          return json({ skipped: "not answered" });
        }
        const tokens = await tokensFor([q.user_id]);
        const sent = await sendToTokens(sa, tokens, {
          notification: {
            title: "Your answer is ready",
            body:
              `The astrologer has answered your question about ${q.person_name}.`,
          },
          data: { type: "question_answered", question_id: q.id },
        });
        return json({ sent });
      }

      default:
        return json({ error: "unknown type" }, 400);
    }
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

async function question(id: string) {
  const { data } = await admin
    .from("questions")
    .select("id, user_id, person_name, question, status")
    .eq("id", id)
    .maybeSingle();
  return data;
}

async function tokensFor(userIds: string[]): Promise<string[]> {
  if (userIds.length === 0) return [];
  const { data } = await admin
    .from("device_tokens")
    .select("token")
    .in("user_id", userIds);
  return (data ?? []).map((r) => r.token);
}

const truncate = (s: string, n: number) =>
  s.length <= n ? s : s.slice(0, n - 1) + "…";

// ------------------------------------------------------------------- FCM

type Message = {
  token?: string;
  topic?: string;
  notification: { title: string; body: string };
  data: Record<string, string>;
};

async function sendToTokens(
  sa: ServiceAccount,
  tokens: string[],
  base: Omit<Message, "token" | "topic">,
): Promise<number> {
  let sent = 0;
  for (const token of tokens) {
    const ok = await send(sa, { ...base, token });
    if (ok) sent++;
  }
  return sent;
}

/** Returns true on success; deletes tokens FCM reports as dead. */
async function send(sa: ServiceAccount, message: Message): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await accessToken(sa)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: { ...message, android: { priority: "high" } },
      }),
    },
  );
  if (res.ok) return true;

  const text = await res.text();
  if (
    message.token &&
    (res.status === 404 || text.includes("UNREGISTERED") ||
      text.includes("INVALID_ARGUMENT"))
  ) {
    await admin.from("device_tokens").delete().eq("token", message.token);
  } else {
    console.error("FCM error", res.status, text);
  }
  return false;
}

// Google OAuth access token from the service account (signed JWT).
let cached: { token: string; exp: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;

  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const jwt = `${header}.${claims}.${b64urlBytes(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`OAuth failed: ${res.status} ${await res.text()}`);
  const body = await res.json();
  cached = { token: body.access_token, exp: now + body.expires_in };
  return cached.token;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function b64urlBytes(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

const b64url = (s: string) => b64urlBytes(new TextEncoder().encode(s));
