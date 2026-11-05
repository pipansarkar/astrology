// Default (English) daily horoscope texts. Pure Dart: also used by
// tool/gen_horoscope_seed.dart to generate the Supabase seed SQL.
//
// Texts edited in the Supabase table `horoscope_texts` override these, so
// content and translations can change without an app update.

enum Tone { good, mixed, caution }

class HoroscopeText {
  const HoroscopeText(this.title, this.body);
  final String title;
  final String body;
}

/// Chandra Gochar: transiting Moon in house 1-12 counted from the natal
/// Moon sign (rashi). Index 0 = 1st house.
const gocharTone = [
  Tone.mixed,
  Tone.mixed,
  Tone.good,
  Tone.caution,
  Tone.mixed,
  Tone.good,
  Tone.good,
  Tone.caution,
  Tone.mixed,
  Tone.good,
  Tone.good,
  Tone.caution,
];

const defaultGochar = <HoroscopeText>[
  HoroscopeText(
    'Moon in your own sign',
    'Feelings run strong today and you notice your own needs more than usual. '
        'Look after your health, eat on time and give yourself some quiet. '
        'A good day to start something personal, not to argue.',
  ),
  HoroscopeText(
    'Focus on money and family',
    'Attention turns to savings, food and family matters. '
        'Think before spending and choose your words carefully, since speech '
        'is sensitive today. A family meal or call brings warmth.',
  ),
  HoroscopeText(
    'Courage and communication',
    'Energy and confidence are high. Make the call, send the message or take '
        'the short trip you have been putting off. Brothers, sisters and '
        'neighbours can be helpful.',
  ),
  HoroscopeText(
    'Home and peace of mind',
    'You may feel restless or low on comfort. Stay close to home, avoid '
        'arguments with family and postpone property or vehicle decisions. '
        'Time with your mother or in a calm place helps.',
  ),
  HoroscopeText(
    'Studies, children and creativity',
    'The mind is active but can wander. Good for study, creative work and '
        'time with children, but avoid speculation and quick decisions about '
        'money. Keep promises small and realistic.',
  ),
  HoroscopeText(
    'Victory over obstacles',
    'A strong day for clearing pending work, tackling problems and handling '
        'competition. Health routines and service to others bring good results. '
        'Pending dues or loans can move forward.',
  ),
  HoroscopeText(
    'Partnerships and people',
    'Relationships, meetings and deals are favoured. Your spouse or business '
        'partner is supportive. Good for social plans, travel with others and '
        'agreements made in good faith.',
  ),
  HoroscopeText(
    'Chandrashtama: go slowly',
    'The Moon is 8th from your sign, a traditional day for caution. Avoid '
        'major decisions, risky travel and new commitments. Rest, drive carefully '
        'and keep your temper. This passes in about two days.',
  ),
  HoroscopeText(
    'Elders, faith and fortune',
    'Blessings come through teachers, elders and acts of faith. Good for '
        'prayer, learning and planning long journeys. Results are mixed for '
        'material matters, so be patient with outcomes.',
  ),
  HoroscopeText(
    'Work and recognition',
    'Your efforts at work get noticed. Good for meetings with seniors, '
        'important tasks and taking responsibility. Act with confidence and '
        'finish what you begin.',
  ),
  HoroscopeText(
    'Gains and good news',
    'One of the best days of the cycle. Income, help from friends and '
        'fulfilment of wishes are likely. Ask for what you need and enjoy time '
        'with your circle.',
  ),
  HoroscopeText(
    'Rest and letting go',
    'Expenses and tiredness may increase. Keep spending in check, sleep well '
        'and avoid starting important work. A good day for meditation, charity '
        'and finishing old tasks quietly.',
  ),
];

/// Tara Bala: today's nakshatra counted from the birth nakshatra.
/// Index 0 = Janma (1st) ... 8 = Param Mitra (9th).
const taraNames = [
  'Janma',
  'Sampat',
  'Vipat',
  'Kshema',
  'Pratyak',
  'Sadhana',
  'Naidhana',
  'Mitra',
  'Param Mitra',
];

const taraTone = [
  Tone.mixed,
  Tone.good,
  Tone.caution,
  Tone.good,
  Tone.caution,
  Tone.good,
  Tone.caution,
  Tone.good,
  Tone.good,
];

const defaultTara = <HoroscopeText>[
  HoroscopeText(
    'Janma Tara',
    'Today\'s star is your birth star. Keep things simple and look after your '
        'body and mind.',
  ),
  HoroscopeText(
    'Sampat Tara',
    'A star of wealth. Favourable for money matters, purchases and new '
        'efforts.',
  ),
  HoroscopeText(
    'Vipat Tara',
    'A star of obstacles. Expect small delays; double-check plans and avoid '
        'starting new ventures.',
  ),
  HoroscopeText(
    'Kshema Tara',
    'A star of well-being. Good for health, comfort and steady progress.',
  ),
  HoroscopeText(
    'Pratyak Tara',
    'A star of resistance. People may oppose you; stay patient and avoid '
        'confrontations.',
  ),
  HoroscopeText(
    'Sadhana Tara',
    'A star of achievement. Efforts succeed; a good day to complete goals.',
  ),
  HoroscopeText(
    'Naidhana Tara',
    'A difficult star. Avoid risks, travel carefully and postpone important '
        'decisions.',
  ),
  HoroscopeText(
    'Mitra Tara',
    'A friendly star. Help comes from friends; good for cooperation.',
  ),
  HoroscopeText(
    'Param Mitra Tara',
    'A very friendly star. Support and good results come easily today.',
  ),
];
