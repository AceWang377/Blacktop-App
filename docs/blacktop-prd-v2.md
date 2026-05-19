# Blacktop iOS App PRD v2

Last updated: May 19, 2026

## 1. Product Summary

Blacktop v2 builds on the launched v1 App Store release. The product remains a lightweight basketball court discovery app focused on practical court facts, not ratings or social networking.

The v2 goal is to make Blacktop more useful and more trustworthy without making the app feel heavy. Users should still be able to open the app, browse the map, filter courts, and view details without creating an account.

The main v2 upgrade is controlled user contribution: basketball players can help improve factual court information, while Blacktop keeps review control before changes affect public court records.

## 2. Core Promise

Know the court before you go.

## 3. V2 Positioning

Blacktop helps players quickly answer:

- Is this court worth going to?
- Is it playable for my situation today?
- What practical facts should I know before travelling?
- Can I help improve this court record if I know the place?

V2 should not become a basketball social app. It should remain a fast court utility.

## 4. Product Principles

1. Browsing stays no-login
   Users can use the map, filters, details, directions, and local saved courts without signing in.

2. Login only appears when needed
   Sign in with Apple is required only when a user wants to submit court facts or, later, submit a court photo.

3. Facts and structured signals over opinions
   V2 still avoids star ratings, vague comments, public reviews, rankings, and social feeds. If a subjective signal is useful, such as court playing intensity, it should be structured, lightweight, and aggregated.

4. Contributions become vote-backed factual signals
   User submissions should be stored as structured votes on factual labels. They should not directly overwrite public court data. The UI should show the label plus vote count so users can judge confidence themselves.

5. Trust should feel natural
   The app should avoid heavy labels like "verified" or "unverified" on main user surfaces. Instead, show transparent community signal counts, such as "Nets · 14" or "Dries fast · 8", without claiming absolute truth.

6. More useful, not more complicated
   Each v2 addition must help users decide whether to go to a court.

## 5. V2 Goals

- Add light Sign in with Apple for contribution flows.
- Let users vote on structured court fact labels.
- Give Blacktop an admin control path for spam, abuse, and base court record maintenance.
- Improve court details into a faster checklist-style decision surface.
- Add practical "Best for" tags derived from existing facts.
- Add court vibe/intensity voting so players can understand whether a court usually feels casual, mixed, or competitive.
- Encourage users to fill missing facts without exposing raw data confidence.
- Improve search and directions usefulness.
- Preserve v1 speed and simplicity.

## 6. Non-Goals

V2 should not include:

- Public comments
- Star ratings
- Player profiles
- Social feed
- Chat
- Matchmaking
- Real-time pickup game creation
- Public follower/friend systems
- Public leaderboards
- Realtime occupancy or heat bar
- Continuous location tracking

The realtime court heat bar can be reconsidered for v3 after contribution quality and moderation are stable. V2 may include non-realtime court vibe/intensity voting because it describes the usual feel of a court rather than the live number of players there.

## 7. V2 Feature Scope

### 7.0 V2 Refinement Decisions After First Device Test

After the first real-device test of the V2 foundation, the following changes are accepted into V2 scope:

1. Profile owns account entry
   Sign in with Apple should appear as a formal account section inside Profile. Contribution sheets may still show a compact sign-in prompt when needed, but Profile is the primary place for sign in, sign out, sync status, and account wording.

2. Saved courts should remain local when signed out and sync when signed in
   Signed-out users keep the v1 behaviour: saved courts stay on the device. After Sign in with Apple, local saved courts should be merged into the user's Supabase saved list. Future save/unsave actions should update both local state and Supabase.

3. Voting must show visible counts immediately
   After a user votes on court vibe or court facts, the relevant label should show a vote count. The app should not hide all results behind a threshold because that makes the action feel fake. Users can judge signal confidence from the count themselves.

4. Court facts should move from admin-approved truth to community-backed labels
   Admin users may still maintain base court records, remove abusive data, and hide suspicious votes, but most court detail improvements should be represented as structured labels with vote counts rather than admin-approved absolute facts. This avoids pretending that an admin can reliably verify every court globally.

