import {createAssistantMessageEventStream, type Context, type Model, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {openBrokerCompat} from "./compat.ts";
import {fetchBrokerModels, OPENBROKER_MODELS, validateOpenBrokerApiKey} from "./catalog.ts";
import {normalizeAssistantContent} from "./normalize.ts";

async function loginOpenBroker(callbacks: OAuthLoginCallbacks): Promise<string> {
  const apiKey = (await callbacks.onPrompt({message: "Paste your OpenBroker API key", placeholder: "obk-..."})).trim();
  if (callbacks.signal?.aborted) throw new Error("OpenBroker login cancelled");
  if (!apiKey) throw new Error("An OpenBroker API key is required");
  callbacks.onProgress?.("Validating OpenBroker API key...");
  await validateOpenBrokerApiKey(apiKey, callbacks.fetch ?? fetch);
  return apiKey;
}

// Rough input size estimate. pi-ai's tokenizer is not always available at
// extension load, and 4-chars-per-token is a standard heuristic for English
// text that over-estimates slightly — the safe direction for a soft warning.
function estimateInputTokens(context: Context): number {
  let chars = 0;
  for (const message of context.messages) {
    const content = message.content;
    if (typeof content === "string") {
      chars += content.length;
    } else if (Array.isArray(content)) {
      for (const part of content) {
        if (typeof part.text === "string") chars += part.text.length;
      }
    }
  }
  return Math.ceil(chars / 4);
}

// Process-level set of model ids we've already warned about, so long sessions
// don't spam the log on every turn once context stays above the threshold.
const warnedModels = new Set<string>();

// OpenBroker passes the OpenAI-compatible body through to the underlying devshard
// inference; the MiniMax route rejects plain OpenAI assistant/tool turns whose
// `content` is not a non-empty array of non-empty {name,type,text} parts, so only
// MiniMax requests are normalized. `streamOpenAICompletions` performs all standard
// OpenAI streaming/tool-call/dialect handling on the response.
function openBrokerStream(requested: Model, context: Context, options?: SimpleStreamOptions) {
  const strictContent = requested.id.toLowerCase().includes("minimax");

  // Soft warning: when the input exceeds the model's highContextWarnTokens
  // (probed empirically against the live broker), suggest the user compact
  // before the next turn. The devshard handles 200k+ cleanly, so this is a
  // nudge, not a refusal. Warned at most once per process per model.
  const warnTokens = (requested as {highContextWarnTokens?: number}).highContextWarnTokens;
  if (warnTokens && !warnedModels.has(requested.id)) {
    const estimate = estimateInputTokens(context);
    if (estimate > warnTokens) {
      const hint = (requested as {highContextHint?: string}).highContextHint ?? "acceptable";
      const prefer = hint === "preferred" ? requested.name : "Kimi K2.6";
      process.stderr.write(
        `[openbroker] ${requested.name}: input ~${estimate} tokens exceeds ${warnTokens} soft threshold. Consider compacting, or switching to ${prefer} for cleaner high-context behavior.\n`,
      );
      warnedModels.add(requested.id);
    }
  }

  const outer = createAssistantMessageEventStream();
  // The provider uses a custom streamSimple to normalize OpenBroker payloads,
  // but the delegated handler still needs the built-in API discriminator so it
  // can resolve the OpenAI compatibility policy.
  const openaiModel: Model<"openai-completions"> = {
    ...requested,
    api: "openai-completions",
    compat: requested.compat ?? openBrokerCompat(requested),
  } as Model<"openai-completions">;
  const streamOptions: SimpleStreamOptions = {
    ...options,
    onPayload: (payload: unknown, model?: Model<"openai-completions">) => {
      const normalized = strictContent ? normalizeAssistantContent(payload) : payload;
      return options?.onPayload?.(normalized, model);
    },
  };
  void (async () => {
    try {
      for await (const event of streamOpenAICompletions(openaiModel, context, streamOptions)) outer.push(event);
    } catch (error) {
      outer.fail(error);
    }
  })();
  return outer;
}

const openBrokerProvider: ExtensionFactory = pi => {
  const environmentKey = process.env.OPENBROKER_API_KEY?.trim();
  let refresh: Promise<void> | undefined;

  const registerModels = () =>
    pi.registerProvider("openbroker", {
      baseUrl: "https://api.openbroker.gonka.gg/v1",
      api: "openbroker-completions",
      streamSimple: openBrokerStream,
      ...(environmentKey ? {apiKey: environmentKey} : {}),
      authHeader: true,
      oauth: {name: "OpenBroker", login: loginOpenBroker},
      models: OPENBROKER_MODELS,
    });

  // The registry copies limits out of `models` at registration time, so refreshed
  // values only take effect by registering again (the runtime replaces the
  // provider's overlays and invalidates its caches).
  //
  // Only `contextWindow` is refreshed. `maxTokens` is intentionally a local cap
  // (DeepSeek's 4,096 verbosity brake is lower than the broker's advertised
  // 16,384) and would be silently overwritten by the broker's larger value if we
  // refreshed it. The broker's `max_output_length` is an upper bound the server
  // enforces, not a recommendation; we are free to request less.
  const refreshModelLimits = async (): Promise<void> => {
    if (refresh) return refresh;
    refresh = fetchBrokerModels().then(models => {
      let changed = false;
      for (const model of OPENBROKER_MODELS) {
        const latest = models.find(candidate => candidate.id === model.id);
        if (!latest || model.contextWindow === latest.contextWindow) continue;
        model.contextWindow = latest.contextWindow;
        changed = true;
      }
      if (changed) registerModels();
    }).finally(() => { refresh = undefined; });
    return refresh;
  };

  registerModels();

  pi.on("session_start", (_event, context) => {
    context.setInterval(() => {
      void refreshModelLimits().catch(error => pi.logger.debug("OpenBroker model refresh failed; retaining static limits", {error}));
    }, 5 * 60_000);
  });
};

export default openBrokerProvider;
