# OMP time manager

This extension shows elapsed model-call and original-prompt durations in OMP's
status bar:

```text
Total 1:22 · Task 0:12
```

`Task duration` resets when each provider request begins and stops when its streamed
assistant message completes. `Total duration` begins when the original prompt is
submitted and stops only when the agent loop fully settles, including model calls,
tool execution, retries, and continuations. The completed values remain visible until
the next prompt resets them. Turn completion and OMP's authoritative idle state are
used as fallbacks so a delayed lifecycle notification cannot leave either timer running.
Cancelling an in-flight assistant request freezes both values immediately.
