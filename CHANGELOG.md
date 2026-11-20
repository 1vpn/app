# Changelog

One entry per release, newest first. Each entry states the version, the date of its cut and the
upstream pin. Its notes list each change with the platforms it affects.

## 3.0.2 - 2026-11-19

Upstream pin: `fb988b89c04e8411c0558ae0d2ee2b7c1ec3ba1f`

Platforms: Android.

- Lookups inside the tunnel now go to Cloudflare, with Google as a backup, and are faster on
  free locations. (Android)
- After an update, a connected tunnel picks up the new settings the next time you open the app,
  with one brief reconnect. (Android)

## 3.0.1 - 2026-11-11

Upstream pin: `fb988b89c04e8411c0558ae0d2ee2b7c1ec3ba1f`

Platforms: Android.

- Xray-core moves to v26.10.31 through libXray, with the MPTCP advisory. (Android)
- A picked direct region sends only that region's sites and local-network names outside the
  tunnel. The whole Apple, Microsoft and Bing lists no longer go direct with it. On Android,
  a tunnel already running takes the change the next time the app starts. (Android)
- A sign-up whose password the server refuses shows the password rules. (Android)
- A lost reply to the session refresh no longer ends the session: the app retries the rotation
  once inside the server's grace window. The server side of this ships separately; until it is
  live, an already-lost session ends at that refresh instead of the next one. (Android)
- The purchased screen returns on launch until the account exists. (Android)
- Ads and the purchase sheet open inside the app, no longer as a separate entry in the app
  switcher. A tap on the app's icon, the tile or a notification while one is open closes it.
  (Android)
- The app keeps a single entry in the app switcher. A second 1VPN entry can no longer appear
  after an update or a start from the tile. (Android)
- A geodata refresh is refused when the list is incomplete, and the files swap atomically.
  (Android)
- The Support buttons use title case and the version shows in the footer. The store SDK logs
  warnings only in release builds. (Android)
- Direct installs: the 3.0.1 APK on the public release is signed by Google Play. A device that
  installed the 3.0.0 APK from the public release, which was signed with a different key,
  uninstalls it once and installs 3.0.1; Play installs are unaffected. (Android)

## 3.0.0 - 2026-11-03

Upstream pin: `fb988b89c04e8411c0558ae0d2ee2b7c1ec3ba1f`

Platforms: Android.

- 1VPN 3 replaces 1VPN 2. The app is a fork of OneXray on the Xray core. (Android)
- After the update from 1VPN 2, the app starts signed out. The first launch deletes the session
  and the connection credentials that 1VPN 2 stored. Users log in again with the same 1VPN
  account. (Android)
- Users log in, sign up and log out with a 1VPN account. A user with 2FA also enters the 2FA
  token to log in. (Android)
- The location list follows the account's plan. Free and signed-out users connect to the free
  locations. A locked location opens the paywall. (Android)
- One tap connects. Automatic measures the locations and connects to the fastest. (Android)
- A connect that finds no working location blocks traffic and reads Connection Failed. A picked
  location stays picked. After a minute with no answer, the tunnel stops. A tap retries.
  (Android)
- The tunnel stays up across a network change, such as Wi-Fi to mobile data. (Android)
- Direct Regions sends one picked region's sites outside the tunnel, from the user's real IP
  address. (Android)
- While connected, DNS goes through the tunnel. Names in a Direct Region resolve on the local
  network, unless Private DNS is on. (Android)
- A tap on the Quick Settings tile opens the app and connects. A tap while connected
  disconnects. The launcher icon's long-press menu offers Connect. (Android)
- When a purchase cannot go through because the Google account already holds a 1VPN
  subscription, the paywall says so and links 1VPN Support. A Google Play sheet left open
  comes back when the app returns, and a purchase Google Play never finished is cleared on
  the next tap. (Android)
- Free users see an ad when they switch location while connected: the connection stops, the
  ad shows, and the connection resumes on the new location. Premium users switch without
  interruption. (Android)
- The app's own connections for the account and the store leave outside the tunnel, as in
  1VPN 2. The tunnel carries the rest of the device as before. (Android)
- The menu has Always-On VPN guidance. (Android)
- After the update from 1VPN 2, an Always-On VPN user opens the app and connects once. Until
  then, Always-On VPN cannot start the tunnel, and with Block connections without VPN turned on
  the device has no connection. A notification asks the user to open 1VPN. (Android)
- The app sells premium as a monthly or yearly Google Play subscription. Each plan card shows
  its store price per month. The Yearly badge states the saving those prices give. (Android)
- For free and signed-out users, the paywall opens at launch or on a return to the app. It
  opens at most once every 12 hours. (Android)
- A completed purchase unlocks premium before the server confirms it. A buyer with no account
  signs up with the email the purchase used. (Android)
- Premium follows the 1VPN account. A subscriber from 1VPN 2 logs in and keeps premium.
  (Android)
- Free and signed-out users see an ad before some connects. The ad shows before the tunnel comes
  up. The first connect is ad-free. (Android)
- Where the law requires consent, Google's consent form asks before the first ad. Privacy
  Choices on the Support page changes the answer. (Android)
- The Support page links the FAQ, Contact Us, the policies and Manage subscription. It shows the
  app version and build number. (Android)
- When the main 1VPN domain is unreachable, the app uses a backup domain. The connect screen
  names it. (Android)
- Free and signed-out users whose app language is Russian, Persian or Chinese see a warning
  once, before a connect. It says that government restrictions may block some servers.
  (Android)
- On Android 13 and later, the first connect asks for the notification permission. The
  connected notification needs it. (Android)
- After a disconnect on the connect screen, the app asks whether the user is enjoying 1VPN.
  Yes opens Google Play's review sheet, or the store listing when no sheet shows. The app stops
  asking once the user answers. (Android)
- The menu's Language page sets the app language. It lists System Default and each language
  under its native name. System Default follows the device language. (Android)
- The app comes in 26 languages, with localized place names. (Android)
- The release builds from pinned native inputs: libXray with Xray-core v26.10.21, and the v2fly
  geodata. (Android)
