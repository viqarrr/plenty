# PLENTY — Gamified Plant Care App (MVP)
## Technical Implementation Plan — v2 (Updated Flow)

**Stack:** Flutter (Dart) · 2-Layer MVP Architecture (Presentation + Data) · SQLite (`sqflite`) · `shared_preferences` · Perenual API · `flutter_local_notifications` · `fl_chart` (growth graph)
**Timeline:** 5 weeks
**Architecture constraint:** No Domain layer. No Entities. No UseCases. No `toEntity`/`fromEntity` mappers.

> **v2 changelog (vs. original flow):** Onboarding is now decoupled from plant creation and ends in a skippable CTA. Plant creation is a single **Unified Add Plant Flow** reachable from three entry points. Daily tasks changed: `Cek Hama` removed, replaced by `Monitor Tinggi Tanaman` (height input that writes to the growth log). Time Capsule can now be created inline during plant setup, not only from the profile. New **Level/XP** stat per plant, plus a Tasks Completed counter and a height-over-time graph on the Plant Details screen. Community Forum is **unchanged** from v1 (not pictured in the new diagram, but still in scope per the original PRD) — flagged as an assumption below.

---

## 1. Architectural Blueprint & Data Flow

### 1.1 Pattern Summary (unchanged)

- **Data Layer** — `DataSource` → `Repository` (returns Models directly, no mapping step).
- **Presentation Layer** — `Controller`/`StateNotifier` (Riverpod) → `Screen`/`Widget`.

```
UI Widget → Controller method → Repository method → DataSource → SQLite/API
                                      ↓
                            Controller updates state → Widget rebuilds
```

### 1.2 Folder Structure (updated)

```
lib/
  core/
    constants/          # colors.dart, tiers.dart, task_types.dart, xp_config.dart
    db/                 # AppDatabase (sqflite singleton, migrations)
    utils/              # date_utils.dart, image_utils.dart
    theme/              # app_theme.dart
  data/
    models/
      user_model.dart
      user_preferences_model.dart
      plant_catalog_model.dart
      plant_model.dart              # now carries level, xp
      care_schedule_model.dart
      care_action_log_model.dart
      growth_log_model.dart         # photo now optional
      time_capsule_model.dart
      user_streak_model.dart
      badge_model.dart
      user_badge_model.dart
      community_post_model.dart
      post_comment_model.dart
    datasources/
      local/ ...
      remote/
        perenual_remote_datasource.dart
        weather_remote_datasource.dart
    repositories/
      user_repository.dart
      plant_repository.dart          # now owns Unified Add Plant Flow persistence
      care_repository.dart
      growth_repository.dart         # now also handles height-log + XP awarding
      streak_repository.dart
      badge_repository.dart
      forum_repository.dart
  presentation/
    onboarding/                      # 3-question flow only, no plant creation
    add_plant/                       # NEW: unified 3-step + time capsule modal
    home/                            # empty state + populated state
    plant_details/                   # renamed from plant_profile; adds Level/XP, graph
    daily_routine/                   # renamed from daily_checklist
    forum/
    gamification/
  main.dart
```

### 1.3 Database Schema (updated `CREATE TABLE`)

