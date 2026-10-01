import { createServer, type Server } from "node:http";
import { randomUUID } from "node:crypto";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const PROVIDER_ID = "cline";
const CLINE_BASE_URL = "https://api.cline.bot/api/v1";
const AUTH_TIMEOUT_MS = 10 * 60_000;
const FETCH_TIMEOUT_MS = 15_000;
const CALLBACK_PORT_START = 48801;
const CALLBACK_PORT_END = 48811;
const CLINE_CLIENT_HEADERS = {
  "HTTP-Referer": "https://cline.bot",
  "X-Title": "Cline",
  "X-PLATFORM": "Visual Studio Code",
  "X-PLATFORM-VERSION": "1.109.3",
  "X-CLIENT-TYPE": "VSCode Extension",
  "X-CLIENT-VERSION": "3.76.0",
  "X-CORE-VERSION": "3.76.0",
  "X-Is-Multiroot": "false",
};

const FALLBACK_FREE_MODELS = [
  "cline-free/deepseek-v4.1-flash",
  "z-ai/glm-5.3-flash",
  "poolside/laguna-s-2.1:free",
  "qwen/qwen3.8-27b:free",
];

// Guardrail / moderation routes cannot drive an agent.
const EXCLUDED_FREE_PATTERN = /content-safety|content-moderation/i;

interface ClineRecommendedModel {
  id: string;
  name?: string;
  description?: string;
  tags?: string[];
}

interface ClineCatalogModel {
  id: string;
  name?: string;
  context_length?: number | null;
  supported_parameters?: string[] | null;
  architecture?: {
    modality?: string | string[] | null;
    input_modalities?: string[] | null;
  } | null;
  top_provider?: {
    max_completion_tokens?: number | null;
    context_length?: number | null;
  } | null;
}

interface ClineCredentials {
  access: string;
  refresh: string;
  expires: number;
}
interface ClineLoginCallbacks {
  signal?: AbortSignal;
  onProgress?: (message: string) => void;
  onAuth?: (info: { url: string; instructions: string }) => void;
  onManualCodeInput?: () => Promise<string>;
}

let registeredModels = FALLBACK_FREE_MODELS.map((id) => modelConfig(id));

function modelConfig(
  id: string,
  metadata?: ClineCatalogModel,
  recommended?: ClineRecommendedModel,
) {
  const name = recommended?.name?.trim() || metadata?.name?.trim() || id;
  const inputModalities = metadata?.architecture?.input_modalities;
  const modality = metadata?.architecture?.modality;
  const supportsImages =
    inputModalities?.includes("image") ||
    (typeof modality === "string" && modality.includes("image")) ||
    (Array.isArray(modality) && modality.includes("image"));
  const reasoning =
    metadata?.supported_parameters?.includes("reasoning") === true ||
    metadata?.supported_parameters?.includes("include_reasoning") === true;

  return {
    id,
    name: `${name} (Cline Free)`,
    provider: PROVIDER_ID,
    baseUrl: CLINE_BASE_URL,
    api: "openai-completions" as const,
    reasoning,
    input: supportsImages ? (["text", "image"] as const) : (["text"] as const),
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow:
      metadata?.context_length ?? metadata?.top_provider?.context_length ?? 128_000,
    maxTokens: metadata?.top_provider?.max_completion_tokens ?? 65_536,
  };
}

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${CLINE_BASE_URL}${path}`, {
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...CLINE_CLIENT_HEADERS,
    },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!response.ok) {
    throw new Error(`Cline ${path} returned HTTP ${response.status}`);
  }
  return (await response.json()) as T;
}

async function fetchFreeModels() {
  const [recommended, catalog] = await Promise.all([
    fetchJson<{ free?: ClineRecommendedModel[] }>(
      "/ai/cline/recommended-models",
    ),
    fetchJson<{ data?: ClineCatalogModel[] }>("/ai/cline/models"),
  ]);

  const freeModels = Array.isArray(recommended.free)
    ? recommended.free.filter((model) => model && typeof model.id === "string")
    : [];

  const metadata = new Map(
    (Array.isArray(catalog.data) ? catalog.data : [])
      .filter((model) => model && typeof model.id === "string")
      .map((model) => [model.id, model]),
  );

  // The curated `free` list is only a subset: the catalog carries more
  // `:free`-suffixed routes that stay callable on the free tier. Union
  // both (curated order first), minus guardrail routes.
  const seen = new Set(freeModels.map((model) => model.id));
  for (const id of metadata.keys()) {
    if (!id.endsWith(":free") || seen.has(id)) continue;
    if (EXCLUDED_FREE_PATTERN.test(id)) continue;
    seen.add(id);
    freeModels.push({ id });
  }
  if (freeModels.length === 0) {
    throw new Error("Cline returned no free models");
  }

  return freeModels.map((model) => modelConfig(model.id, metadata.get(model.id), model));
}

async function discoverFreeModels() {
  try {
    return await fetchFreeModels();
  } catch {
    return FALLBACK_FREE_MODELS.map((id) => modelConfig(id));
  }
}

function parseCallback(rawUrl: string, port: number) {
  const url = new URL(rawUrl, `http://127.0.0.1:${port}`);
  const code =
    url.searchParams.get("refreshToken") ||
    url.searchParams.get("idToken") ||
    url.searchParams.get("code");
  if (!code) throw new Error("Cline callback did not contain an authorization code");
  return { code, provider: url.searchParams.get("provider") };
}