5. Search and directions should be completed before V2 release
   Search should provide clearer feedback after city/area/postcode/court lookup, and directions should support Apple Maps, Google Maps, copy address/postcode, and copy coordinates.

### 7.1 Light Sign in with Apple

#### Purpose

Sign in exists only to make user submissions accountable enough for moderation.

#### User Rules

- No login required to browse.
- No login required to search.
- No login required to filter.
- No login required to open court details.
- No login required to save courts locally.
- Login required to submit a court fact update.
- Login may be required later to submit court photos.

#### Account Model

Use Sign in with Apple as the only public login method for v2.

Avoid email/password login in v2 because it adds support burden, password handling, and extra privacy surface.

#### Profile Data

Store only what is needed:

- Internal user id
- Apple user identifier or Supabase auth user id
- Created timestamp
- Last active timestamp, optional
- Role, such as user or admin

Do not require public usernames, avatars, bios, or profile pages.

### 7.2 User Court Fact Signals

#### Purpose

Let players improve court usefulness through structured factual label votes.

The product should not pretend that every contributed fact is admin-verified truth. For many details, such as whether the court stays dry, has nets, feels spacious, or is clean, the most honest first version is a community-backed signal with a visible count.

#### Entry Points

- Court detail page: "Know this court?"
- Missing facts prompt: "Vote on court facts"
- Profile page: lightweight contribution history, optional after v2.0

#### Submission Format

Use structured labels, not open-ended reviews.

Possible categories:

- Court type: indoor / outdoor / covered / unknown
- Access: public / limited / private / unknown
- Cost: free / paid / unknown
- Lights: yes / no / unknown
- Dry after rain: yes / no / slow to dry / unknown
- Slippery when wet: yes / no / unknown
- Surface: asphalt / concrete / rubber / wood / synthetic / unknown
- Nets: yes / no / mixed / unknown
- Rim height: standard / low / high / unknown
- Rim type: single / double / unknown
- Space: tight / normal / spacious / unknown
- Cleanliness: clean / okay / dirty / unknown
- Facilities: toilet / water / parking / changing rooms
- Opening/access note: not recommended for V2 unless admin-managed, because free text creates moderation burden

#### Display Rule

Fact votes do not directly update `courts`.

They should be stored in a fact vote table and displayed as labels with counts.

Example:

```text
Nets · 14
Dries fast · 8
Double rim · 6
Clean · 5
```

The number is part of the trust model. A label with 1 vote is useful but weak. A label with 30 votes is stronger. The app should let users interpret this rather than hiding all low-count signals.

#### Admin Role

Admin should not be required to decide whether every fact vote is true. Admin controls should focus on:

- Removing abusive or impossible votes.
- Hiding suspicious labels.
- Maintaining base court identity, coordinates, address, and duplicate cleanup.
- Manually editing `courts` only when the owner has first-hand knowledge or a reliable source.

#### Submission UX

The flow should be short:

1. User taps "Vote on court facts."
2. If not signed in, show Sign in with Apple.
3. User selects one or more fact labels.
4. User submits.
5. App confirms: "Thanks. Your vote helps other players judge this court."

Avoid long forms and avoid making the user feel they are writing a review.

### 7.3 Admin Data Stewardship

#### Purpose

Protect the product from spam, duplicates, unsafe data, and obviously abusive submissions without turning admin into the sole judge of every court fact.

#### Admin Capabilities

Admin should be able to:

- View suspicious or reported fact votes.
- Hide or reset abusive labels.
- Maintain court identity, coordinates, address, postcode, and duplicate cleanup.
- Manually edit `courts` when the admin has first-hand knowledge or a reliable external source.
- See basic submitter metadata for abuse control.

#### Implementation Preference

For v2.0, the admin stewardship tool can be:

- A hidden admin section in debug/internal builds, or
- A simple Supabase dashboard/manual SQL workflow for moderation and manual edits, or
- A lightweight web admin page later.

Do not expose admin controls in the public App Store build.

