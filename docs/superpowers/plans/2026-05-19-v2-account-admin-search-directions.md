# Blacktop V2 Account, Admin, Search, and Directions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the first V2 community foundation into a product-feeling release: account state lives in Profile, saved courts can sync to a signed-in account, user votes visibly update, admins can approve factual updates into `courts`, and map search/directions become more useful.

**Architecture:** Keep no-login browsing as the default. Use Supabase Auth only for account-backed features, store public court data in `courts`, store user-owned state in separate RLS-protected tables, and expose admin review through a hidden/admin-only app surface plus SQL-backed approval RPCs. Avoid public comments, public profiles, social feeds, and realtime occupancy.

**Tech Stack:** SwiftUI, MapKit, AuthenticationServices, Supabase REST/RPC, PostgreSQL RLS, Sign in with Apple, Keychain.

---

## Product Analysis and Decisions

### 1. Sign in belongs in Profile

This is reasonable and should be changed. Profile is the expected place for account identity, sign out, sync status, and account-related privacy explanation.

Recommended behaviour:
- Map/details remain browseable without login.
- Profile shows signed-out state with a single "Sign in with Apple" card.
- Contribution flows still show a compact sign-in prompt when needed, but they should reuse the same account session.
- Signed-in Profile shows email/private relay label, sync status, and sign out.

### 2. Saved courts should sync after sign in

This is reasonable, but must preserve the V1 local saved experience.

Recommended behaviour:
- Signed-out users keep local saved courts in `UserDefaults`.
- When the user signs in, upload local saved court ids to Supabase.
- Then fetch remote saved courts and merge them with local saved courts.
- After sign-in, save/unsave should update both local state and Supabase.
- On sign-out, keep the current saved list locally unless user explicitly clears it.

This avoids surprising data loss and keeps offline/local behaviour simple.

### 3. Vibe voting needs visible personal feedback

Current behaviour can feel fake because aggregated results are hidden until at least 3 votes exist. That threshold is correct for public aggregate trust, but the user needs immediate confirmation.

Recommended behaviour:
- After voting, show "Your vote: Casual runs" immediately.
- Public aggregate still appears only after threshold.
- If aggregate is below threshold, show "Not enough player votes yet" plus user's own vote if signed in.
- Users can revisit and change their vote.

### 4. Admin approval should write into `courts`

This is reasonable for admin accounts only. Normal users should never write directly to `courts`.

Recommended behaviour:
- User submissions go to `court_fact_updates`.
- Admin sees pending submissions.
- Admin approves one field at a time.
- Approval runs a Supabase RPC that updates the exact column in `courts`, marks the submission approved, and records an audit row.
- Admin rejection only updates submission status.

This prevents the app from becoming complex while making the workflow real.

### 5. Search and directions should be completed before V2 release

Search already has auto viewport loading, country pins, and geocoding, but V2 should make search results feel explicit and reliable.

Recommended behaviour:
- Search city/area/postcode/court name.
- Use local loaded results first, then MapKit geocode, then Supabase viewport load.
- Show a lightweight result summary after search: `Manchester · courts nearby`.
- Directions should offer Apple Maps, Google Maps, copy address/postcode, and copy coordinates inside court details.

---

## File Structure

### Swift app files

- Modify: `Blacktop/Models/AppStore.swift`
  - Own account session, saved sync lifecycle, personal vibe votes, admin review actions.
- Modify: `Blacktop/Data/SupabaseCommunityService.swift`
  - Add saved courts endpoints, personal vote fetching, pending fact updates, approve/reject RPC calls.
- Modify: `Blacktop/Models/CommunityModels.swift`
  - Add saved court DTOs, pending update DTOs, admin role helpers, personal vote model.
- Modify: `Blacktop/Views/ProfileView.swift`
  - Add Profile sign-in/sign-out card and saved sync status.
- Modify: `Blacktop/Views/CommunityContributionViews.swift`
  - Reuse Profile account state, show personal vote after submit.
- Modify: `Blacktop/Views/CourtDetailView.swift`
  - Show user's vote separately from aggregate; replace single directions button with action sheet.
- Modify: `Blacktop/Views/CourtMapView.swift`
  - Improve search summary and selected-result handling.
- Create: `Blacktop/Views/AdminReviewView.swift`
  - Admin-only pending submission review list and approve/reject screen.

### Supabase files