Changes from v1 are marked `-- v2`.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE user_preferences (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  experience_level TEXT NOT NULL,        -- 'beginner' | 'intermediate' | 'master'  -- v2 labels
  available_time TEXT,                   -- 'daily' | 'weekly'                      -- v2 (was free text)
  safety_restriction TEXT,               -- 'child_safe' | 'pet_safe' | 'none'      -- v2 (single select, was boolean)
  has_completed_onboarding INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE plant_catalog (
  id TEXT PRIMARY KEY,
  common_name TEXT NOT NULL,
  scientific_name TEXT,
  family TEXT,
  default_watering_interval INTEGER NOT NULL DEFAULT 3,
  sunlight_level TEXT,
  care_level TEXT,
  image_url TEXT,
  local_image_path TEXT,
  cached_at TEXT NOT NULL
);

CREATE TABLE user_plants (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  catalog_id TEXT REFERENCES plant_catalog(id),
  nickname TEXT NOT NULL,
  is_indoor INTEGER NOT NULL DEFAULT 1,        -- v2, from Step 2 (Indoor/Outdoor)
  sunlight_condition TEXT,                     -- v2, from Step 2
  pot_size TEXT,                                -- v2, from Step 2
  window_distance TEXT,                         -- v2, from Step 2
  initial_height_cm REAL,                       -- v2, from Step 3
  adopted_at TEXT NOT NULL,
  cover_photo_path TEXT,
  health_status TEXT NOT NULL DEFAULT 'healthy',
  level INTEGER NOT NULL DEFAULT 1,             -- v2
  xp INTEGER NOT NULL DEFAULT 0,                -- v2
  is_archived INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE care_schedules (
  id TEXT PRIMARY KEY,
  user_plant_id TEXT NOT NULL REFERENCES user_plants(id),
  task_type TEXT NOT NULL,          -- v2: 'siram' | 'bersih_bersih' | 'monitor_tinggi'  (cek_hama removed)
  interval_days INTEGER,
  last_performed_at TEXT,
  next_due_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE care_action_logs (
  id TEXT PRIMARY KEY,
  user_plant_id TEXT NOT NULL REFERENCES user_plants(id),
  task_type TEXT NOT NULL,
  completed_at TEXT NOT NULL,
  log_date TEXT NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 0,   -- v2, for audit/debug of XP source
  notes TEXT
);

CREATE TABLE growth_logs (
  id TEXT PRIMARY KEY,
  user_plant_id TEXT NOT NULL REFERENCES user_plants(id),
  photo_path TEXT,                  -- v2: now NULLABLE — daily height task has no photo
  height_cm REAL,
  leaf_count INTEGER,
  note TEXT,
  source TEXT NOT NULL DEFAULT 'manual',   -- v2: 'manual' | 'daily_task' | 'initial'
  logged_at TEXT NOT NULL
);

CREATE TABLE time_capsules (
  id TEXT PRIMARY KEY,
  user_plant_id TEXT NOT NULL REFERENCES user_plants(id),
  photo_path TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL,
  unlock_at TEXT NOT NULL,
  is_unlocked INTEGER NOT NULL DEFAULT 0
);
-- MVP: max 1 row per user_plant_id, enforced in repository. Creatable either
-- inline during Add Plant Step 3 (v2) or later from Plant Details ("Create Time Capsule").

CREATE TABLE user_streaks (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  current_tier INTEGER NOT NULL DEFAULT 1,
  last_streak_date TEXT,
  freeze_tokens_available INTEGER NOT NULL DEFAULT 1,   -- kept; see §1.4 assumption note
  freeze_used_on TEXT
);

CREATE TABLE badges ( id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL, icon_asset_path TEXT NOT NULL );
CREATE TABLE user_badges ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), badge_id TEXT NOT NULL REFERENCES badges(id), unlocked_at TEXT NOT NULL, UNIQUE(user_id, badge_id) );
CREATE TABLE community_posts ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), category TEXT NOT NULL, caption TEXT, image_url TEXT, kudos_count INTEGER NOT NULL DEFAULT 0, comment_count INTEGER NOT NULL DEFAULT 0, selected_solution_comment_id TEXT, created_at TEXT NOT NULL );
CREATE TABLE post_comments ( id TEXT PRIMARY KEY, post_id TEXT NOT NULL REFERENCES community_posts(id), user_id TEXT NOT NULL REFERENCES users(id), content TEXT NOT NULL, created_at TEXT NOT NULL );

CREATE INDEX idx_care_logs_plant_date ON care_action_logs(user_plant_id, log_date);
CREATE INDEX idx_schedules_plant ON care_schedules(user_plant_id);
CREATE INDEX idx_growth_plant_date ON growth_logs(user_plant_id, logged_at);  -- v2, for graph queries
CREATE INDEX idx_posts_category ON community_posts(category);
```

> **⚠️ Assumption flagged:** the new diagram doesn't show Streak Freeze/Tolerance or the Community Forum. Both are kept as-is from the original PRD scope since nothing in the new flow contradicts them — they're simply out of frame in this particular diagram (which focuses on onboarding → add-plant → home → daily routine → plant details). Confirm with product if either was intentionally cut.

### 1.4 XP / Level System (new, v2)

No XP curve was specified in the diagram — this plan assumes a simple, tunable linear-step curve so it ships in 5 weeks. Treat as a placeholder to swap later:

```dart
// core/constants/xp_config.dart
class XpConfig {
  static const Map<String, int> xpPerTask = {
    'siram': 10,
    'bersih_bersih': 10,
    'monitor_tinggi': 15,   // slightly higher — requires actual input, not just a tap
  };
  static const int xpPerLevel = 100;   // Level = (xp / 100).floor() + 1
  static int levelForXp(int xp) => (xp ~/ xpPerLevel) + 1;
}
```

### 1.5 Dart Model Signatures (updated)

```dart
// data/models/plant_model.dart
class PlantModel {
  final String id;
  final String userId;
  final String? catalogId;
  final String nickname;
  final bool isIndoor;
  final String? sunlightCondition;
  final String? potSize;
  final String? windowDistance;
  final double? initialHeightCm;
  final DateTime adoptedAt;
  final String? coverPhotoPath;
  final String healthStatus;
  final int level;      // v2
  final int xp;          // v2
  final bool isArchived;
  final String? commonName;
  final int defaultWateringInterval;