### 7.4 Court Detail Checklist Redesign

#### Purpose

Make court details faster to scan.

#### Current Problem

Court facts can feel like database fields. V2 should make them feel like a decision checklist.

#### Recommended Sections

1. Playability
   - Dry after rain
   - Slippery when wet
   - Surface type
   - Surface condition
   - Space/runoff

2. Hoop setup
   - Nets
   - Rim height
   - Rim type
   - Hoop count
   - Backboard/rim condition

3. Access
   - Indoor/outdoor
   - Free/paid
   - Public/limited/private
   - Opening hours
   - Evening access

4. Facilities
   - Lights
   - Toilets
   - Drinking water
   - Parking
   - Changing rooms

Each fact should be compact, visual, and easy to scan.

### 7.5 Best For Tags

#### Purpose

Help users interpret facts quickly.

#### Examples

- Best for solo shooting
- Good for pickup
- Good after rain
- Evening friendly
- Indoor option
- Free to play
- Bring your own water
- Not ideal after rain
- No lights
- Tight space

#### Rule

Tags should be derived from court facts, not manually written marketing copy.

Example logic:

- If `good_for_solo = yes` and space is not tight: show "Best for solo shooting."
- If lights are yes and evening access is yes: show "Evening friendly."
- If dry after rain is yes and slippery when wet is no: show "Good after rain."
- If drinking water is no or unknown: show "Bring your own water."

### 7.6 Court Vibe and Intensity Voting

#### Purpose

Help users understand the usual playing environment of a court before they arrive.

This solves a different problem from court facts. A court can have good rims and lights but still feel too competitive, too quiet, or not welcoming for a beginner. V2 should help users answer:

- Is this court beginner-friendly?
- Is it usually casual or competitive?
- Is it good for solo shooting?
- Do people usually run pickup games here?
- Is it a good place to join as a new player?

#### Product Position

This is not a rating system. It should not ask users whether a court is "good" or "bad."

It is a structured community signal about the court's usual basketball vibe.

Recommended user-facing names:

- Court vibe
- Run level
- Playing level
- Usual game

Avoid names like:

- Rating
- Score
- Skill ranking
- Player ranking

#### Voting Model

Each signed-in user can vote once per court per vote category.

Users can update their vote later. Updating replaces their previous vote instead of creating another vote.

Browsing users can see aggregated results without logging in, but voting requires Sign in with Apple.

#### V2 Vote Categories

Keep the vote lightweight. Start with two or three questions, not a long survey.

Recommended v2.0 questions:

1. Usual intensity
   - Quiet practice
   - Casual runs
   - Mixed level
   - Competitive runs
   - Not sure

2. Best suited for
   - Solo shooting
   - Beginner-friendly pickup
   - Casual 3v3
   - Full-court runs
   - Competitive pickup
   - Not sure

3. Join-in feel
   - Easy to join
   - Depends on the group
   - Usually organised groups
   - Better with friends
   - Not sure

Do not include open text in v2.0 vibe voting. Free text creates moderation and safety risk.

#### Sensitive Label Guidance

Avoid labels that can become exclusionary or hard to moderate, such as gender-specific or identity-specific tags.

Instead of "women-friendly," use broader product language when needed:

- Beginner-friendly
- Low pressure
- Easy to join
- Casual
- Usually organised groups

This keeps the product useful while reducing moderation and policy risk.

#### Aggregation Rules

Display vote labels with counts immediately.

Recommended display:

- 1+ vote: show the selected label with its count, such as "Casual runs · 1".
- 3 to 9 votes: the leading signal can use soft language, such as "Players say this is usually casual."
- 10+ votes: show stronger distribution UI, such as a segmented bar.

Example display:

```text
Court vibe
Casual runs · 12
Competitive runs · 4
Solo shooting · 3
```

For intensity, use a calm visual scale:

- Green: quiet practice
- Light green: casual
- Yellow: mixed
- Orange/red: competitive

Do not imply live occupancy. Avoid wording like "busy now" or "20 people here" unless a future realtime check-in feature exists.

