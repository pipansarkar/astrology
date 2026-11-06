# Astrology

A free Vedic astrology app built with Flutter and Supabase.

## Features

- **Daily panjika**: Bengali date (Bangabda), sunrise and sunset, moonrise and moonset, tithi, nakshatra, yoga and karana with their end times, Rahu Kaal, Yamaganda, Gulika, Abhijit and Brahma muhurta, Bhadra, Panchak, lunar month, Vikram and Shaka samvat, and ritu, for any place and date
- **Festivals and vrats**: Durga Puja, Kali Puja, Saraswati Puja, Poila Boishakh, Rath Yatra, Ekadashi, Purnima, Amavasya, Sankranti and more, computed for any year and place (checked against published 2025–26 dates)
- **Muhurat finder**: auspicious windows for marriage, griha pravesh, annaprashan, namakaran, vehicle, property and business, optionally personalised (Chandrashtama, Tara)
- **Doshas**: Mangal (with common cancellations), Kaal Sarp, Pitra, Guru Chandal and Grahan, plus a lifetime Sade Sati and Shani dhaiya timeline
- **Transits**: the next 12 months of Jupiter, Saturn, Rahu and Mars sign changes, retrograde stations and eclipses, read from the Moon sign
- **Numerology**: Mulank, Bhagyank and Chaldean name number
- **Languages**: English, Bengali and Hindi, switchable in the app
- **Free Kundli**: Rashi (D1) and Navamsa (D9) charts in North, South or East Indian style, planet positions with nakshatra and pada, house, retrograde status and dignity, plus a basic Manglik check
- **Places worldwide**: about 37,600 places bundled offline (every Indian town over 1,000 people and world cities over 15,000) with historical time zones, including India's 1942–45 war time and daylight saving abroad. Coordinates can also be entered by hand
- **Kundli Matching**: Ashtakoota Guna Milan (36 points) with Nadi, Bhakoot and Manglik notes
- **PDF report**: a two-page kundli with charts, planets, panchang and dasha, shared from the chart screen
- **Vimshottari Dasha**: all Mahadashas and Antardashas, with the current period highlighted
- **Panchang**: tithi, nakshatra, yoga, karana and vara, both at birth and for today
- **Daily Horoscope**: calculated from the Moon's real position using Chandra Gochar (Moon's house from your rashi) and Tara Bala (today's nakshatra from your birth nakshatra)
- **Trust**: a fixed visible price, a 24-hour answer promise, no fear-based selling, and public astrologer profiles with user ratings
- **Ask an Astrologer**: users ask about a birth chart and an astrologer answers from an in-app desk that shows the chart and current dasha. The first question is free; paid questions (₹99) are prepared in the database but payments are not connected yet
- **Reading assistant for astrologers**: works out the question's topic, then analyses the relevant houses, lords, significators, current dasha, Sade Sati and Jupiter/Saturn transits, and upcoming favourable periods. It drafts an answer for the astrologer to edit. It is rule-based, so it runs free and offline
- **Accounts**: every user gets a guest account automatically (Supabase anonymous sign-in). They can turn it into an email and password or Google account at any time and keep their data. No verification email is sent
- **Push notifications** (Firebase Cloud Messaging): users are notified when their answer is ready, astrologers when a new question arrives, and anyone who opts in gets a 7 AM daily horoscope reminder

All charts use the sidereal zodiac with Lahiri ayanamsa, whole-sign houses and the mean lunar node.

## Tech

| Part | Choice |
|------|--------|
| App | Flutter (Android first) |
| Calculations | [Swiss Ephemeris](https://www.astro.com/swisseph/) via [`sweph`](https://pub.dev/packages/sweph) |
| Backend | [Supabase](https://supabase.com): Auth, Postgres with row-level security, Edge Functions, pg_cron |
| Push | Firebase Cloud Messaging (HTTP v1, sent from a Supabase Edge Function) |

## Run it

```sh
flutter pub get
cp app_config.example.json app_config.json   # add your project URL + publishable key
flutter run --dart-define-from-file=app_config.json
```

Without `app_config.json` the app still runs: kundli and horoscope work offline, but sign-in and saved charts are hidden.

### Your own Supabase project

```sh
supabase link --project-ref <your-ref>
supabase db push          # applies supabase/migrations
supabase config push      # auth settings (anonymous sign-in on)
```

### Google sign-in (optional)

1. Google Cloud console → APIs & Services → Credentials:
   - Create a **Web application** OAuth client. Its ID goes in `app_config.json` as `GOOGLE_WEB_CLIENT_ID`.
   - Create an **Android** OAuth client with package `com.pipansarkar.astrology` and the SHA-1 of your signing key (`cd android && ./gradlew signingReport`).
2. Supabase → Authentication → Providers → **Google**: enable it, paste the web client ID and secret, and turn on **Skip nonce check**.

The button is hidden until `GOOGLE_WEB_CLIENT_ID` is set.

### Push notifications

1. Create a Firebase project and add an Android app with package `com.pipansarkar.astrology`. Copy its project ID, API key, app ID and sender ID into `app_config.json`.
2. Firebase console → Project settings → Service accounts → **Generate new private key**.
3. Store the key and a shared secret in Supabase:
   ```sh
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)" PUSH_SECRET=<random>
   supabase functions deploy push --no-verify-jwt --use-api
   ```
4. In the SQL editor, give the database the function URL and the same secret:
   ```sql
   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_function_url');
   select vault.create_secret('<same random>', 'push_secret');
   ```

### Add an astrologer

In the SQL editor, invite their email:

```sql
insert into public.astrologer_invites (email, display_name)
values ('astrologer@example.com', 'Their Name');
```

When that email creates an account in the app (**Sign in → Create account**), or if it already has one, it becomes an astrologer automatically. The home screen then shows **Astrologer desk**.

Security for questions is enforced in Postgres (row-level security plus `submit_question` and `answer_question` functions). To check it against your project, run `python3 supabase/tests/qa_security_test.py`.

Horoscope texts are stored in the `horoscope_texts` table. You can edit them in the dashboard, or add Bengali and Hindi versions as rows with `lang = 'bn'` or `lang = 'hi'`. To regenerate the English seed after editing `lib/horoscope/default_texts.dart`:

```sh
dart run tool/gen_horoscope_seed.dart > supabase/migrations/20261105000100_horoscope_texts.sql
```

## Translations

UI strings are wrapped in `tr('English text')` and translated in `tool/translations_bn.py` and `tool/translations_hi.py`. After changing text:

```sh
python3 -I tool/extract_tr_keys.py --missing   # list untranslated strings
python3 -I tool/gen_strings.py                 # regenerate lib/l10n/strings_*.dart
```

Astrological names (signs, nakshatras, tithis and so on) are in `lib/l10n/names.dart`. The astrologer desk, the reading assistant, some generated dosha details and the PDF report stay in English.

## Tests

```sh
flutter test
```

The Swiss Ephemeris tests need a desktop build of the C library because `flutter test` cannot load the Android one. See the header of `test/swiss_ephemeris_test.dart`.

## Data

Place names and coordinates © [GeoNames](https://www.geonames.org), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). To rebuild `assets/cities.tsv`, see `tool/build_cities.py`.

## Licence

This app uses the Swiss Ephemeris, which is licensed under the GNU Affero General Public License v3. This app is therefore also released under the **AGPL-3.0**; see [LICENSE](LICENSE). If you distribute a modified version, including as a mobile app, you must make your source code available under the same licence.

For guidance and entertainment purposes only.