  const PlantModel({
    required this.id,
    required this.userId,
    this.catalogId,
    required this.nickname,
    this.isIndoor = true,
    this.sunlightCondition,
    this.potSize,
    this.windowDistance,
    this.initialHeightCm,
    required this.adoptedAt,
    this.coverPhotoPath,
    this.healthStatus = 'healthy',
    this.level = 1,
    this.xp = 0,
    this.isArchived = false,
    this.commonName,
    this.defaultWateringInterval = 3,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map) => PlantModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        catalogId: map['catalog_id'] as String?,
        nickname: map['nickname'] as String,
        isIndoor: (map['is_indoor'] as int? ?? 1) == 1,
        sunlightCondition: map['sunlight_condition'] as String?,
        potSize: map['pot_size'] as String?,
        windowDistance: map['window_distance'] as String?,
        initialHeightCm: (map['initial_height_cm'] as num?)?.toDouble(),
        adoptedAt: DateTime.parse(map['adopted_at'] as String),
        coverPhotoPath: map['cover_photo_path'] as String?,
        healthStatus: map['health_status'] as String? ?? 'healthy',
        level: map['level'] as int? ?? 1,
        xp: map['xp'] as int? ?? 0,
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
        commonName: map['common_name'] as String?,
        defaultWateringInterval: map['default_watering_interval'] as int? ?? 3,
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'user_id': userId, 'catalog_id': catalogId, 'nickname': nickname,
        'is_indoor': isIndoor ? 1 : 0, 'sunlight_condition': sunlightCondition,
        'pot_size': potSize, 'window_distance': windowDistance,
        'initial_height_cm': initialHeightCm, 'adopted_at': adoptedAt.toIso8601String(),
        'cover_photo_path': coverPhotoPath, 'health_status': healthStatus,
        'level': level, 'xp': xp, 'is_archived': isArchived ? 1 : 0,
      };
}

// data/models/growth_log_model.dart (photo now optional, +source)
class GrowthLogModel {
  final String id;
  final String userPlantId;
  final String? photoPath;         // v2: nullable
  final double? heightCm;
  final int? leafCount;
  final String? note;
  final String source;             // v2: 'manual' | 'daily_task' | 'initial'
  final DateTime loggedAt;

  const GrowthLogModel({
    required this.id,
    required this.userPlantId,
    this.photoPath,
    this.heightCm,
    this.leafCount,
    this.note,
    this.source = 'manual',
    required this.loggedAt,
  });

