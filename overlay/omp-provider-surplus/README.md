# OMP Surplus provider

This extension registers Surplus Intelligence as an OpenAI-compatible OMP provider.

Model discovery validates the configured `inf_...` key against the buyer endpoint,
intersects the model catalog with currently healthy marketplace routes, and reports
the best live input/output price from the market snapshot. The extension refreshes
that snapshot once at session startup; it remains fixed for the rest of the OMP
process. Run `omp models refresh` to force a refresh outside an interactive session.

Surplus API-key inference is paid from the buyer wallet/credit balance. A valid key
can list models while an unfunded account still receives HTTP 402. Fund and approve
the buyer account at <https://www.surplusintelligence.ai/buy> before inference.