- Modify: `supabase/v2_community_features.sql`
  - Add `saved_courts`, `admin_actions`, personal vote select policies, approval/rejection RPCs.
- Create: `docs/v2-community-admin-workflow.md`
  - Explain how to enable admin role and review submissions.

---

## Task 1: Move Account Entry to Profile

**Files:**
- Modify: `Blacktop/Views/ProfileView.swift`
- Modify: `Blacktop/Views/CommunityContributionViews.swift`
- Modify: `Blacktop/Models/AppStore.swift`

- [ ] **Step 1: Add a Profile account section**

Add a `profileAccountSection` above `quickStats` in `ProfileView`.

Expected UI:
- Signed out: title `Account`, subtitle `Sign in only when you want to contribute or sync saved courts.`, Apple button.
- Signed in: title `Signed in with Apple`, email/private relay, `Sign out` button.

- [ ] **Step 2: Keep contribution sheets compact**

In `CommunityContributionViews.swift`, replace the full `CommunitySignInPanel` copy with shorter wording:

```swift
Text(store.localized("Use your Blacktop account to submit this.", "使用你的 Blacktop 账号提交。"))
```

If signed out, it still shows the Apple sign-in button, but the main account explanation lives in Profile.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project Blacktop.xcodeproj -scheme Blacktop -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/BlacktopV2Build CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
git add Blacktop/Views/ProfileView.swift Blacktop/Views/CommunityContributionViews.swift Blacktop/Models/AppStore.swift
git commit -m "Move V2 account controls to Profile"
```

---

## Task 2: Sync Saved Courts to Supabase

**Files:**
- Modify: `supabase/v2_community_features.sql`
- Modify: `Blacktop/Data/SupabaseCommunityService.swift`
- Modify: `Blacktop/Models/AppStore.swift`
- Modify: `Blacktop/Views/ProfileView.swift`

- [ ] **Step 1: Add saved courts table**

Add to `supabase/v2_community_features.sql`:

```sql
create table if not exists public.saved_courts (
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    court_id text not null references public.courts(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, court_id)
);

alter table public.saved_courts enable row level security;

drop policy if exists "Users can read own saved courts" on public.saved_courts;
create policy "Users can read own saved courts"
on public.saved_courts
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own saved courts" on public.saved_courts;
create policy "Users can insert own saved courts"
on public.saved_courts
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own saved courts" on public.saved_courts;
create policy "Users can delete own saved courts"
on public.saved_courts
for delete
to authenticated
using (auth.uid() = user_id);

