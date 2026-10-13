# ADR 0002: Streaming lifecycle and rendering

## Status

Accepted for the trial implementation.

## Decision

Each active response has a generation and message ID. Cancellation, route
changes, and a newer request invalidate the generation before a subscription is
cancelled, so late events cannot update another conversation. Stream deltas are
batched for 70 ms and persisted in order; stop preserves the last persisted
partial response. A response that was streaming during process death reopens as
stopped and can be retried explicitly.

Render assistant output as GitHub-flavored Markdown. Fenced code blocks use a
separate horizontal scroller and copy action. Gemini SSE cancellation is tied
to Dio's request cancellation token. Without `GEMINI_API_KEY`, a deterministic
mock stream exercises Markdown, stop, and retry behavior.

## Consequences

The fake stream and SSE adapter can exercise ordering and cancellation without
credentials. A real Gemini call is at-least-once from the client's perspective:
if the app loses the response after the server accepts a prompt, the client
cannot prove whether generation completed.