  factory GrowthLogModel.fromMap(Map<String, dynamic> map) => GrowthLogModel(
        id: map['id'] as String,
        userPlantId: map['user_plant_id'] as String,
        photoPath: map['photo_path'] as String?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        leafCount: map['leaf_count'] as int?,
        note: map['note'] as String?,
        source: map['source'] as String? ?? 'manual',
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'user_plant_id': userPlantId, 'photo_path': photoPath,
        'height_cm': heightCm, 'leaf_count': leafCount, 'note': note,
        'source': source, 'logged_at': loggedAt.toIso8601String(),
      };
}
```

`UserModel`, `DailyCareLogModel` → `CareActionLogModel` (add `xpAwarded` field), `ForumPostModel` carry over unchanged from v1 aside from the trivial rename.

---

## 2. Phase-by-Phase Execution Roadmap

### Phase 0 — Project Foundation (Days 1–2) — unchanged from v1
Skeleton, `AppDatabase`, theme, router, seed badges. Add `fl_chart` to `pubspec.yaml` for the growth graph, add `xp_config.dart`.

---

### Phase 1 — Onboarding (decoupled) + Unified Add Plant Flow (Days 3–6)

**Goal:** Onboarding collects 3 answers and ends in a skippable CTA; plant creation is a standalone flow reusable from 3 entry points.

**Task Checklist**
- [ ] `presentation/onboarding/onboarding_controller.dart` — 3-step state machine: `experienceLevel` → `availableTime` → `safetyRestriction`; each answer persisted immediately (see edge case #12, unchanged)
- [ ] `Q1: Experience Level` screen — options `beginner` / `intermediate` / `master`
- [ ] `Q2: Available Time` screen — options `daily` / `weekly`
- [ ] `Q3: Safety Restrictions` screen — single-select `child_safe` / `pet_safe` / `none`
- [ ] `CTA Screen` — "Add First Plant?" with two actions: `Tap: Add First Plant` → push `add_plant` flow; `Tap: Skip / Later` → mark `has_completed_onboarding=1` and route to Home (Empty State)
- [ ] `user_repository.dart`: `saveOnboardingPrefs()` writes the 3 answers; `hasCompletedOnboarding()` gates splash routing
- [ ] Build **Unified Add Plant Flow** as its own route (`/add-plant`), reachable from: (a) onboarding CTA, (b) Home Empty State button, (c) Home FAB — same screens, same controller, only the "on complete" navigation target differs (pass a `NavigationTarget` enum into the flow)
  - **Step 1 — Select Plant Species:** search/browse via `perenual_remote_datasource.dart`, fallback per §3 edge case #4
  - **Step 2 — Environment Conditions:** Indoor/Outdoor toggle, sunlight level, pot size, window distance
  - **Step 3 — Nickname & Initial Height:** text field + numeric height (cm) input → on save, this becomes both `user_plants.initial_height_cm` AND the first `growth_logs` row (`source='initial'`)
  - **Time Capsule decision (`R`):** modal question "Create Time Capsule?" — Yes opens `TimeCapsuleModal` (photo + note + duration picker), Skip proceeds directly
  - **Confirm & Save (`T`):** single repository call persists plant + initial growth log + care schedules + (optional) time capsule in one transaction
  - **First Plant check (`U`):** if this is the user's first non-archived plant → show Reward Modal (`FIRST_PLANT` badge + streak initialized to Day 1); otherwise route straight to Home Populated State
- [ ] `plant_repository.dart`: `addPlant(...)` wraps the whole Step 1–3 + Time Capsule + reward logic in a single `Database.transaction()` so a crash mid-save never leaves an orphaned plant with no schedules

**Files to Create**
```
lib/presentation/onboarding/onboarding_controller.dart
lib/presentation/onboarding/experience_level_screen.dart
lib/presentation/onboarding/available_time_screen.dart
lib/presentation/onboarding/safety_restrictions_screen.dart
lib/presentation/onboarding/add_first_plant_cta_screen.dart
lib/presentation/add_plant/add_plant_flow_controller.dart
lib/presentation/add_plant/select_species_step.dart
lib/presentation/add_plant/environment_conditions_step.dart
lib/presentation/add_plant/nickname_height_step.dart
lib/presentation/add_plant/time_capsule_modal.dart
lib/presentation/gamification/first_reward_popup.dart
```

**Key Signatures**
```dart
enum AddPlantEntryPoint { onboarding, emptyState, fabHome }

class AddPlantFlowController extends StateNotifier<AddPlantFlowState> {
  AddPlantFlowController(this._plantRepo, this.entryPoint);
  final AddPlantEntryPoint entryPoint;

  void setSpecies(PlantCatalogModel species);
  void setEnvironment({required bool isIndoor, String? sunlight, String? potSize, String? windowDistance});
  void setNicknameAndHeight(String nickname, double? initialHeightCm);
  void setTimeCapsule({String? photoPath, String? note, DateTime? unlockAt}); // null = skipped
  Future<AddPlantResult> confirmAndSave(); // returns {plant, isFirstPlant}
}

