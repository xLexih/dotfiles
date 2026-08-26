import type {Context, Model, SimpleStreamOptions, Usage} from "@oh-my-pi/pi-ai";
import type {SurplusProviderModel, SurplusProviderRoute} from "./catalog.ts";

export const CHEAP_TRUSTED_MODEL_ID = "cheap-trusted";
export const CHEAP_UNTRUSTED_MODEL_ID = "cheap-untrusted";
export const CONTINUE_WITH_MODEL = "Continue with this model";

export interface RoutingProfile {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
}

export interface SelectedSurplusRoute {
  model: SurplusProviderModel;
  route: SurplusProviderRoute;
  score: number;
}

export interface ResolvedSurplusModel {
  model: Model<"openai-completions">;
  selected?: SelectedSurplusRoute;
}

export function routeAfterChoice(choice: string | undefined, previous: SelectedSurplusRoute, selected: SelectedSurplusRoute): SelectedSurplusRoute {
  return choice === CONTINUE_WITH_MODEL ? previous : selected;
}

export function updateRoutingProfile(usage: Usage): RoutingProfile {
  return {input: usage.input, output: usage.output, cacheRead: usage.cacheRead, cacheWrite: usage.cacheWrite};
}

export function isCheapAlias(id: string): boolean {
  return id === CHEAP_TRUSTED_MODEL_ID || id === CHEAP_UNTRUSTED_MODEL_ID;
}

export function cheapAliasLabel(id: string, trusted: boolean): string | undefined {
  if (!isCheapAlias(id)) return undefined;
  return trusted ? "Cheapest[T]" : "Cheapest['T]";
}

export function surplusModelLabel(model: Pick<Model, "id" | "name">, aliasId?: string, trusted = true): string {
  const concrete = (model.name?.trim() || model.id).replace(/^Surplus → /, "").replace(/ \(Surplus\)$/, "");
  const alias = aliasId ? cheapAliasLabel(aliasId, trusted) : undefined;
  return `Surplus → ${alias ? `${alias} → ` : ""}${concrete}`;
}

export function routeRequiresApproval(previous: SelectedSurplusRoute, next: SelectedSurplusRoute): boolean {
  return previous.model.id !== next.model.id || previous.route.provider !== next.route.provider
    || next.route.input > previous.route.input || next.route.output > previous.route.output
    || next.route.cacheRead > previous.route.cacheRead || next.route.cacheWrite > previous.route.cacheWrite;
}

export function approvedRouteRestored(previous: SelectedSurplusRoute, next: SelectedSurplusRoute): boolean {
  return !routeRequiresApproval(previous, next);
}

export function pinSurplusProvider(options: SimpleStreamOptions | undefined, provider: string): SimpleStreamOptions {
  return {...options, onPayload: (payload, model) => {
    if (payload && typeof payload === "object" && !Array.isArray(payload)) (payload as Record<string, unknown>).provider = provider;
    return options?.onPayload?.(payload, model);
  }};
}

function hasImage(value: unknown): boolean {
  if (!value || typeof value !== "object") return false;
  if (Array.isArray(value)) return value.some(hasImage);
  const record = value as Record<string, unknown>;
  return record.type === "image" || record.type === "image_url" || Object.values(record).some(hasImage);
}

export function estimateInputTokens(context: Context): number {
  return Math.max(1, Math.ceil(JSON.stringify(context).length / 4));
}

function sameRoute(left: SelectedSurplusRoute, right: SelectedSurplusRoute): boolean {
  return left.model.id === right.model.id && left.route.provider === right.route.provider;
}

function routeScore(route: SurplusProviderRoute, profile?: RoutingProfile): number {
  if (!profile) return 0;
  return profile.input * route.input + profile.output * route.output
    + profile.cacheRead * route.cacheRead + profile.cacheWrite * route.cacheWrite;
}

function isCompatible(model: SurplusProviderModel, context: Context, options?: SimpleStreamOptions): boolean {
  const outputTokens = options?.maxTokens ?? 0;
  return (!context.tools?.length || model.supportsTools)
    && (!hasImage(context.messages) || model.input.includes("image"))
    && model.maxTokens >= outputTokens
    && model.contextWindow >= estimateInputTokens(context) + outputTokens;
}

