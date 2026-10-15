# ADR 0001: Local persistence and offline replay

## Status

Accepted for the trial implementation.

## Decision

Use Hive CE as the durable local database and keep the most recently opened 20
conversations in a bounded in-memory LRU cache. Reads use memory, then Hive;
chat generation uses the configured Gemini or OpenRouter stream. The fixed
sample responder is selected explicitly for UI development; a missing live key
produces a setup error instead of a sample being presented as a real answer.
History mutations and offline prompts enter a Hive outbox before the UI reports
them as queued. Replay sorts by creation time and operation ID and applies one
operation at a time.

The conflict rule is last-write-wins by operation timestamp. An older queued
mutation does not replace a newer remote record. The mock history service stores
applied operation IDs and ignores redelivery of the same ID. This proves client
replay behavior against the mock only. A real server must support idempotency
keys for the server to prevent duplicate mutations after an ambiguous timeout.

## Cache invalidation

| Write | Cache action |
| --- | --- |
| Save messages or a streamed delta | Replace that conversation's cached messages |
| Rename or pin | Message cache is unchanged; history provider is invalidated |
| Delete | Remove cached messages and invalidate history |
| Reopen | Refresh that conversation from memory or Hive |

## Consequences

The local transcript is available without a network connection and queued
operations survive process death. Hive is simple for this bounded trial slice.
A production service still needs remote history reads, server timestamps or
versions, and a documented idempotency contract.
