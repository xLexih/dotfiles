import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {fetchSurplusModels, validateSurplusApiKey} from "./catalog.ts";

async function loginSurplus(callbacks: OAuthLoginCallbacks): Promise<string> {
  const apiKey = (await callbacks.onPrompt({
    message: "Paste your Surplus API key",
    placeholder: "inf_...",
  })).trim();
  if (callbacks.signal?.aborted) throw new Error("Surplus login cancelled");
  if (!apiKey) throw new Error("A Surplus API key is required");
  callbacks.onProgress?.("Validating Surplus API key...");
  await validateSurplusApiKey(apiKey, callbacks.fetch ?? fetch);
  return apiKey;
}

const surplusProvider: ExtensionFactory = pi => {
  const environmentKey = process.env.SURPLUS_API_KEY?.trim();
  pi.registerProvider("surplus", {
    baseUrl: "https://api.surplusintelligence.ai/v1",
    api: "openai-completions",
    ...(environmentKey ? {apiKey: environmentKey} : {}),
    authHeader: true,
    oauth: {name: "Surplus Intelligence", login: loginSurplus},
    fetchDynamicModels: apiKey => fetchSurplusModels(apiKey),
  });
  pi.on("session_start", async (_event, context) => {
    await context.modelRegistry.refreshRuntimeProviders("online");
  });
};

export default surplusProvider;
