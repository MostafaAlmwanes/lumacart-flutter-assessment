# LumaCart UX Plan

## Navigation map

```text
Splash
 ├─ unauthenticated → Sign in ↔ Sign up
 └─ authenticated → Main shell
                      ├─ Home → Product details
                      ├─ Cart
                      ├─ Saved carts → Saved cart details
                      └─ Profile → Logout → Sign in
```

The shell uses bottom navigation with Home, Cart, Saved Carts, and Profile. Product details is pushed above the shell so the user can return to the same catalog state.

## Session flow

1. Splash initializes secure storage and Hive before rendering app content.
2. `AuthBloc` restores the secure session envelope.
3. The persisted safe session profile is loaded and validated.
4. Valid sessions route to the shell; invalid or corrupt sessions are cleared and route to sign-in.
5. Logout deletes only active secure-session values. Current and saved carts remain persisted.

## Authentication flow

### Sign in

- Fields: username, password.
- Local account lookup occurs first. A matching username is verified with PBKDF2.
- If no local account matches, the app calls `POST /auth/login`.
- On success, `/users` is fetched and username matched to resolve profile data.
- Demo hint: `mor_2314 / 83r5^_` appears in a low-emphasis expandable/tonal panel.
- Errors remain near the form and keep entered username.

### Sign up

- Fields: first name, last name, email, username, phone, city, street, street number, ZIP/postal code, password, confirm password.
- Duplicate email and username are checked case-insensitively against local accounts.
- `POST /users` is attempted with the form payload.
- The app stores a salted PBKDF2 hash plus the profile, starts a local session, and routes to Home.
- The UI never claims the account was permanently created on the remote service.

## Main navigation behavior

- The bottom bar remains visible for the four root destinations.
- Selecting the current destination preserves scroll/search state.
- Cart badge animates when item count changes.
- Back from a root destination exits according to platform behavior; back from details returns to the previous shell tab.

## Product flow

1. Home loads cached products immediately when available, then refreshes remotely.
2. Category chips and the search query combine in `ProductsBloc`.
3. Search input is debounced by 350 ms.
4. Pull-to-refresh triggers a non-destructive refresh.
5. Product card opens details with a shared Hero tag.
6. Details lets the user choose quantity and add to cart.
7. A SnackBar confirms quantity added and offers “View cart.”

## Cart flow

1. Cart loads from local storage through `CartBloc`.
2. Increment/decrement actions persist immediately.
3. Decrement stops at quantity one; explicit removal offers undo.
4. Summary displays unique lines, total item quantity, subtotal, and total.
5. Save opens a sheet with an optional editable name prefilled from date/time.
6. Empty carts cannot be saved.
7. Clear requires confirmation.

## Saved carts flow

1. Saved snapshots load newest first.
2. Cards show name, saved date, total quantity, and total.
3. Tapping opens details.
4. Restore prompts for Replace or Merge when the active cart is non-empty; otherwise it restores directly after confirmation.
5. Delete requires confirmation.
6. Optional remote API history, when implemented, appears below a clearly titled “Previous online carts” section and never mixes with local snapshots.

## Profile flow

- Header: avatar placeholder, full name, username.
- Information tiles: email, phone, address.
- Logout appears as a destructive outlined action near the bottom.
- Account origin is not surfaced in normal UI.

## Screen specifications and wireframes

### Splash

**Purpose:** Restore local services and authentication without flashing the wrong route.

**Sections/components:** Brand mark/icon, indeterminate progress, optional recovery message.

**States:** Loading only; failure falls back to sign-in after clearing invalid session data.

**Accessibility:** Brand image decorative; progress has semantic “Restoring session.”

```text
┌────────────────────────────┐
│                            │
│          [bag icon]        │
│          LumaCart          │
│       [progress line]      │
│                            │
└────────────────────────────┘
```

### Sign in

**Purpose:** Authenticate remote or local users.

**Main sections:** Welcome header, form, submit button, sign-up link, demo hint.

**Loading:** Button spinner; fields stay visible.

**Empty:** Not applicable.

**Error:** Inline banner plus field-specific validation.

**Primary action:** Sign in.

**Secondary action:** Create account.

```text
┌────────────────────────────┐
│ [brand]                    │
│ Welcome back               │
│ Sign in to continue        │
│                            │
│ Username                   │
│ [________________________] │
│ Password             [eye] │
│ [________________________] │
│                            │
│ [        Sign in         ] │
│ Create an account          │
│ ▸ Demo account             │
└────────────────────────────┘
```

### Sign up

**Purpose:** Create a durable local account while demonstrating API registration.

**Sections:** Identity, contact, address, password, submit.

**Loading:** Submit button state.

