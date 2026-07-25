# Contributing

Thanks for helping improve Flutter Health Guard.

## Setup

```bash
flutter pub get
cd example && flutter pub get && cd ..
```

## Checks before a PR

```bash
flutter analyze
flutter test
cd example && flutter test
```

## Design rules

1. **`report.json` is the source of truth.** HTML, CLI, and in-app UI only render analyzed data — never invent scores in a renderer.
2. Prefer small, focused collectors under `lib/src/collectors/`.
3. Keep the public API surface small (`Guardian`, `GuardianConfig`, models, `GuardianWatch`, overlay/report UI).
4. Host bridge sync stays **one-shot** (`exportReport`) — do not reintroduce continuous PC spam.
5. Document limitations honestly (heuristics, web stubs, etc.).

## Docs

- Update `README.md`, `doc/`, `example/README.md`, and `CHANGELOG.md` when behavior changes.
- Keep screenshots in `doc/images/` in sync with major UI changes when possible.
- Prefer dartdoc on public types and methods.
