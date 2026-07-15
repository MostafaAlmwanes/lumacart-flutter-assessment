# LumaCart Requirements

## Source material

This document reconciles the uploaded `Flutter Task.pdf`, the uploaded `fake-store-api-reference.md`, the Fake Store API base URL, and the official API documentation. The PDF requires authentication, a searchable product catalog, product details, a cart with saved carts, profile data, local persistence, state management, clean code, usable UX, and optional animations. The expanded assessment brief adds secure local accounts, BLoC, offline cache, tests, and an Android release artifact.

## Project decisions

- **App name:** LumaCart
- **Positioning:** A focused mobile storefront for browsing products, maintaining a current cart, and revisiting saved carts.
- **State management:** BLoC and Cubit using `flutter_bloc`.
- **Local persistence:** Hive CE boxes storing structured JSON maps. This avoids generated adapters while retaining structured, inspectable local records.
- **Sensitive storage:** `flutter_secure_storage` for the active session and remote token.
- **Password storage:** PBKDF2-HMAC-SHA256 with a random 16-byte salt and 120,000 iterations. Raw passwords are never persisted.
- **Navigation:** `go_router` with an authenticated shell containing Home, Cart, Saved Carts, and Profile. Product details is pushed above the shell.
- **Data flow:** Widgets dispatch events to BLoCs/Cubits; domain repositories coordinate remote and local data sources; storage and HTTP stay outside widgets.
- **Android minimum SDK:** API 24. This follows the Flutter 3.44.6 Android template baseline and is compatible with the selected maintained plugins.
- **Application ID:** `com.lumacart.store`.

## Functional requirements

### Authentication

1. Existing Fake Store API users can sign in with username and password through `POST /auth/login`.
2. After remote authentication, the app fetches `/users` and matches the username to resolve the full profile and numeric user ID.
3. New users can register with first name, last name, email, username, password, phone, city, street, street number, and ZIP/postal code.
4. Sign-up calls `POST /users` for integration demonstration, then stores the account locally because the API does not persist writes.
5. A local account can sign in after restart using the stored salted password hash.
6. The active session is restored on launch.
7. Logout clears the active secure session but leaves saved carts intact.

### Product catalog

1. Load products and categories from Fake Store API.
2. Display product image, title, price, rating, rating count, and category.
3. Search by title and category using case-insensitive matching with debounce.
4. Filter by category chips.
5. Support pull-to-refresh.
6. Show skeleton/loading, empty, cached-offline, and retryable error states.
7. Cache the last successful product list locally.

### Product details

1. Display a large product image, category, title, price, rating, description, and quantity selector.
2. Use a Hero transition for the product image.
3. Add the selected quantity to the active cart.
4. Confirm the cart update without disrupting navigation.

### Current cart

1. Display image, title, unit price, quantity, and line total.
2. Increase, decrease, set, and remove quantities.
3. Prevent quantities below one for retained lines.
4. Merge duplicate additions by increasing quantity.
5. Display item count, subtotal, and total with two-decimal currency formatting.
6. Persist after every meaningful change.
7. Save a non-empty cart as a named snapshot.
8. Clear only after confirmation.

### Saved carts

1. List saved carts newest first.
2. Display name, date, item count, and total.
3. Open saved-cart details.
4. Restore by replacing or merging into the active cart after confirmation.
5. Delete a saved cart after confirmation.
6. Retain saved carts across app restarts and logout.
7. Remote cart history is optional and clearly separated from local saved carts.

### Profile

1. Display avatar placeholder, full name, username, email, phone, and formatted address.
2. Support both remote API users and local accounts.
3. Never display a password, password hash, salt, or authentication token.
4. Provide logout.

## Non-functional requirements