**Error:** Near-field validation; top banner for remote/local persistence failure.

**Primary action:** Create account.

**Secondary action:** Back to sign in.

```text
┌────────────────────────────┐
│ ← Create account           │
│ First name  Last name      │
│ [________]  [________]     │
│ Email                      │
│ [________________________] │
│ Username                   │
│ [________________________] │
│ Phone                      │
│ [________________________] │
│ Address fields...          │
│ Password             [eye] │
│ Confirm password     [eye] │
│ [    Create account      ] │
└────────────────────────────┘
```

### Home

**Purpose:** Discover and filter products.

**Sections:** App bar/cart badge, search, category chips, status banner, product grid.

**Loading:** Skeleton grid.

**Empty:** No-results panel with clear filters action.

**Error:** Retry panel; cached data remains visible when possible.

**Primary action:** Open product.

**Secondary action:** Refresh/clear filters.

```text
┌────────────────────────────┐
│ LumaCart              🛒 3 │
│ [ Search products...    ×] │
│ [All] [Electronics] [...]  │
│ (Offline: showing cache)   │
│ ┌──────────┐ ┌──────────┐ │
│ │  image   │ │  image   │ │
│ │category  │ │category  │ │
│ │title...  │ │title...  │ │
│ │★ 4.2     │ │★ 3.9     │ │
│ │$109.95   │ │$22.30    │ │
│ └──────────┘ └──────────┘ │
│ Home Cart Saved Profile    │
└────────────────────────────┘
```

### Product details

**Purpose:** Evaluate one product and add a chosen quantity.

**Sections:** Hero image, category, title, rating, price, description, stepper, sticky add button.

**Loading:** Details skeleton when opened by deep link without cached model.

**Error:** Retry or back.

**Primary action:** Add to cart.

```text
┌────────────────────────────┐
│ ← Product                  │
│ ┌────────────────────────┐ │
│ │       large image      │ │
│ └────────────────────────┘ │
│ CATEGORY                   │
│ Product title wraps        │
│ ★ 4.3 (120)      $109.95  │
│ Description...             │
│ Quantity   [−]  2  [+]     │
│ [       Add to cart      ] │
└────────────────────────────┘
```

### Cart

**Purpose:** Edit the active cart and save a snapshot.

**Sections:** Lines, undo feedback, summary, save/clear actions.

**Loading:** Short progress while restoring persisted cart.

**Empty:** Empty-cart panel with Browse products action.

**Error:** Persistence warning that keeps in-memory content visible.

**Primary action:** Save cart.

**Secondary actions:** Clear cart, continue shopping.

```text
┌────────────────────────────┐
│ Current cart               │
│ [img] Product title        │
│       $20.00 each          │
│       [−] 2 [+]   $40.00   │
│────────────────────────────│
│ Items                    2 │
│ Subtotal             $40.00│
│ Total                $40.00│
│ [        Save cart       ] │
│ [        Clear cart      ] │
│ Home Cart Saved Profile    │
└────────────────────────────┘
```

### Saved carts

**Purpose:** Reopen, restore, or delete saved snapshots.

**Sections:** Saved-cart list and optional separate remote-history section.

**Loading:** Skeleton list.

**Empty:** Explanation plus Go to cart action.

**Error:** Retry panel.

**Primary action:** Open snapshot.

```text
┌────────────────────────────┐
│ Saved carts                │
│ ┌────────────────────────┐ │
│ │ Weekend picks          │ │
│ │ Jul 12 · 4 items       │ │
│ │ $138.44          ›     │ │
│ └────────────────────────┘ │
│ ┌────────────────────────┐ │
│ │ Electronics            │ │
│ │ Jul 10 · 2 items       │ │
│ │ $83.98           ›     │ │
│ └────────────────────────┘ │
│ Home Cart Saved Profile    │
└────────────────────────────┘
```

### Saved cart details

**Purpose:** Inspect a snapshot before restoring or deleting.

**Sections:** Metadata, immutable line list, total, restore/delete.

**Primary action:** Restore.

**Secondary action:** Delete.

### Profile

**Purpose:** Show the authenticated user and provide logout.

**Sections:** Avatar/name header, information tiles, logout.

**Loading:** Session data is already available; a progress state is retained for defensive restore.

**Error:** Safe sign-out prompt if profile data becomes unavailable.

```text
┌────────────────────────────┐
│ Profile                    │
│       [avatar]             │
│       John Doe             │
│       @johnd               │
│ ✉ john@example.com         │
│ ☎ 1-570-236-7033           │
│ ⌂ New Road 3, Kilcoole...  │
│ [         Log out        ] │
│ Home Cart Saved Profile    │
└────────────────────────────┘
```