#### Data Freshness

Court vibe should represent the usual feel, not a live state.

Votes can be weighted toward recent votes later, but v2.0 can start with simple aggregation.

Potential future rule:

- Votes from the last 12 months have full weight.
- Older votes have reduced weight.

#### Abuse Controls

- Require Sign in with Apple to vote.
- One vote per user per court per category.
- Allow users to change their vote.
- Rate-limit voting actions.
- Admin can hide or reset suspicious vote aggregates.
- Do not expose individual voter identity.

#### Relationship To Best For Tags

Court vibe votes can feed some "Best for" tags after enough votes exist.

Examples:

- If most votes say quiet practice: show "Good for solo shooting."
- If most votes say casual runs: show "Casual pickup."
- If most votes say competitive runs: show "Competitive pickup."
- If most votes say easy to join: show "Easy to join."

These tags can be shown with counts as soon as they receive votes. The UI should avoid overstating certainty when counts are low.

### 7.7 Missing Facts Prompt

#### Purpose

Turn incomplete data into a contribution opportunity.

#### UX Copy

Use friendly copy:

- "Know this court?"
- "Help add missing facts."
- "Seen the nets, lights, or surface?"

Avoid exposing raw internal labels like:

- unverified
- imported
- low confidence
- incomplete source record

#### Prompt Rule

Show the prompt only when useful:

- Several important facts are unknown.
- User is viewing the court detail page.
- User has not dismissed the prompt recently.

### 7.8 Admin-Only Photo Strategy

#### V2.0 Recommendation

Do not open public photo uploads immediately.

Use the existing default court illustration when no photo exists. Allow admin-added photos first.

#### Future Extension

After moderation is stable, logged-in users may submit photos for review.

Photo submissions must be reviewed before public display because they create higher App Store and moderation risk than structured fact updates.

### 7.9 Search Improvements

#### Purpose

Make it easier to find a useful court area without manually dragging the map.

#### V2 Search Targets

- City
- Area/neighbourhood
- Postcode, where available
- Court name
- Near me

#### Search Result UX

When a city or region is selected, show:

- Area name
- Approximate court count
- A map camera move to the relevant area
- A "Search this area" or automatic load when zoomed in enough

Example:

```text
Manchester · 128 courts
```

#### Data Rule

Search should remain fast with large global datasets. Use backend queries and capped viewport results rather than loading all courts.

### 7.10 Saved Filter Preferences

#### Purpose

Make repeated use faster.

#### Behaviour

Remember the user's last filter choices locally:

- Outdoor
- Indoor
- Free
- Lights
- Dry after rain
- Nets present
- Standard rim

Do not require login. Store locally on device.

#### Reset

Provide a simple way to clear filters.

### 7.11 Better Directions Actions

#### Purpose

Make going to a court easier after the user chooses one.

#### Actions

Court detail page should support:

- Open in Apple Maps
- Open in Google Maps, if installed or via web fallback
- Copy address or postcode, where available
- Copy coordinates when address is missing

#### Rule

Directions actions should not clutter the main map. Keep them inside court detail or a compact action sheet.

## 8. Data Model Draft

### 8.1 Existing Table: `courts`

Public read table for base court records.

In V2, `courts` should mainly represent stable information: identity, coordinates, address, postcode, source metadata, and admin/manual base fields. Community fact votes should not automatically overwrite this table.

Likely additions:

- `updated_at`
- `last_fact_update_at`
- `fact_completeness_score`
- `photo_url`, optional
- `postcode`, if not already present
- `address_label`, if not already present

### 8.2 New Table: `profiles`

Stores minimal authenticated user metadata.

Suggested fields:

- `id uuid primary key`
- `auth_user_id uuid unique not null`
- `role text default 'user'`
- `created_at timestamptz default now()`
- `last_seen_at timestamptz`

### 8.3 New Table: `court_fact_votes`

Stores one structured factual label vote per signed-in user, per court, per fact category.

Suggested fields:

