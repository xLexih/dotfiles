# OMP Surplus provider

This extension registers Surplus Intelligence's live concrete model catalog plus
the synthetic `surplus/cheap-trusted` and `surplus/cheap-untrusted` models.

Model discovery validates the configured `inf_...` key against the buyer endpoint,
intersects the model catalog with currently healthy marketplace routes, and exposes
each concrete model normally. `cheap-trusted` considers only providers marked trusted by Surplus;
`cheap-untrusted` considers the entire market, including untrusted providers. Tool,
image, context-window, and output-limit requirements are applied before comparing
prices. Model ID and provider name break ties. Concrete selections bypass the selector.
Surplus accounts default to trusted-only routing; enable untrusted providers in the
Routing preferences card on `/buy` before using `cheap-untrusted`.

At session startup the extension fetches the effective policy for the authenticated
API key from `/v1/buyer/preferences`. A key restricted to trusted providers removes
untrusted routes. The policy is fixed for that OMP session. If the policy request
fails, startup fails closed instead of falling back to the unrestricted public market.

Surplus currently keeps key-budget `providers_blocked` behind its web-session budget
API; inference keys cannot read that field themselves. This deployment therefore
preloads the key's Jatevo endpoint blocklist. It also treats Surplus's authoritative
`provider_not_in_key_scope` inference response as a session block: before any output
is emitted, the rejected provider is removed and the request is rerouted automatically.

The public market snapshot is refreshed at session startup, before a cheap request
when stale, and every 30 seconds to match the endpoint's current cache lifetime.
Concurrent refreshes are coalesced. Background refresh failures retain the last good
snapshot; a stale request-time refresh fails closed instead of spending against an
unverified quote. Provider-specific input, output, cache-read, and cache-write reference
prices come from Surplus's public `/v1/prices` matrix, whose one-hour cache lifetime is
honored locally. Marketplace discounts are applied to those fetched reference rates;
when a cache rate is absent, the live route input rate is used conservatively.

Routing has no seeded workload ratios, smoothing factor, or percentage-switch threshold.
A route is discarded only when another compatible route is no more expensive for every
fetched input, output, cache-read, and cache-write category and strictly cheaper for at
least one. Exact usage from the last successful OMP response orders the remaining
non-dominated routes without changing that guarantee. If multiple routes remain and
the current route is not among them, interactive OMP sessions ask the user to choose;
non-interactive sessions fail closed instead of inventing a weighting.

Cheap routes pin the selected provider in the inference request. OMP's primary model
label and working message show `Surplus → Cheapest[T] → model` for a trusted route or
`Surplus → Cheapest['T] → model` for an untrusted route. Direct model selections show
`Surplus → model`; routing details additionally include the provider and current
input/output/cache quote.
After the first request, a model/provider switch or any input/output/cache price increase
opens a selector with `Continue with this model`, `Switch once`, `Auto-switch this
session`, `Wait for price to revert`, and `Cancel`. Continuing retries the exact
previously approved model/provider rather than accepting the proposed route; if that
seller is unavailable, inference fails normally. Waiting pauses the request and
refreshes at most once per 30-second market-cache window until the previously approved
model/provider is again a non-dominated route at input/output/cache prices no higher than its
approved quote. The wait can be stopped through OMP's normal abort action. Auto-switch
accepts later changes for the current OMP session but still emits a warning
describing each automatically accepted switch. Price decreases on the same route are
accepted silently. Non-interactive sessions fail closed when a route change needs
approval.

Surplus API-key inference is paid from the buyer wallet/credit balance. A valid key
can list models while an unfunded account still receives HTTP 402. Fund and approve
the buyer account at <https://www.surplusintelligence.ai/buy> before inference.