class PlantRepository {
  Future<AddPlantResult> addPlant({
    required String userId,
    required PlantCatalogModel? species,
    required String nickname,
    required bool isIndoor,
    String? sunlightCondition,
    String? potSize,
    String? windowDistance,
    double? initialHeightCm,
    TimeCapsuleDraft? timeCapsule,
  }); // single transaction: user_plants + growth_logs(initial) + care_schedules + time_capsules?
}
```

---

### Phase 2 — Home Screen States + Daily Routine Loop (Days 7–11)

**Goal:** Home renders Empty vs Populated correctly; daily task loop reflects the new 3-task set incl. height input.

**Task Checklist**
- [ ] `home_controller.dart` — derives `HomeState` = `empty` (no active plants) or `populated` (≥1 active plant), per diagram node `H`
- [ ] Empty State screen: illustration + "+ Add Plant" CTA → `/add-plant?entry=emptyState`
- [ ] Populated State: **Plant Collection Grid** (`GridView.builder`, cover photo + nickname + level badge per card) + FAB → `/add-plant?entry=fabHome`; tap card → `/plant-details/:id`
- [ ] `core/constants/task_types.dart` — update enum: `siram`, `bersih_bersih`, `monitor_tinggi` (remove `cek_hama`)
- [ ] `care_repository.dart`:
  - `getTodaysTasks(userPlantId)` → always includes `bersih_bersih` + `monitor_tinggi`; includes `siram` only if due (unchanged branch logic, new task set)
  - `completeSimpleTask(userPlantId, taskType)` for `bersih_bersih` (tap-to-complete)
  - `completeHeightTask(userPlantId, heightCm)` → **not just a checkbox**: inserts `growth_logs` row (`source='daily_task'`), then logs `care_action_logs(task_type='monitor_tinggi')`, then calls `growth_repository.awardXp(userPlantId, 'monitor_tinggi')`
  - `completeWateringTask(userPlantId)` → logs action, resets `care_schedules.next_due_date` (unchanged from v1)
- [ ] **Daily Tasks Card** on Home — aggregate view across all active plants (per diagram, task card lives at Home level, not nested in a per-plant screen); each task row expands per-plant if the user has more than one plant due for that task
- [ ] XP award wiring: every `completeXTask` call also calls `growth_repository.awardXp(userPlantId, taskType)`:
  ```dart
  Future<void> awardXp(String userPlantId, String taskType) async {
    final xp = XpConfig.xpPerTask[taskType] ?? 0;
    // read current xp, add, recompute level via XpConfig.levelForXp, write both back
  }
  ```
- [ ] Streak evaluation (`AF`→`AG`/`AH`) — same "all tasks complete before 23:59" logic as v1, just checked against the new 3-task set instead of the old set; **keep the freeze-token check from v1** per the assumption flagged in §1.3, or explicitly cut it if product confirms the new diagram intends a hard reset with no tolerance — this is the one open decision blocking Phase 2 sign-off

**Files to Create/Modify**
```
lib/presentation/home/home_controller.dart
lib/presentation/home/home_empty_state_screen.dart
lib/presentation/home/home_populated_screen.dart
lib/presentation/home/plant_collection_grid.dart
lib/presentation/daily_routine/daily_tasks_card.dart
lib/presentation/daily_routine/monitor_tinggi_input_sheet.dart   # bottom sheet for height entry
lib/core/constants/task_types.dart   # modified
lib/data/repositories/care_repository.dart   # modified
lib/data/repositories/growth_repository.dart   # + awardXp
```

**Key Signatures**
```dart
enum HomeState { empty, populated }