async function startCallbackServer(signal?: AbortSignal) {
  let server: Server | undefined;
  let port = 0;
  let settled = false;
  let timeout: ReturnType<typeof setTimeout> | undefined;
  let abortListener: (() => void) | undefined;
  let resolveCode!: (value: { code: string; provider: string | null }) => void;
  let rejectCode!: (error: Error) => void;
  const waitForCode = new Promise<{ code: string; provider: string | null }>(
    (resolve, reject) => {
      resolveCode = resolve;
      rejectCode = reject;
    },
  );
  void waitForCode.catch(() => undefined);

  const cleanup = () => {
    clearTimeout(timeout);
    if (signal && abortListener) signal.removeEventListener("abort", abortListener);
    server?.close();
    server = undefined;
  };
  const settle = (callback: () => void) => {
    if (settled) return;
    settled = true;
    cleanup();
    callback();
  };

  server = createServer((request, response) => {
    try {
      if (new URL(request.url || "/", `http://127.0.0.1:${port}`).pathname !== "/auth") {
        response.writeHead(404);
        response.end("Not found");
        return;
      }
      const callback = parseCallback(request.url || "/", port);
      response.writeHead(200, { "Content-Type": "text/html" });
      response.end(
        "<!doctype html><title>Cline authentication complete</title><p>Authenticated. You can close this window.</p>",
      );
      settle(() => resolveCode(callback));
    } catch (error) {
      response.writeHead(400);
      response.end("Invalid Cline callback");
      settle(() =>
        rejectCode(error instanceof Error ? error : new Error(String(error))),
      );
    }
  });

  for (let candidate = CALLBACK_PORT_START; candidate <= CALLBACK_PORT_END; candidate += 1) {
    try {
      await new Promise<void>((resolve, reject) => {
        const onError = (error: NodeJS.ErrnoException) => {
          server?.off("error", onError);
          reject(error);
        };
        server?.once("error", onError);
        server?.listen(candidate, "127.0.0.1", () => {
          server?.off("error", onError);
          resolve();
        });
      });
      port = candidate;
      break;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EADDRINUSE") throw error;
    }
  }

  if (port === 0 || !server) {
    cleanup();
    throw new Error("No available Cline callback port (tried 48801-48811)");
  }

  timeout = setTimeout(
    () => settle(() => rejectCode(new Error("Cline authentication timed out"))),
    AUTH_TIMEOUT_MS,
  );
  abortListener = () => settle(() => rejectCode(new Error("Cline login cancelled")));
  signal?.addEventListener("abort", abortListener, { once: true });
  if (signal?.aborted) abortListener();

  return {
    callbackUrl: `http://127.0.0.1:${port}/auth`,
    waitForCode,
    close: () => settle(() => rejectCode(new Error("Cline login cancelled"))),
  };
}

async function fetchAuthorizeUrl(callbackUrl: string, signal?: AbortSignal) {
  const url = new URL(`${CLINE_BASE_URL}/auth/authorize`);
  url.searchParams.set("client_type", "extension");
  url.searchParams.set("callback_url", callbackUrl);
  url.searchParams.set("redirect_uri", callbackUrl);
  const response = await fetch(url, {
    headers: CLINE_CLIENT_HEADERS,
    redirect: "manual",
    signal,
  });
  if (response.status >= 300 && response.status < 400) {
    const location = response.headers.get("location");
    if (location) return location;
  }
  const body = (await response.json()) as { redirect_url?: string };
  if (body.redirect_url) return body.redirect_url;
  throw new Error("Cline did not return an authorization URL");
}

function parseManualCode(input: string) {
  const trimmed = input.trim();
  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    return parseCallback(trimmed, 48801);
  }
  return { code: trimmed, provider: null };
}