- `id uuid primary key`
- `court_id text references courts(id)`
- `profile_id uuid references profiles(id)`
- `field_name text not null`
- `vote_value text not null`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

Recommended unique constraint:

```sql
unique (court_id, profile_id, field_name)
```

This lets a user update their fact vote while preventing duplicate votes for the same court and fact category.

### 8.4 New View Or Materialized View: `court_fact_vote_summaries`

Aggregates public fact labels without exposing individual voters.

Suggested output:

- `court_id`
- `field_name`
- `vote_value`
- `vote_count`
- `field_total`
- `percentage`
- `updated_at`

Display rule:

- Show labels with counts from 1 vote onward.
- Avoid claiming the label is verified.
- Sort labels by vote count, then by recent activity.

### 8.5 New Table: `admin_actions`

Audit trail for moderation decisions.

Suggested fields:

- `id uuid primary key`
- `admin_profile_id uuid references profiles(id)`
- `action_type text`
- `target_table text`
- `target_id text`
- `created_at timestamptz default now()`
- `metadata jsonb`

### 8.6 New Table: `court_vibe_votes`

Stores one structured vibe/intensity vote per signed-in user, per court, per category.

Suggested fields:

- `id uuid primary key`
- `court_id text references courts(id)`
- `profile_id uuid references profiles(id)`
- `category text not null`
- `vote_value text not null`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

Recommended unique constraint:

```sql
unique (court_id, profile_id, category)
```

This allows a user to change their vote while preventing duplicate votes for the same court and category.

### 8.7 New View Or Materialized View: `court_vibe_summaries`

Aggregates public court vibe results without exposing individual voters.

Suggested output:

- `court_id`
- `category`
- `vote_count`
- `leading_vote_value`
- `leading_vote_count`
- `distribution jsonb`
- `updated_at`

Display rules should be applied in the app or view:

- 1+ vote: show the label with its count.
- 3+ votes: show soft leading-signal copy if useful.
- 10+ votes: show richer distribution UI.

### 8.8 Future Table: `court_photo_submissions`

Not required for v2.0 unless user photo review is included.

## 9. Supabase Security Requirements

### Public Users

- Can read base court records.
- Cannot update `courts` directly.
- Cannot read private moderation tables unless explicitly allowed.

### Authenticated Users

- Can insert or update their own `court_fact_votes`.
- Can read their own fact votes, optional.
- Can insert or update their own `court_vibe_votes`.
- Cannot insert more than one fact vote per court/field because of the unique constraint.
- Cannot insert more than one vote per court/category because of the unique constraint.
- Cannot edit another user's votes.
- Cannot read individual vote rows from other users.

### Admin Users

- Can hide or reset suspicious vote labels.
- Can maintain base court records, duplicate cleanup, coordinates, and address data.
- Can manually update public court facts only when there is first-hand knowledge or a reliable source.

### RLS Principle

All write paths must be protected by Row Level Security.

The public app must never include a Supabase service role key.

## 10. Privacy and App Store Impact

### App Privacy Changes

V2 will introduce account/auth data if Sign in with Apple is implemented.

App Store privacy answers may need to disclose:

- User ID, if used for account authentication
- User-generated content or submitted data, if Apple classifies court fact updates as user content
- Structured gameplay/vibe votes, if Apple classifies them as user-generated content
- Approximate/precise location only if still used for map centering and not stored

### Important Privacy Rules

- Do not store continuous user location.
- Do not infer real-time court attendance.
- Do not imply court vibe votes are live occupancy.
- Do not show public user profiles in v2.
- Do not expose user email in app UI.
- Make it clear that community labels are vote-backed signals, not guaranteed verification.

## 11. UX Changes By Screen

### Map

- Keep map-first experience.
- Do not show contribution prompts on the main map.
- Keep saved pins visually distinct.
- Continue capped viewport loading for performance.

### Court Detail

- Add checklist-style sections.
- Add derived "Best for" tags.
- Add court vibe/intensity labels with vote counts.
- Add lightweight vibe voting entry for signed-in users.
- Add "Know this court?" prompt when important facts are missing.
- Add directions action sheet.
- Add update freshness copy such as "Updated this month."