class CareRepository {
  Future<List<String>> getTodaysTaskTypes(String userPlantId); // ['bersih_bersih','monitor_tinggi', if due: 'siram']
  Future<void> completeSimpleTask({required String userPlantId, required String taskType});
  Future<void> completeHeightTask({required String userPlantId, required double heightCm});
  Future<void> completeWateringTask({required String userPlantId});
  Future<bool> isAllTasksCompleteTodayForUser(String userId);
}
```

---

### Phase 3 — Plant Details Screen (Days 12–15)

**Goal:** Replace v1's Plant Profile with the richer Plant Details screen from the new diagram.

**Task Checklist**
- [ ] `presentation/plant_details/plant_details_screen.dart` — assembles all sub-widgets below
- [ ] **Stats: Level/XP display** (`AI`) — progress bar widget, `level`, `xp % XpConfig.xpPerLevel` toward next level
- [ ] **Growth Log: Height Graph + Photo Timeline** (`AJ`) — `fl_chart` `LineChart` plotting `growth_logs.height_cm` vs `logged_at` (query via new `idx_growth_plant_date` index); photo timeline reuses v1's gallery grid widget, filtered to rows where `photo_path IS NOT NULL`
- [ ] **Tasks Completed Counter** (`AK`) — `SELECT COUNT(*) FROM care_action_logs WHERE user_plant_id=?`, surfaced via `care_repository.getTaskCompletedCount(userPlantId)`
- [ ] **Status: Watering in X Days** (`AL`) — `care_schedules.next_due_date - today`, rendered as "Siram dalam X hari" / "Siram hari ini" if due
- [ ] **Time Capsule tri-state** (`AM`):
  - No capsule → `AP` "Option: Create Time Capsule" button (reuses `TimeCapsuleModal` from Phase 1, now also invokable standalone from this screen)
  - Locked → `AN` countdown "X Hari Lagi" widget
  - Unlocked → `AO` "Tap to Open" → `AQ` full-screen Reveal Modal (photo + note, unlock animation)
- [ ] `growth_repository.dart`: `getHeightSeries(userPlantId)` → `List<(DateTime, double)>` for the chart; `getTimeCapsuleState(userPlantId)` → enum `{none, locked, unlocked}`

**Files to Create**
```
lib/presentation/plant_details/plant_details_screen.dart
lib/presentation/plant_details/level_xp_bar.dart
lib/presentation/plant_details/growth_height_chart.dart
lib/presentation/plant_details/photo_timeline_grid.dart
lib/presentation/plant_details/time_capsule_status_widget.dart
lib/presentation/plant_details/time_capsule_reveal_modal.dart
```

**Key Signatures**
```dart
enum TimeCapsuleState { none, locked, unlocked }

class GrowthRepository {
  Future<List<GrowthLogModel>> getHeightSeries(String userPlantId); // sorted asc by logged_at
  Future<TimeCapsuleState> getTimeCapsuleState(String userPlantId);
  Future<void> awardXp(String userPlantId, String taskType);
}

