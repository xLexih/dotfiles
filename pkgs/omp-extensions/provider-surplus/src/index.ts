import {createAssistantMessageEventStream, type Context, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionContext, ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {applySurplusAccessPolicy, extendSurplusAccessPolicy, fetchPublicSurplusModels, fetchSurplusAccessPolicy, fetchSurplusModels, type SurplusAccessPolicy, type SurplusProviderModel, validateSurplusApiKey} from "./catalog.ts";
import {approvedRouteRestored, cheapAliasLabel, CONTINUE_WITH_MODEL, createCheapModels, isCheapAlias, pinSurplusProvider, resolveSelectedSurplusModel, resolveSurplusModel, routeAfterChoice, routeRequiresApproval, selectCheapestRoute, selectCheapestRoutes, surplusModelLabel, updateRoutingProfile, type RoutingProfile, type SelectedSurplusRoute} from "./router.ts";

const MARKET_REFRESH_MS = 30_000;
const STATUS_KEY = "surplus-route";
const SWITCH_ONCE = "Switch once";
const AUTO_SWITCH_SESSION = "Auto-switch this session";
const WAIT_FOR_REVERT = "Wait for price to revert";
const CANCEL_SWITCH = "Cancel";
const CONFIGURED_BLOCKED_PROVIDERS = ["api.jatevo.ai", "glm.jatevo.ai", "jatevo.ai", "lb.jatevo.ai"];

function isProviderScopeError(error: unknown): boolean {
  try {
    const text = error instanceof Error ? `${error.message} ${JSON.stringify(error.cause)}` : JSON.stringify(error);
    return /provider_not_in_key_scope|not scoped to any available provider/i.test(text);
  } catch {
    return false;
  }
}

async function loginSurplus(callbacks: OAuthLoginCallbacks): Promise<string> {
  const apiKey = (await callbacks.onPrompt({message: "Paste your Surplus API key", placeholder: "inf_..."})).trim();
  if (callbacks.signal?.aborted) throw new Error("Surplus login cancelled");
  if (!apiKey) throw new Error("A Surplus API key is required");
  callbacks.onProgress?.("Validating Surplus API key...");
  await validateSurplusApiKey(apiKey, callbacks.fetch ?? fetch);
  return apiKey;
}

function routeLabel(selected: SelectedSurplusRoute, aliasId: string): string {
  const {model, route} = selected;
  return `Surplus → ${cheapAliasLabel(aliasId, route.trusted) ?? aliasId} → ${model.id} @ ${route.provider} · in $${route.input} · out $${route.output} · cache $${route.cacheRead}/$${route.cacheWrite} per 1M`;
}

function confirmMessage(aliasId: string, previous: SelectedSurplusRoute, next: SelectedSurplusRoute): string {
  return `Previous: ${routeLabel(previous, aliasId)}\nNext: ${routeLabel(next, aliasId)}\n\nThe model/provider changed or at least one token price increased.`;
}

function wait(milliseconds: number, signal?: AbortSignal): Promise<void> {
  if (signal?.aborted) return Promise.reject(signal.reason ?? new Error("Surplus price wait aborted"));
  return new Promise((resolve, reject) => {
    const timer = setTimeout(done, milliseconds);
    function done(): void {
      signal?.removeEventListener("abort", aborted);
      resolve();
    }
    function aborted(): void {
      clearTimeout(timer);
      reject(signal?.reason ?? new Error("Surplus price wait aborted"));
    }
    signal?.addEventListener("abort", aborted, {once: true});
  });
}

const surplusProvider: ExtensionFactory = pi => {
  const environmentKey = process.env.SURPLUS_API_KEY?.trim();
  const approvedRoutes = new Map<string, SelectedSurplusRoute>();
  let candidates: SurplusProviderModel[] = [];
  let refreshedAt = 0;
  let refresh: Promise<void> | undefined;
  let sessionContext: ExtensionContext | undefined;
  let autoSwitchSession = false;
  let routingProfile: RoutingProfile | undefined;
  let accessPolicy: SurplusAccessPolicy | undefined;
  let accessPolicyPromise: Promise<SurplusAccessPolicy> | undefined;

  const updateCandidates = async (models: Promise<SurplusProviderModel[]>): Promise<SurplusProviderModel[]> => {
    const next = await models;
    candidates = next;
    refreshedAt = Date.now();
    return next;
  };

  const refreshMarket = (): Promise<void> => {
    if (refresh) return refresh;
    if (!accessPolicy) return Promise.reject(new Error("Surplus key access policy is not initialized"));
    refresh = updateCandidates(fetchPublicSurplusModels(fetch, accessPolicy)).then(() => undefined).finally(() => { refresh = undefined; });
    return refresh;
  };

  const refreshSafely = (): Promise<void> => refreshMarket()
    .catch(err => pi.logger.warn("Surplus market refresh failed; retaining the last snapshot", {err}));

  const waitForPriceRevert = async (aliasId: string, previous: SelectedSurplusRoute, context: Context, options?: SimpleStreamOptions): Promise<SelectedSurplusRoute> => {
    sessionContext?.ui.setStatus(STATUS_KEY, `Surplus → waiting for ${previous.model.id} @ ${previous.route.provider} price to revert`);
    sessionContext?.ui.setWorkingMessage("Waiting for Surplus price to revert");
    let lastAttemptAt = Date.now();
    while (true) {
      await wait(Math.max(1_000, MARKET_REFRESH_MS - (Date.now() - lastAttemptAt)), options?.signal);
      lastAttemptAt = Date.now();
      try {
        await refreshMarket();
      } catch (err) {
        pi.logger.warn("Surplus market refresh failed while waiting for price reversion", {err});
        continue;
      }
      const reverted = selectCheapestRoute(candidates, aliasId, context, options, routingProfile, previous);
      if (reverted && approvedRouteRestored(previous, reverted)) {
        sessionContext?.ui.notify(`Surplus price reverted; continuing.\n${routeLabel(reverted, aliasId)}`, "info");
        return reverted;
      }
    }
  };

  const chooseStrictRoute = async (aliasId: string, routes: SelectedSurplusRoute[], previous?: SelectedSurplusRoute): Promise<{selected: SelectedSurplusRoute; explicit: boolean}> => {
    if (!routes.length) throw new Error(`Surplus has no healthy ${aliasId} model compatible with this request`);
    const current = previous && routes.find(route => route.model.id === previous.model.id && route.route.provider === previous.route.provider);
    if (current) return {selected: current, explicit: false};
    if (routes.length === 1) return {selected: routes[0]!, explicit: false};
    if (!sessionContext?.hasUI) throw new Error(`Surplus has ${routes.length} non-dominated routes; interactive selection is required`);
    const labels = routes.map(route => routeLabel(route, aliasId));
    const choice = await sessionContext.ui.select("No route is cheapest for every input/output/cache mix. Choose from the non-dominated live routes:", labels);
    const index = choice === undefined ? -1 : labels.indexOf(choice);
    if (index < 0) throw new Error("Surplus route selection cancelled");
    return {selected: routes[index]!, explicit: true};
  };

  const approveRoute = async (aliasId: string, selected: SelectedSurplusRoute, context: Context, options?: SimpleStreamOptions, explicit = false): Promise<SelectedSurplusRoute> => {
    const previous = approvedRoutes.get(aliasId);
    if (previous && routeRequiresApproval(previous, selected) && !explicit) {
      if (!sessionContext?.hasUI) throw new Error(`${routeLabel(selected, aliasId)} requires approval, but interactive UI is unavailable`);
      if (autoSwitchSession) {
        sessionContext.ui.notify(`Surplus route change automatically accepted.\n${confirmMessage(aliasId, previous, selected)}`, "warning");
      } else {
        const choice = await sessionContext.ui.select(`Surplus route changed\n\n${confirmMessage(aliasId, previous, selected)}`, [
          CONTINUE_WITH_MODEL,
          SWITCH_ONCE,
          AUTO_SWITCH_SESSION,
          WAIT_FOR_REVERT,
          CANCEL_SWITCH,
        ]);
        if (choice === CONTINUE_WITH_MODEL) {
          selected = routeAfterChoice(choice, previous, selected);
          sessionContext.ui.notify(`Continuing with the previously approved model/provider.\n${routeLabel(selected, aliasId)}`, "warning");
        } else if (choice === AUTO_SWITCH_SESSION) {
          autoSwitchSession = true;
          sessionContext.ui.notify(`Surplus route change automatically accepted; auto-switch is enabled for this session.\n${confirmMessage(aliasId, previous, selected)}`, "warning");
        } else if (choice === WAIT_FOR_REVERT) {
          selected = await waitForPriceRevert(aliasId, previous, context, options);
        } else if (choice !== SWITCH_ONCE) {
          throw new Error("Surplus route change rejected");
        }
      }
    }
    approvedRoutes.set(aliasId, selected);
    sessionContext?.ui.setStatus(STATUS_KEY, routeLabel(selected, aliasId));
    return selected;
  };

  pi.registerProvider("surplus", {
    baseUrl: "https://api.surplusintelligence.ai/v1",
    api: "surplus-cheapest" as never,
    streamSimple: (requested, context, options) => {
      const outer = createAssistantMessageEventStream();
      void (async () => {
        try {
          if (isCheapAlias(requested.id) && Date.now() - refreshedAt >= MARKET_REFRESH_MS) {
            await outer.trackLocalWork(refreshMarket());
          }
          let scopeRetries = 0;
          while (true) {
            const previous = approvedRoutes.get(requested.id);
            const resolved = resolveSurplusModel(requested, candidates, context, options, routingProfile, previous);
            let explicitlyApproved = false;
            if (isCheapAlias(requested.id)) {
              const strict = await outer.trackLocalWork(chooseStrictRoute(requested.id,
                selectCheapestRoutes(candidates, requested.id, context, options, routingProfile, previous), previous));
              resolved.selected = strict.selected;
              explicitlyApproved = strict.explicit;
            }
            let streamOptions = options;
            let selected: SelectedSurplusRoute | undefined;
            if (resolved.selected) {
              selected = await outer.trackLocalWork(approveRoute(requested.id, resolved.selected, context, options, explicitlyApproved));
              requested.name = surplusModelLabel(selected.model, requested.id, selected.route.trusted);
              resolved.model = resolveSelectedSurplusModel(requested, selected);
              sessionContext?.ui.setWorkingMessage(routeLabel(selected, requested.id));
              streamOptions = pinSurplusProvider(options, selected.route.provider);
              pi.logger.debug("Surplus selected protected cheap route", {alias: requested.id,
                model: selected.model.id, provider: selected.route.provider,
                trusted: selected.route.trusted, inputPrice: selected.route.input,
                outputPrice: selected.route.output});
            } else {
              sessionContext?.ui.setStatus(STATUS_KEY, `Surplus → ${resolved.model.id}`);
            }
            let emitted = false;
            try {
              let scopeRejected = false;
              for await (const event of streamOpenAICompletions(resolved.model, context, streamOptions)) {
                if (!emitted && event.type === "error" && selected && accessPolicy && isProviderScopeError(event)) {
                  scopeRejected = true;
                  break;
                }
                emitted = true;
                if (event.type === "done") routingProfile = updateRoutingProfile(event.message.usage);
                outer.push(event);
              }
              if (scopeRejected && selected && accessPolicy && scopeRetries++ < 10) {
                accessPolicy = extendSurplusAccessPolicy(accessPolicy, [selected.route.provider]);
                candidates = applySurplusAccessPolicy(candidates, accessPolicy);
                approvedRoutes.delete(requested.id);
                sessionContext?.ui.notify(`Surplus rejected ${selected.route.provider} for this API key; removed it for this session and retrying.`, "warning");
                continue;
              }
              break;
            } catch (error) {
              if (!emitted && selected && accessPolicy && isProviderScopeError(error) && scopeRetries++ < 10) {
                accessPolicy = extendSurplusAccessPolicy(accessPolicy, [selected.route.provider]);
                candidates = applySurplusAccessPolicy(candidates, accessPolicy);
                approvedRoutes.delete(requested.id);
                sessionContext?.ui.notify(`Surplus rejected ${selected.route.provider} for this API key; removed it for this session and retrying.`, "warning");
                continue;
              }
              throw error;
            }
          }
        } catch (error) {
          outer.fail(error);
        } finally {
          sessionContext?.ui.setWorkingMessage();
        }
      })();
      return outer;
    },
    ...(environmentKey ? {apiKey: environmentKey} : {}),
    authHeader: true,
    oauth: {name: "Surplus Intelligence", login: loginSurplus},
    fetchDynamicModels: async apiKey => {
      accessPolicyPromise ??= fetchSurplusAccessPolicy(apiKey).catch(error => {
        accessPolicyPromise = undefined;
        throw error;
      });
      accessPolicy = extendSurplusAccessPolicy(await accessPolicyPromise, CONFIGURED_BLOCKED_PROVIDERS);
      const models = await updateCandidates(fetchSurplusModels(apiKey, fetch, accessPolicy));
      return models.length ? [...models, ...createCheapModels(models)] : [];
    },
  });
  pi.on("session_start", (_event, context) => {
    autoSwitchSession = false;
    routingProfile = undefined;
    accessPolicy = undefined;
    accessPolicyPromise = undefined;
    sessionContext = context;
    context.setInterval(refreshSafely, MARKET_REFRESH_MS);
    void (async () => {
      try {
        await context.modelRegistry.refreshRuntimeProviders("online");
        if (!candidates.length) await refreshSafely();
      } catch (err) {
        pi.logger.warn("Surplus startup refresh failed; continuing without live market data", {err});
      }
    })();
  });
};

export default surplusProvider;