grant select, insert, delete on public.saved_courts to authenticated;
```

- [ ] **Step 2: Add service methods**

Add to `SupabaseCommunityService`:
- `fetchSavedCourtIDs(session:) async throws -> Set<String>`
- `saveCourt(courtID:session:) async throws`
- `removeSavedCourt(courtID:session:) async throws`
- `syncSavedCourtIDs(_:session:) async throws -> Set<String>`

Use `/rest/v1/saved_courts` with the authenticated bearer token.

- [ ] **Step 3: Update AppStore save behaviour**

Change `toggleSaved(_:)`:
- Always update local `savedCourtIDs`.
- If signed in, call service async to save/remove remote.
- If remote fails, keep local state and set a light `communityMessage`.

Add `syncSavedCourtsAfterSignIn()` after successful sign-in:
- POST local saved ids.
- Fetch remote saved ids.
- Merge and persist locally.

- [ ] **Step 4: Profile shows sync status**

In Profile, show:
- Signed out: `Saved courts stay on this device.`
- Signed in: `Saved courts sync with your Blacktop account.`

- [ ] **Step 5: Build and commit**

Run the simulator build. Commit:

```bash
git add supabase/v2_community_features.sql Blacktop/Data/SupabaseCommunityService.swift Blacktop/Models/AppStore.swift Blacktop/Views/ProfileView.swift
git commit -m "Sync saved courts for signed-in users"
```

---

## Task 3: Show Personal Vibe Votes Immediately

**Files:**
- Modify: `supabase/v2_community_features.sql`
- Modify: `Blacktop/Data/SupabaseCommunityService.swift`
- Modify: `Blacktop/Models/CommunityModels.swift`
- Modify: `Blacktop/Models/AppStore.swift`
- Modify: `Blacktop/Views/CourtDetailView.swift`
- Modify: `Blacktop/Views/CommunityContributionViews.swift`

- [ ] **Step 1: Allow users to read own vibe votes**

Confirm `court_vibe_votes` has a select policy for own rows. It currently should. Keep:

```sql
using (auth.uid() = user_id or public.is_blacktop_admin())
```

- [ ] **Step 2: Add personal vote model**

Add:

```swift
struct CourtVibeUserVote: Identifiable, Hashable, Decodable {
    var courtID: String
    var category: CourtVibeCategory
    var option: CourtVibeOption
    var id: String { "\(courtID)-\(category.rawValue)" }
}
```

- [ ] **Step 3: Fetch personal votes**

Add `fetchUserVibeVotes(courtID:session:)` to `SupabaseCommunityService`.

Endpoint:

```text
/rest/v1/court_vibe_votes?select=court_id,category,option&court_id=eq.{courtID}
```

Authorization: user access token.

- [ ] **Step 4: Store personal votes in AppStore**

Add:

```swift
@Published var userVibeVotesByCourtID: [String: [CourtVibeUserVote]] = [:]
```

After sign-in and after vote submission, load personal votes for the selected court.

- [ ] **Step 5: Court details display both aggregate and personal state**

Rules:
- If aggregate exists: show aggregate.
- If aggregate is below threshold and signed-in user voted: show `Your vote: ...`.
- If no aggregate and no user vote: show `Waiting for player votes`.

- [ ] **Step 6: Build and commit**

Run build. Commit:

```bash
git add supabase/v2_community_features.sql Blacktop/Data/SupabaseCommunityService.swift Blacktop/Models/CommunityModels.swift Blacktop/Models/AppStore.swift Blacktop/Views/CourtDetailView.swift Blacktop/Views/CommunityContributionViews.swift
git commit -m "Show personal court vibe votes"
```

---

## Task 4: Admin Review Writes Approved Facts to Courts

**Files:**
- Modify: `supabase/v2_community_features.sql`
- Create: `Blacktop/Views/AdminReviewView.swift`
- Modify: `Blacktop/Data/SupabaseCommunityService.swift`
- Modify: `Blacktop/Models/CommunityModels.swift`
- Modify: `Blacktop/Views/ProfileView.swift`

- [ ] **Step 1: Add admin actions table**

Add:

```sql
create table if not exists public.admin_actions (
    id uuid primary key default gen_random_uuid(),
    admin_user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    action_type text not null,
    target_table text not null,
    target_id text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

alter table public.admin_actions enable row level security;

drop policy if exists "Admins can read admin actions" on public.admin_actions;
create policy "Admins can read admin actions"
on public.admin_actions
for select
to authenticated
using (public.is_blacktop_admin());

drop policy if exists "Admins can insert admin actions" on public.admin_actions;
create policy "Admins can insert admin actions"
on public.admin_actions
for insert
to authenticated
with check (public.is_blacktop_admin());

grant select, insert on public.admin_actions to authenticated;
```

- [ ] **Step 2: Add approval RPC**

Add `approve_court_fact_update(update_id uuid)` as `security definer`.

RPC behaviour:
- Verify `public.is_blacktop_admin()`.
- Read pending update.
- Map `field_key` to allowed `courts` column only.
- Execute dynamic SQL with `format('%I', column_name)` for safe column name.
- Update `court_fact_updates.status = 'approved'`.
- Insert `admin_actions`.

Allowed fields are exactly:

```text
dryness_after_rain, has_nets, has_lights, rim_height, rim_type, court_space, court_cleanliness, price_type, court_type, has_toilets, has_drinking_water, has_parking
```

- [ ] **Step 3: Add rejection RPC**

Add `reject_court_fact_update(update_id uuid)`.

RPC behaviour:
- Verify admin.
- Set status rejected.
- Insert admin action.

- [ ] **Step 4: Add admin service methods**

Add:
- `fetchPendingFactUpdates(session:)`
- `approveFactUpdate(id:session:)`
- `rejectFactUpdate(id:session:)`

- [ ] **Step 5: Add AdminReviewView**

Hidden owner/admin screen should show:
- Court id/name if available.
- Field key.
- Suggested value.
- Approve button.
- Reject button.

Use this view from the existing debug owner tools first. Do not expose in public navigation.

- [ ] **Step 6: Build and commit**

Run build. Commit:

```bash
git add supabase/v2_community_features.sql Blacktop/Views/AdminReviewView.swift Blacktop/Data/SupabaseCommunityService.swift Blacktop/Models/CommunityModels.swift Blacktop/Views/ProfileView.swift
git commit -m "Add admin review for court fact updates"
```

---

## Task 5: Complete Directions Actions

**Files:**
- Modify: `Blacktop/Views/CourtDetailView.swift`

- [ ] **Step 1: Replace bottom directions button with action sheet**

Use `confirmationDialog` with:
- `Open in Apple Maps`
- `Open in Google Maps`
- `Copy address`
- `Copy coordinates`

- [ ] **Step 2: Implement Google Maps fallback**

Open:

```text
comgooglemaps://?daddr={lat},{lng}&directionsmode=walking
```

If unavailable, open:

```text
https://www.google.com/maps/dir/?api=1&destination={lat},{lng}&travelmode=walking
```

- [ ] **Step 3: Copy address behaviour**

If `court.addressLine` or `court.postcode` exists, copy:

```text
{court.name}
{addressLine}
{postcode}
```

Otherwise copy:

```text
{latitude}, {longitude}
```

- [ ] **Step 4: Build and commit**

Run build. Commit:

```bash
git add Blacktop/Views/CourtDetailView.swift
git commit -m "Add full directions actions"
```

---

## Task 6: Improve Search Feedback

**Files:**
- Modify: `Blacktop/Views/CourtMapView.swift`
- Modify: `Blacktop/Models/AppStore.swift` if status text needs shared state.

- [ ] **Step 1: Add search result state**

In `CourtMapView` add:

```swift
@State private var searchResultMessage: String?
```

- [ ] **Step 2: Set message after search**

After a city/geocode/court search loads, set:

```swift
searchResultMessage = "\(displayName) · \(areaCourtCount) courts nearby"
```

Use Chinese equivalent through `store.localized`.

- [ ] **Step 3: Show compact pill below search**

Show a black translucent pill below the search bar. It should dismiss when:
- user clears search,
- user moves map significantly,
- user taps a court.

- [ ] **Step 4: Keep backend loading capped**

Do not increase viewport limit. Keep the existing 600-700 cap and country summary pins.

- [ ] **Step 5: Build and commit**

Run build. Commit:

```bash
git add Blacktop/Views/CourtMapView.swift Blacktop/Models/AppStore.swift
git commit -m "Improve map search feedback"
```

---

## Task 7: Documentation and Supabase Setup Guide

**Files:**
- Create: `docs/v2-community-admin-workflow.md`
- Modify: `docs/blacktop-prd-v2.md`

- [ ] **Step 1: Document Supabase setup**

Document:
- Run `supabase/v2_community_features.sql`.
- Enable Apple provider.
- Make an admin user:

```sql
insert into public.blacktop_profiles (user_id, role)
values ('AUTH_USER_UUID_HERE', 'admin')
on conflict (user_id)
do update set role = 'admin';
```

- [ ] **Step 2: Update PRD**

Add a V2 refinement section:
- Profile owns sign-in.
- Saved courts sync only after sign-in.
- Public vibe aggregate threshold remains 3 votes.
- User's own vote is shown immediately.
- Admin approval writes approved facts into `courts`.

- [ ] **Step 3: Commit**

```bash
git add docs/v2-community-admin-workflow.md docs/blacktop-prd-v2.md
git commit -m "Document V2 community workflow"
```

---

## Self-Review

### Spec coverage

- Profile sign-in: covered by Task 1.
- Saved courts synced to account: covered by Task 2.
- Voting no longer feels fake: covered by Task 3.
- Admin direct write to `courts`: covered by Task 4.
- Search improvements: covered by Task 6.
- Full directions actions: covered by Task 5.
- Documentation before development: covered by this plan and Task 7.

### Risk notes

- Apple Sign in with Supabase must be tested on a real device after Task 1 and Task 2.
- Supabase RPC approval must be tested with a real admin user before shipping.
- Saved court syncing should be idempotent to avoid duplicate rows.
- Vibe aggregate threshold should stay at 3 to avoid exposing misleading one-person results.

### Execution recommendation

Implement in the task order above. Task 1 and Task 3 are product polish. Task 2 and Task 4 require Supabase SQL execution. Task 5 and Task 6 can ship independently if backend setup takes longer.