### Court Vibe Voting

- Show as a compact module inside court detail, not on the main map.
- Let users vote or update their vote after signing in.
- Use structured choices only.
- Do not show individual voters.
- Show vote labels with counts immediately; avoid strong recommendation copy until enough votes exist.

### Fact Signal Flow

- Lightweight structured form.
- Sign in with Apple only when submitting.
- Confirmation after voting.
- Show the selected label with a count so the action feels real.

### Profile

- Keep lightweight.
- Own the Sign in with Apple entry and sign-out state.
- Keep saved courts local when signed out; sync them when signed in.
- Keep Data Sources, Terms, Privacy, and Support here.

### Admin

- Keep hidden from production user UI.
- Focus on abuse control, duplicate cleanup, and base record maintenance rather than judging every fact vote.

## 12. Rollout Plan

### Phase 1: Foundation

- Add Sign in with Apple and Supabase auth.
- Add profiles table.
- Add `court_fact_votes` table with RLS.
- Add fact vote API path from app to Supabase.
- Keep all public browsing unchanged.

### Phase 2: Contribution UX

- Add "Know this court?" prompt.
- Add structured fact voting form.
- Add vote confirmation state.
- Add basic contribution history only if it stays lightweight.

### Phase 3: Court Vibe Voting

- Add `court_vibe_votes` table with RLS.
- Add one-vote-per-user-per-court/category constraint.
- Add aggregate `court_vibe_summaries`.
- Add court detail vibe summary module.
- Add signed-in vote/update flow.

### Phase 4: Admin Stewardship

- Create admin moderation workflow for suspicious votes.
- Allow admins to hide/reset abusive fact or vibe labels.
- Keep manual `courts` edits for base data and reliable first-hand checks.

### Phase 5: Detail Utility Upgrade

- Redesign court detail into checklist sections.
- Add derived "Best for" tags.
- Feed eligible court vibe results into "Best for" tags.
- Add update freshness copy.

### Phase 6: Search and Directions Improvements

- Improve city/postcode/court search.
- Add court count on search result areas.
- Remember filter preferences locally.
- Add Google Maps and copy address actions.

## 13. Success Metrics

### Product Metrics

- Court detail open rate
- Filter usage rate
- Directions tap rate
- Saved court rate
- Contribution prompt tap rate
- Fact label vote rate
- Fact labels with 3+ votes
- Court vibe voting rate
- Court vibe vote update rate

### Quality Metrics

- Percentage of courts with fact labels voted on
- Percentage of key fact categories with 3+ votes
- Hidden/reset suspicious vote rate
- Duplicate/spam report rate
- Courts with 3+ vibe votes
- Courts with 10+ vibe votes
- App launch-to-map-ready time
- Viewport court load latency

## 14. Risks

### Moderation Load

Even structured votes create abuse-control work. Start with label voting and avoid public photos in v2.0.

### Privacy Expansion

Login changes App Store privacy answers. Keep auth minimal and avoid unnecessary user profile fields.

### Data Trust

If labels are presented as verified truth, users may over-trust weak signals. Always show vote counts and avoid absolute wording when counts are low.

### Product Complexity

Do not let contribution features dominate the app. The primary experience is still finding courts.

### Subjective Signal Risk

Court vibe voting is more subjective than physical court facts. Keep it structured, aggregate-only, and count-based. Do not allow public free-text vibe comments in v2.0.

## 15. Recommended V2.0 Scope

Build these first:

1. Sign in with Apple for contributors only.
2. Structured court fact label voting.
3. Supabase fact vote tables/views and RLS.
4. Admin stewardship tools for abuse control and base data maintenance.
5. Court detail checklist redesign.
6. Court vibe/intensity voting with one vote per user per court/category.
7. Best for tags.
8. Missing facts prompt.
9. Saved filter preferences.
10. Better directions actions.

Defer:

- Heat bar / realtime occupancy
- Public photo submissions
- Comments
- Ratings
- Social features
- Public profiles
