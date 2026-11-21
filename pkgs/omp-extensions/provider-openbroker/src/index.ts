import {createAssistantMessageEventStream, type Context, type Model, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {openBrokerCompat} from "./compat.ts";
import {fetchBrokerModels, OPENBROKER_BASE_URL, validateOpenBrokerApiKey} from "./catalog.ts";
import {normalizeAssistantContent} from "./normalize.ts";
import type {ReasoningProfile} from "./profiles.ts";

const reasoningProfiles = new Map<string, ReasoningProfile>();

async function loginOpenBroker(callbacks: OAuthLoginCallbacks): Promise<string> {
  const apiKey = (await callbacks.onPrompt({message: "Paste your OpenBroker API key", placeholder: "obk-..."})).trim();
  if (callbacks.signal?.aborted) throw new Error("OpenBroker login cancelled");
  if (!apiKey) throw new Error("An OpenBroker API key is required");
  callbacks.onProgress?.("Validating OpenBroker API key...");
  await validateOpenBrokerApiKey(apiKey, callbacks.fetch ?? fetch);
  return apiKey;
}

function openBrokerStream(requested: Model, context: Context, options?: SimpleStreamOptions) {
  const carried = (requested as Model & {openBrokerProfile?: ReasoningProfile}).openBrokerProfile;
  const profile = carried ?? reasoningProfiles.get(requested.id);
  if (!profile) {
    throw new Error(
      `OpenBroker metadata for ${requested.id} is unavailable; refresh model discovery or select another model`,
    );
  }
  const outer = createAssistantMessageEventStream();
  const openaiModel: Model<"openai-completions"> = {
    ...requested,
    api: "openai-completions",
    compat: requested.compat ?? openBrokerCompat(requested, profile),
  } as Model<"openai-completions">;
  const streamOptions: SimpleStreamOptions = {
    ...options,
    onPayload: (payload: unknown, model?: Model<"openai-completions">) => {
      const normalized = profile.strictContent ? normalizeAssistantContent(payload) : payload;
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
  const baseUrl = OPENBROKER_BASE_URL;
  pi.registerProvider("openbroker", {
    baseUrl,
    api: "openbroker-completions",
    streamSimple: openBrokerStream,
    ...(environmentKey ? {apiKey: environmentKey} : {}),
    authHeader: true,
    oauth: {name: "OpenBroker", login: loginOpenBroker},
    fetchDynamicModels: async () => {
      const entries = await fetchBrokerModels();
      reasoningProfiles.clear();
      return entries.map(({model, profile}) => {
        reasoningProfiles.set(model.id, profile);
        const registered = {
          ...model,
          provider: "openbroker",
          api: "openbroker-completions",
          baseUrl,
          openBrokerProfile: profile,
          ...(model.thinking ? {thinking: model.thinking as unknown as Model["thinking"]} : {}),
        } as Model;
        return {...registered, compat: openBrokerCompat(registered, profile)};
      });
    },
  });
};

export default openBrokerProvider;