- Dart null safety throughout.
- Material 3 UI.
- Feature-first organization with pragmatic presentation, domain, and data layers.
- Immutable state, `Equatable`, and explicit failure types.
- No HTTP or database access from widgets.
- No global mutable state.
- No production `print` calls.
- Centralized strings, spacing, radii, durations, colors, API paths, and timeouts.
- Every asynchronous feature exposes loading, success, empty, and failure behavior where applicable.
- Offline product fallback uses the last successful cache.
- Minimum 48x48 logical-pixel targets, semantic labels, large-text resilience, and sufficient contrast.
- Analyzer-clean and formatted code.
- Unit, BLoC, and widget coverage for core behavior.
- Release APK built only after analyze and tests pass.

## API limitations and impact

Fake Store API create, update, and delete operations return simulated responses but do not permanently modify the server database.

- Remote sign-up is demonstrative only. The app persists a local account as the durable record.
- Local authentication is checked before remote login so registered users can return after restart.
- The active cart and saved carts are local sources of truth.
- `POST /carts` may be attempted as a demonstration for remote users, but local success never depends on it.
- Remote user cart history is read-only supplemental data.
- The API user payload exposes fake plaintext passwords. The app does not persist, display, or log them.

## Assumptions

- English UI is acceptable; localization is outside the assessment core.
- Prices are displayed as USD because the API provides numeric prices without currency metadata.
- Taxes, shipping, discounts, inventory, payment, and order placement are not modeled.
- One active session is supported at a time.
- Saved carts are shared on the device rather than deleted on logout; each snapshot stores its owner key for filtering.
- Cached catalog data may be stale while offline and is labeled accordingly.

## Out of scope

- Checkout and payment.
- Order creation or fulfillment.
- Admin product CRUD.
- Wishlists.
- Push notifications.
- Social login.
- Password reset.
- Backend account verification.
- Multi-currency conversion.
- Production analytics and crash reporting.

## Screen acceptance criteria

### Splash

- Shows a compact branded loading state.
- Restores a valid session and routes to the shell.
- Routes safely to sign-in when data is missing, corrupted, or incomplete.
- Does not expose token contents.

### Sign in

- Username and password validation appears near fields.
- Password visibility toggle has a semantic label.
- Valid remote credentials authenticate and load the full user profile.
- Valid local credentials authenticate after restart.
- Invalid credentials produce a useful, non-technical error.
- Demo credentials are available as a low-emphasis hint.

### Sign up

- All required fields are validated specifically.
- Duplicate local username and email are blocked.
- Password confirmation must match.
- Remote simulated registration is attempted.
- Local account and session persist without plaintext password storage.

### Home

- Products and categories load with visible progress.
- Cached products remain usable offline after a successful prior load.
- Search and category filters combine correctly.
- Pull-to-refresh and retry work.
- Cards remain readable with large text.

### Product details

- Complete product information is readable.
- Image failure has a stable placeholder.
- Quantity cannot be less than one.
- Add-to-cart updates the active cart and provides feedback.

### Cart

- Empty and populated states are distinct.
- Quantity controls, removal, clear, save, totals, and persistence work.
- Empty cart cannot be saved.
- Destructive actions require confirmation or offer undo.

### Saved carts

- Saved snapshots appear newest first.
- Details, replace, merge, and delete work.
- Empty state explains how to create a saved cart.

### Profile

- Complete session profile is displayed for both account types.
- Logout clears active authentication and blocks protected routes.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Fake Store API is unavailable or slow | Dio timeouts, mapped failures, retry action, cached catalog fallback |
| Remote writes appear successful but vanish | Local account/cart persistence is authoritative and UI copy avoids implying permanent server storage |
| Secure storage is unavailable in widget tests | Repository abstractions and in-memory fakes |
| Corrupt local JSON | Versioned parsing, defensive defaults, record-level discard, safe sign-out |
| Floating-point display artifacts | Store API price as `double`, calculate in integer cents for totals, format to two decimals |
| Search rebuild cost | Debounced query event and derived filtered list in BLoC state |
| Large text breaks two-column cards | Responsive switch to one column based on width and text scale |
| Plugin/Android compatibility drift | Deliberate package constraints, documented SDK floor, release build quality gate |
| Release signing secrets leak | Local signing only, ignored properties/keystore files, documented production setup |