class CareRepository {
  Future<int> getTaskCompletedCount(String userPlantId);
}
```

---

### Phase 4 — Community Forum (Days 16–19) — unchanged from v1
Carried over as-is; see original plan §Phase 4. Not pictured in the new diagram (flagged in §1.3).

---

### Phase 5 — Gamification Polish, Notifications, Weather Fallback, QA (Days 20–25)

**Task Checklist (delta from v1 Phase 5)**
- [ ] 7-tier streak color propagation — unchanged from v1, still driven by `user_streaks.current_tier`
- [ ] **New:** Level-up celebration modal (distinct from streak tier-up modal) — fires when `XpConfig.levelForXp(newXp) > oldLevel`
- [ ] `flutter_local_notifications`, weather fallback, empty states, visual QA, image compression — unchanged from v1 Phase 5
- [ ] Regression-test the Add Plant Flow from all three entry points (onboarding CTA, empty-state button, home FAB) to confirm identical behavior and correct post-save navigation per entry point

---

## 3. Edge Cases, Failure Modes & Error Handling (delta — new/changed items only; v1 items 1–14 still apply)

| # | Edge Case | Fallback / Defensive Strategy |
|---|---|---|
| 15 | **User skips onboarding CTA, never adds a plant** | Home renders Empty State indefinitely; streak/XP systems simply have nothing to evaluate (no crash, no false Tier 1→0 reset). `evaluateEndOfDay` short-circuits with "no active plants" and does not touch `user_streaks`. |
| 16 | **User backs out mid-Add-Plant-Flow (any entry point)** | Flow state lives in the `AddPlantFlowController` only (not persisted to DB) until `confirmAndSave()`. Backing out simply discards it — no partial `user_plants` row is ever written, since save is one atomic transaction (§Phase 1). |
| 17 | **Height input is invalid (negative, zero, absurd jump e.g. +500cm overnight)** | `monitor_tinggi_input_sheet.dart` validates client-side (must be `> 0`, must be `<= previous height * 3` as a sanity ceiling); on violation, show inline error, do not submit — never silently clamp or auto-correct user data. |
| 18 | **Time Capsule created inline during Add Plant Flow, then user later tries "Create Time Capsule" from Plant Details** | `getTimeCapsuleState` returns `locked`/`unlocked` (never `none`) once one exists from either origin, so the profile-level create option is simply not shown — same 1-per-plant guard as v1 edge case #9, now checked from two call sites instead of one. |
| 19 | **XP/Level desync if `care_action_logs` insert succeeds but `awardXp` write fails (e.g. app killed mid-call)** | `completeHeightTask`/`completeSimpleTask`/`completeWateringTask` wrap the log-insert + XP-update in a single `Database.transaction()` — both succeed or both roll back, never partially applied. |
| 20 | **Multiple plants due for the same task on the same day** | Daily Tasks Card groups by task type with a per-plant sub-row (per Phase 2); `isAllTasksCompleteTodayForUser` requires every active plant's every required task type logged for `todayKey()`, not just "at least one plant done." |

---

## 4. Verification & Testing Strategy (delta)

### 4.1 Manual — Happy Path (new/changed)
- [ ] Complete 3-question onboarding → tap "Skip/Later" → confirm Home renders Empty State, not a crash or blank screen
- [ ] From Empty State, tap "+ Add Plant" → complete all 3 steps + inline Time Capsule → confirm Reward Modal shows only because it's the first plant
- [ ] Add a **second** plant via Home FAB → confirm no Reward Modal (not first plant) and routes straight to Populated Home
- [ ] Complete "Monitor Tinggi Tanaman" with a height input → confirm a new `growth_logs` row appears on the Plant Details height graph immediately
- [ ] Complete all 3 daily tasks across 2 plants → confirm streak increments only after **both** plants' tasks are done, not just one
- [ ] Cross a level-up threshold → confirm Level-Up modal fires (distinct from streak tier-up modal)
- [ ] Open a Time Capsule after its unlock date → confirm Reveal Modal shows correct photo/note

### 4.2 Manual — Destructive Path (new/changed)
- [ ] Kill app mid-Add-Plant-Flow (after Step 2, before Confirm) → relaunch → confirm no orphaned/partial plant exists in DB
- [ ] Enter a wildly implausible height jump (e.g. 5cm → 500cm) → confirm validation blocks submission
- [ ] Attempt "Create Time Capsule" from Plant Details on a plant that already has one from the inline Add-Plant step → confirm option is hidden/blocked, not a silent second row

### 4.3 Automated Tests (new/changed)
```
test/core/constants/xp_config_test.dart
  - levelForXp(0) → 1, levelForXp(99) → 1, levelForXp(100) → 2 (boundary)

test/data/repositories/care_repository_test.dart (extended)
  - getTodaysTaskTypes never returns 'cek_hama'
  - completeHeightTask: inserts growth_log(source='daily_task') AND care_action_log AND awards correct XP, all-or-nothing on simulated failure

test/data/repositories/plant_repository_test.dart
  - addPlant: partial failure mid-transaction leaves zero rows across user_plants/growth_logs/care_schedules
  - addPlant: second plant for existing user does not trigger FIRST_PLANT badge

test/presentation/home/home_controller_test.dart
  - No active plants → HomeState.empty
  - ≥1 active plant → HomeState.populated
```

---

## 5. Definition of Done (v2 delta — additive to v1's DoD)

- [ ] Onboarding completes and correctly branches on Skip vs Add First Plant, with Home reflecting the right state either way
- [ ] Unified Add Plant Flow produces identical, correct results from all 3 entry points (onboarding, empty state, FAB)
- [ ] Daily task set is exactly `{Bersihkan Tanaman, Monitor Tinggi Tanaman, Siram Tanaman (conditional)}` everywhere in the app — no lingering `Cek Hama` references in code, DB, or UI copy
- [ ] Height input from the daily task correctly appears on the Plant Details growth graph without requiring app restart
- [ ] Level/XP updates are atomic with task completion (verified via §4.3 transaction test) and the Level-Up modal is visually distinct from the streak Tier-Up modal
- [ ] Time Capsule can be created from either the inline Add-Plant step or the Plant Details screen, with the 1-per-plant limit enforced regardless of origin
- [ ] Open decision from Phase 2 (streak freeze/tolerance: keep or cut) is resolved with product and reflected consistently in code + this doc before final demo build
