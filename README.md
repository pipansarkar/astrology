# Astrology

A free Vedic astrology app built with Flutter and Supabase.

## Features

- **Free Kundli**: Rashi (D1) and Navamsa (D9) charts in North Indian style, planet positions with nakshatra and pada, house, retrograde status and dignity, plus a basic Manglik check
- **Vimshottari Dasha**: all Mahadashas and Antardashas, with the current period highlighted
- **Panchang**: tithi, nakshatra, yoga, karana and vara, both at birth and for today
- **Daily Horoscope**: calculated from the Moon's real position using Chandra Gochar (Moon's house from your rashi) and Tara Bala (today's nakshatra from your birth nakshatra)
- **Ask an Astrologer**: users ask about a birth chart and an astrologer answers from an in-app desk that shows the chart and current dasha. The first question is free; paid questions (₹99) are prepared in the database but payments are not connected yet
- **No sign-up**: every user gets an account automatically (Supabase anonymous sign-in), and charts and questions are saved to it. Astrologers log in with email and password

All charts use the sidereal zodiac with Lahiri ayanamsa, whole-sign houses and the mean lunar node.

## Tech

| Part | Choice |
|------|--------|
| App | Flutter (Android first) |
| Calculations | [Swiss Ephemeris](https://www.astro.com/swisseph/) via [`sweph`](https://pub.dev/packages/sweph) |
| Backend | [Supabase](https://supabase.com): Auth and Postgres with row-level security |

## Run it

```sh
flutter pub get
cp supabase.example.json supabase.json   # add your project URL + publishable key
flutter run --dart-define-from-file=supabase.json
```

Without `supabase.json` the app still runs: kundli and horoscope work offline, but sign-in and saved charts are hidden.

### Your own Supabase project

```sh
supabase link --project-ref <your-ref>
supabase db push          # applies supabase/migrations
supabase config push      # auth settings (anonymous sign-in on)
```

### Add an astrologer

1. Dashboard → Authentication → **Add user**: enter their email and a password, and tick **Auto Confirm User**.
2. SQL Editor:
   ```sql
   insert into public.astrologers (user_id, display_name)
   select id, 'Their Name' from auth.users where email = 'astrologer@example.com';
   ```
3. In the app, open ⋮ → **Astrologer login**. The home screen then shows **Astrologer desk**.

Security for questions is enforced in Postgres (row-level security plus `submit_question` and `answer_question` functions). To check it against your project, run `python3 supabase/tests/qa_security_test.py`.

Horoscope texts are stored in the `horoscope_texts` table. You can edit them in the dashboard, or add Bengali and Hindi versions as rows with `lang = 'bn'` or `lang = 'hi'`. To regenerate the English seed after editing `lib/horoscope/default_texts.dart`:

```sh
dart run tool/gen_horoscope_seed.dart > supabase/migrations/20261105000100_horoscope_texts.sql
```

## Tests

```sh
flutter test
```

The Swiss Ephemeris tests need a desktop build of the C library because `flutter test` cannot load the Android one. See the header of `test/swiss_ephemeris_test.dart`.

## Licence

This app uses the Swiss Ephemeris, which is licensed under the GNU Affero General Public License v3. This app is therefore also released under the **AGPL-3.0**; see [LICENSE](LICENSE). If you distribute a modified version, including as a mobile app, you must make your source code available under the same licence.

For guidance and entertainment purposes only.