async function exchangeCode(
  code: string,
  provider: string | null,
  callbackUrl: string,
  signal?: AbortSignal,
): Promise<ClineCredentials> {
  const candidates = provider ? [provider] : [null, "google", "github", "microsoft", "authkit"];
  let lastError = "";
  for (const candidate of candidates) {
    const payload: Record<string, string> = {
      grant_type: "authorization_code",
      code,
      client_type: "extension",
      redirect_uri: callbackUrl,
    };
    if (candidate) payload.provider = candidate;
    const response = await fetch(`${CLINE_BASE_URL}/auth/token`, {
      method: "POST",
      headers: { ...CLINE_CLIENT_HEADERS, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal,
    });
    if (!response.ok) {
      lastError = `${response.status}: ${(await response.text()).slice(0, 120)}`;
      continue;
    }
    const body = (await response.json()) as {
      success?: boolean;
      data?: { accessToken?: string; refreshToken?: string; expiresAt?: string };
    };
    if (body.success && body.data?.accessToken && body.data.expiresAt) {
      const expires = Date.parse(body.data.expiresAt);
      if (!Number.isFinite(expires)) throw new Error("Cline returned an invalid expiration time");
      return {
        access: body.data.accessToken,
        refresh: body.data.refreshToken || "",
        expires: Math.max(Date.now() + 30_000, expires - 5 * 60_000),
      };
    }
    lastError = "invalid token response";
  }
  throw new Error(`Cline token exchange failed${lastError ? ` (${lastError})` : ""}`);
}

async function loginCline(callbacks: ClineLoginCallbacks): Promise<ClineCredentials> {
  callbacks.onProgress?.("Preparing Cline authentication...");
  const callback = await startCallbackServer(callbacks.signal);
  try {
    const authUrl = await fetchAuthorizeUrl(callback.callbackUrl, callbacks.signal);
    callbacks.onAuth?.({
      url: authUrl,
      instructions: "Open the URL in a browser, then return here after authentication.",
    });
    callbacks.onProgress?.("Waiting for the Cline authentication callback...");

    let result: { code: string; provider: string | null };
    const manual = callbacks.onManualCodeInput?.();
    if (manual) {
      const manualResult = await Promise.race([
        callback.waitForCode,
        manual.then((value: string) => parseManualCode(value)),
      ]);
      result = manualResult;
    } else {
      result = await callback.waitForCode;
    }
    callbacks.onProgress?.("Completing Cline authentication...");
    return await exchangeCode(result.code, result.provider, callback.callbackUrl, callbacks.signal);
  } finally {
    callback.close();
  }
}

async function refreshClineToken(credentials: ClineCredentials) {
  if (credentials.expires > Date.now()) return credentials;
  const response = await fetch(`${CLINE_BASE_URL}/auth/refresh`, {
    method: "POST",
    headers: { ...CLINE_CLIENT_HEADERS, "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken: credentials.refresh, grantType: "refresh_token" }),
  });
  if (!response.ok) throw new Error("Cline token refresh failed; run /login cline");
  const body = (await response.json()) as {
    success?: boolean;
    data?: { accessToken?: string; refreshToken?: string; expiresAt?: string };
  };
  if (!body.success || !body.data?.accessToken || !body.data.expiresAt) {
    throw new Error("Cline returned an invalid refresh response; run /login cline");
  }
  const expires = Date.parse(body.data.expiresAt);
  return {
    access: body.data.accessToken,
    refresh: body.data.refreshToken || credentials.refresh,
    expires: Math.max(Date.now() + 30_000, expires - 5 * 60_000),
  };
}

function providerConfig() {
  return {
    baseUrl: CLINE_BASE_URL,
    api: "openai-completions" as const,
    // Static fallback catalog, visible immediately at registration; OMP
    // replaces it with the live result once `fetchDynamicModels` succeeds.
    models: registeredModels,
    ...(process.env.CLINE_API_KEY ? { apiKey: process.env.CLINE_API_KEY } : {}),
    authHeader: true,
    headers: { ...CLINE_CLIENT_HEADERS, "X-Task-ID": randomUUID() },
    fetchDynamicModels: async () => {
      const models = await discoverFreeModels();
      registeredModels = models;
      return models;
    },
    oauth: {
      name: "Cline",
      login: loginCline,
      refreshToken: refreshClineToken,
      getApiKey: (credentials: ClineCredentials) =>
        credentials.access.startsWith("workos:")
          ? credentials.access
          : `workos:${credentials.access}`,
    },
  };
}

function modelCommandText() {
  return registeredModels.map((model) => `  cline/${model.id}`).join("\n");
}

export default async function clineFreeProvider(pi: ExtensionAPI) {
  pi.registerProvider(PROVIDER_ID, providerConfig());

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.notify(
      `Cline free models registered. Use /login cline or set CLINE_API_KEY, then /model.`,
      "info",
    );
  });

  pi.registerCommand("cline-free", {
    description: "Show and refresh Cline's free model catalog",
    handler: async (args, ctx) => {
      const command = args.trim().split(/\s+/)[0] || "status";
      if (command === "status") {
        ctx.ui.notify(
          [
            "Provider: cline",
            "Catalog: Cline recommended free models",
            `Models: ${registeredModels.length}`,
            "Auth: /login cline or CLINE_API_KEY",
            "",
            modelCommandText(),
          ].join("\n"),
          "info",
        );
        return;
      }
      if (command === "models") {
        ctx.ui.notify(modelCommandText() || "No Cline models registered.", "info");
        return;
      }
      if (command === "update") {
        const models = await fetchFreeModels();
        registeredModels = models;
        pi.registerProvider(PROVIDER_ID, { ...providerConfig(), models });
        ctx.ui.notify(`Cline free catalog refreshed: ${models.length} model(s).\n\n${modelCommandText()}`, "info");
        return;
      }
      if (command === "test") {
        const model = registeredModels[0]?.id || FALLBACK_FREE_MODELS[0];
        ctx.ui.notify(`Run: omp -p --model cline/${model} \"Reply with exactly OK\"`, "info");
        return;
      }
      ctx.ui.notify("Usage: /cline-free [status|models|update|test]", "info");
    },
  });
}