export function selectCheapestRoute(
  models: readonly SurplusProviderModel[],
  aliasId: string,
  context: Context,
  options?: SimpleStreamOptions,
  profile?: RoutingProfile,
  previous?: SelectedSurplusRoute,
): SelectedSurplusRoute | undefined {
  const routes = selectCheapestRoutes(models, aliasId, context, options, profile, previous);
  if (!routes.length) return undefined;
  const current = previous && routes.find(route => sameRoute(route, previous));
  return current ?? routes[0];
}

function priceVector(selected: SelectedSurplusRoute, previous?: SelectedSurplusRoute): readonly number[] {
  const {route} = selected;
  return [route.input, route.output, route.cacheRead,
    previous && sameRoute(selected, previous) ? route.cacheRead : route.cacheWrite, route.cacheWrite];
}

function dominates(left: SelectedSurplusRoute, right: SelectedSurplusRoute, previous?: SelectedSurplusRoute): boolean {
  const a = priceVector(left, previous);
  const b = priceVector(right, previous);
  return a.every((value, index) => value <= b[index]!) && a.some((value, index) => value < b[index]!);
}

export function selectCheapestRoutes(
  models: readonly SurplusProviderModel[],
  aliasId: string,
  context: Context,
  options?: SimpleStreamOptions,
  profile?: RoutingProfile,
  previous?: SelectedSurplusRoute,
): SelectedSurplusRoute[] {
  const trustedOnly = aliasId === CHEAP_TRUSTED_MODEL_ID;
  if (!trustedOnly && aliasId !== CHEAP_UNTRUSTED_MODEL_ID) return [];
  const routes = models
    .filter(model => isCompatible(model, context, options))
    .flatMap(model => model.routes
      .filter(route => !trustedOnly || route.trusted)
      .map(route => ({model, route, score: routeScore(route, profile)})))
    .sort((left, right) => left.score - right.score
      || left.model.id.localeCompare(right.model.id)
      || left.route.provider.localeCompare(right.route.provider));
  return routes.filter(route => !routes.some(other => other !== route && dominates(other, route, previous)));
}

function routeCost(model: SurplusProviderModel, route: SurplusProviderRoute): SurplusProviderModel["cost"] {
  return {...model.cost, input: route.input, output: route.output,
    cacheRead: route.cacheRead, cacheWrite: route.cacheWrite};
}

export function resolveSelectedSurplusModel(requested: Model, selected: SelectedSurplusRoute): Model<"openai-completions"> {
  return {...requested, ...selected.model, cost: routeCost(selected.model, selected.route), api: "openai-completions"};
}

export function createCheapModel(models: readonly SurplusProviderModel[], aliasId: string): SurplusProviderModel {
  const selected = selectCheapestRoute(models, aliasId, {messages: []}, {maxTokens: 0});
  if (!selected) throw new Error(`Surplus returned no routing candidates for ${aliasId}`);
  return {
    ...selected.model,
    id: aliasId,
    name: surplusModelLabel(selected.model, aliasId, selected.route.trusted),
    cost: routeCost(selected.model, selected.route),
    reasoning: models.some(model => model.reasoning),
    input: models.some(model => model.input.includes("image")) ? ["text", "image"] : ["text"],
    contextWindow: Math.max(...models.map(model => model.contextWindow)),
    maxTokens: Math.max(...models.map(model => model.maxTokens)),
    compat: {supportsDeveloperRole: true, supportsReasoningEffort: false, maxTokensField: "max_tokens"},
    supportsTools: models.some(model => model.supportsTools),
    routes: [],
  };
}

export function createCheapModels(models: readonly SurplusProviderModel[]): SurplusProviderModel[] {
  return [createCheapModel(models, CHEAP_TRUSTED_MODEL_ID), createCheapModel(models, CHEAP_UNTRUSTED_MODEL_ID)];
}

export function resolveSurplusModel(
  requested: Model,
  models: readonly SurplusProviderModel[],
  context: Context,
  options?: SimpleStreamOptions,
  profile?: RoutingProfile,
  previous?: SelectedSurplusRoute,
): ResolvedSurplusModel {
  if (isCheapAlias(requested.id)) {
    const selected = selectCheapestRoute(models, requested.id, context, options, profile, previous);
    if (!selected) throw new Error(`Surplus has no healthy ${requested.id} model compatible with this request`);
    return {selected, model: resolveSelectedSurplusModel(requested, selected)};
  }
  const current = models.find(candidate => candidate.id === requested.id);
  return {model: {...requested, ...(current ?? {}), api: "openai-completions"}};
}
