# Blacktop V2 Marketing Plan

Last updated: May 20, 2026

## Goal

V2 should make Blacktop easier to discover in App Store search and easier to understand from the first three screenshots. The product promise should be simple:

> Find basketball courts, filter useful court facts, and save your regular spots.

## Saved Courts Privacy Check

Saved courts are personal account data when the user is signed in.

- Table: `public.saved_courts`
- Primary key: `(user_id, court_id)`
- `user_id` defaults to `auth.uid()`
- RLS is enabled on `public.saved_courts`
- Select policy: `auth.uid() = user_id`
- Insert policy: `auth.uid() = user_id`
- Delete policy: `auth.uid() = user_id`
- The app calls `/rest/v1/saved_courts` using the signed-in user's Supabase access token.

This means User A cannot read, insert, or delete User B's saved courts through the app client. A court can be saved by many users, but each saved row belongs to one Supabase Auth user.

Local behaviour:

- Before login, saved courts are kept in local `UserDefaults`.
- After Sign in with Apple, local saved courts are merged into that user's Supabase `saved_courts`.
- On another device, the user must sign in with the same Apple account to retrieve synced saved courts.

## App Store Name And Subtitle

Keep app name:

`Blacktop`

Recommended subtitle:

`Basketball court finder`

Reason: the app name alone is hard to search because "blacktop" can mean asphalt, schoolyard, or outdoor sport generally. The subtitle should carry the strongest literal search phrase: basketball court finder.

Alternatives:

- `Find basketball courts`
- `Pickup court map`
- `Outdoor basketball map`

Use only one. Do not stuff the subtitle with repeated keywords.

## Keyword Field

Recommended 100-character keyword field:

`basketball,courts,pickup,hoops,map,outdoor,indoor,nets,lights,playground,sports`

Notes:

- Avoid repeating words already in the app name and subtitle unless needed.
- Prefer direct search intent over branding: basketball, courts, pickup, hoops, map.
- Remove weak/legal keywords such as `openstreetmap`; users are unlikely to search that for this app.
- Region keywords such as `uk` can be rotated later if analytics show strong local demand.

## Promotional Text

`Find basketball courts, filter by useful court facts, and save your regular spots.`

## Description

Blacktop helps you find basketball courts and check the details before you leave.

Find nearby courts on a clean map, filter by practical court details, and open quick directions when you are ready to go. Browsing stays account-free, while Sign in with Apple lets players sync saved courts and vote on court facts.

Blacktop focuses on the details players actually need: indoor or outdoor, lights, nets, dry surface, rim height, space, cleanliness, facilities, and court vibe. Community vote counts help show which details have more player signal without turning the app into a ratings feed.

Blacktop is built for quick basketball decisions:

- Browse the court map without logging in
- Search courts or areas
- Filter by outdoor, indoor, free, lights, dry surface, nets, and standard rim
- Save courts and sync them with Sign in with Apple
- Vote on practical court facts and court vibe
- Open walking directions in Apple Maps
- Review data source information from Profile

No star ratings. No noisy social feed. Just basketball courts, practical facts, saved places, and player-backed signals.

## Screenshot Strategy

App Store search results often show only the first three screenshots. The first three should read clearly even when small.

Use this order:

1. `Find courts near you`
2. `Filter by court facts`
3. `Know before you go`
4. `Court details in one place`
5. `Save your favorite courts`

Generated files:

- iPhone: `docs/app-store/screenshots/marketing/iphone-6-9/`
- iPad: `docs/app-store/screenshots/marketing/ipad-13/`

Regenerate them with:

```bash
swift scripts/generate_marketing_screenshots.swift
```

Important: these marketing screenshots should be regenerated from fresh V2 simulator screenshots before final upload, especially screenshots that show voting. The current generated set is a style draft based on the existing screenshot files.

## Search Position Strategy

Blacktop will probably not rank highly for the exact app name immediately because the word is broad. Improve discovery by:

- Using the literal subtitle `Basketball court finder`.
- Putting high-intent terms in the keyword field.
- Making screenshots explain the use case without requiring users to know the brand.
- Asking early users to search for `Blacktop basketball court finder` rather than just `Blacktop`.
- Adding a short launch post/social page that repeats the phrase "Blacktop basketball court finder".
- After release, checking App Store Connect analytics for impressions, product page views, conversion rate, and keyword-driven installs.

## What Not To Claim Yet

Avoid these until they are fully built and stable:

- Real-time pickup game availability
- Live occupancy
- Verified court facts
- Public profiles
- Chat or meetup coordination
- Admin-reviewed submissions

## App Privacy Reminder For V2

Because V2 adds Sign in with Apple and synced saved courts, the App Privacy answers should be updated from V1:

- Tracking: No
- Account identifier: collected for app functionality
- Email address: may be collected for account display if Apple provides it
- User content: court fact votes and vibe votes, used for app functionality
- Saved courts: user-specific saved court IDs, used for app functionality
- Location: used to center the map while the app is open; not stored by Blacktop

