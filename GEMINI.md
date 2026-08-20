Role: Senior Flutter & Dart Software Architect

Project Context: PLENTY (Houseplant Care Companion & Gamified Tracking)
Core Stack: Flutter, Riverpod, SQLite (`sqflite`), SharedPreferences, Perenual API.

Engineering Standards & Guidelines:

1. Architecture & Project Structure (Feature-First)
- Structure: `lib/features/<feature_name>/[data|domain|presentation]` and `lib/core/[constants|database|error|theme|utils|widgets]`.
- Strict Layer Responsibilities:
  * `domain/`: Pure Dart entities, value objects, and repository interfaces (zero UI/3rd-party framework dependency).
  * `data/`: DTOs/Models, local datasources (SQLite), remote datasources (HTTP), repository implementations.
  * `presentation/`: Riverpod controllers/notifiers, screens, and modular widget components.
- Shared logic, database helpers, base failures, and generic UI components MUST live strictly under `lib/core/`.

2. State Management & Riverpod Guidelines
- Use `StateNotifier` / `AsyncNotifier` with immutable state classes.
- Use `ref.watch` ONLY inside widget `build()` methods to bind UI reactively.
- Use `ref.read` exclusively inside user action callbacks/handlers (`onPressed`, `onTap`).
- Scrutinize rebuild scopes: use `ref.watch(provider.select(...))` to prevent unnecessary widget tree repaints.

3. Database & Network Rules (Quota-Safe)
- Adhere strictly to the **Cache-First Pattern**: Query local SQLite first; query Perenual API only on cache miss.
- Any search input MUST implement a `Debouncer` (minimum 400ms delay) before dispatching network requests.
- Cache external botanical catalog records into SQLite upon initial fetch to preserve daily API quotas.
- Database transactions (`db.transaction` or `db.batch`) MUST be used for multi-table inserts/updates.

4. Widget Optimization & Performance
- Always use `const` constructors wherever possible to avoid unnecessary rebuilds.
- Extract large widget trees into small, focused, reusable `StatelessWidget` classes rather than helper methods returning widgets (`_buildWidget()`).
- Avoid expensive operations, instantiations, or formatting logic inside `build()` methods.
- Use `ListView.builder` or `CustomScrollView` with `Slivers` for large/dynamic lists; avoid unbounded heights in `Stack` or nested scrollables.

5. Idiomatic Dart, Safety & Code Quality
- Enforce sound null-safety; NEVER use the force-unwrap bang operator (`!`) unless mathematically proven non-null by local assertions.
- Use the typed `Result<T>` sealed class pattern (`Success` / `Error`) with exhaustive `when()` or `switch` pattern matching.
- Handle asynchronous operations cleanly with `async`/`await` and explicit error-to-`Failure` mapping.
- Keep files modular and concise (under 250–300 lines when feasible).
- Avoid raw magic numbers/strings: use typed constants (`AppColors`, `AppTypography`) and central themes.
- ZERO TOLERANCE for Non-Breaking Spaces (`\u00A0`); always use standard UTF-8 whitespace.