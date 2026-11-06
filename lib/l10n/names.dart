// Translated astrological names. English uses the existing names.

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/panjika.dart';
import '../astro/vedic/panchang.dart';
import 'l10n.dart';

T _pick<T>(T en, T bn, T hi) => switch (LanguageSetting.current) {
  AppLanguage.en => en,
  AppLanguage.bn => bn,
  AppLanguage.hi => hi,
};

// ------------------------------------------------------------------ signs

const _signsBn = [
  'মেষ',
  'বৃষ',
  'মিথুন',
  'কর্কট',
  'সিংহ',
  'কন্যা',
  'তুলা',
  'বৃশ্চিক',
  'ধনু',
  'মকর',
  'কুম্ভ',
  'মীন',
];
const _signsHi = [
  'मेष',
  'वृषभ',
  'मिथुन',
  'कर्क',
  'सिंह',
  'कन्या',
  'तुला',
  'वृश्चिक',
  'धनु',
  'मकर',
  'कुंभ',
  'मीन',
];

/// "Aries (Mesha)" in English, "মেষ" / "मेष" otherwise.
String signName(int i) => _pick(
  '${signNames[i]} (${signNamesSanskrit[i]})',
  _signsBn[i],
  _signsHi[i],
);

/// Short: "Aries" / "মেষ" / "मेष".
String signShort(int i) => _pick(signNames[i], _signsBn[i], _signsHi[i]);

/// Indian name: "Mesha" / "মেষ" / "मेष".
String rashiName(int i) =>
    _pick(signNamesSanskrit[i], _signsBn[i], _signsHi[i]);

// ------------------------------------------------------------- nakshatras

const _naksBn = [
  'অশ্বিনী',
  'ভরণী',
  'কৃত্তিকা',
  'রোহিণী',
  'মৃগশিরা',
  'আর্দ্রা',
  'পুনর্বসু',
  'পুষ্যা',
  'অশ্লেষা',
  'মঘা',
  'পূর্বফাল্গুনী',
  'উত্তরফাল্গুনী',
  'হস্তা',
  'চিত্রা',
  'স্বাতী',
  'বিশাখা',
  'অনুরাধা',
  'জ্যেষ্ঠা',
  'মূলা',
  'পূর্বাষাঢ়া',
  'উত্তরাষাঢ়া',
  'শ্রবণা',
  'ধনিষ্ঠা',
  'শতভিষা',
  'পূর্বভাদ্রপদ',
  'উত্তরভাদ্রপদ',
  'রেবতী',
];
const _naksHi = [
  'अश्विनी',
  'भरणी',
  'कृत्तिका',
  'रोहिणी',
  'मृगशिरा',
  'आर्द्रा',
  'पुनर्वसु',
  'पुष्य',
  'आश्लेषा',
  'मघा',
  'पूर्वाफाल्गुनी',
  'उत्तराफाल्गुनी',
  'हस्त',
  'चित्रा',
  'स्वाति',
  'विशाखा',
  'अनुराधा',
  'ज्येष्ठा',
  'मूल',
  'पूर्वाषाढ़ा',
  'उत्तराषाढ़ा',
  'श्रवण',
  'धनिष्ठा',
  'शतभिषा',
  'पूर्वाभाद्रपद',
  'उत्तराभाद्रपद',
  'रेवती',
];

String nakshatraName(int i) => _pick(nakshatraNames[i], _naksBn[i], _naksHi[i]);

/// "Rohini 3" with localised digits.
String nakshatraWithPada(Placement p) =>
    '${nakshatraName(p.nakshatra)} ${digits(p.pada)}';

// ---------------------------------------------------------------- planets

const _planetsBn = {
  Body.sun: 'সূর্য',
  Body.moon: 'চন্দ্র',
  Body.mars: 'মঙ্গল',
  Body.mercury: 'বুধ',
  Body.jupiter: 'বৃহস্পতি',
  Body.venus: 'শুক্র',
  Body.saturn: 'শনি',
  Body.rahu: 'রাহু',
  Body.ketu: 'কেতু',
};
const _planetsHi = {
  Body.sun: 'सूर्य',
  Body.moon: 'चंद्र',
  Body.mars: 'मंगल',
  Body.mercury: 'बुध',
  Body.jupiter: 'गुरु',
  Body.venus: 'शुक्र',
  Body.saturn: 'शनि',
  Body.rahu: 'राहु',
  Body.ketu: 'केतु',
};
const _shortBn = {
  Body.sun: 'র',
  Body.moon: 'চ',
  Body.mars: 'ম',
  Body.mercury: 'বু',
  Body.jupiter: 'বৃ',
  Body.venus: 'শু',
  Body.saturn: 'শ',
  Body.rahu: 'রা',
  Body.ketu: 'কে',
};
const _shortHi = {
  Body.sun: 'सू',
  Body.moon: 'चं',
  Body.mars: 'मं',
  Body.mercury: 'बु',
  Body.jupiter: 'गु',
  Body.venus: 'शु',
  Body.saturn: 'श',
  Body.rahu: 'रा',
  Body.ketu: 'के',
};

String planetName(Body b) =>
    _pick(bodyNames[b]!, _planetsBn[b]!, _planetsHi[b]!);

/// Chart label, e.g. "Ma(R)", "ম(ব)", "मं(व)".
String planetShort(Body b, {bool retrograde = false}) {
  final base = _pick(bodyShort[b]!, _shortBn[b]!, _shortHi[b]!);
  return retrograde ? '$base(${_pick('R', 'ব', 'व')})' : base;
}

// ----------------------------------------------------------------- tithis

const _tithiBn = [
  'প্রতিপদ',
  'দ্বিতীয়া',
  'তৃতীয়া',
  'চতুর্থী',
  'পঞ্চমী',
  'ষষ্ঠী',
  'সপ্তমী',
  'অষ্টমী',
  'নবমী',
  'দশমী',
  'একাদশী',
  'দ্বাদশী',
  'ত্রয়োদশী',
  'চতুর্দশী',
];
const _tithiHi = [
  'प्रतिपदा',
  'द्वितीया',
  'तृतीया',
  'चतुर्थी',
  'पंचमी',
  'षष्ठी',
  'सप्तमी',
  'अष्टमी',
  'नवमी',
  'दशमी',
  'एकादशी',
  'द्वादशी',
  'त्रयोदशी',
  'चतुर्दशी',
];

/// Tithi 1-30, e.g. "Shukla Dwitiya" / "শুক্ল দ্বিতীয়া" / "शुक्ल द्वितीया".
String tithiName(int t) {
  if (LanguageSetting.current == AppLanguage.en) return tithiFullName(t);
  if (t == 15) return _pick('', 'পূর্ণিমা', 'पूर्णिमा');
  if (t == 30) return _pick('', 'অমাবস্যা', 'अमावस्या');
  final paksha = t <= 15
      ? _pick('', 'শুক্ল', 'शुक्ल')
      : _pick('', 'কৃষ্ণ', 'कृष्ण');
  final name = _pick('', _tithiBn[(t - 1) % 15], _tithiHi[(t - 1) % 15]);
  return '$paksha $name';
}

String pakshaName(bool shukla) => shukla
    ? _pick('Shukla paksha', 'শুক্ল পক্ষ', 'शुक्ल पक्ष')
    : _pick('Krishna paksha', 'কৃষ্ণ পক্ষ', 'कृष्ण पक्ष');

// ------------------------------------------------------- yoga and karana

const _yogaBn = [
  'বিষ্কম্ভ',
  'প্রীতি',
  'আয়ুষ্মান',
  'সৌভাগ্য',
  'শোভন',
  'অতিগণ্ড',
  'সুকর্মা',
  'ধৃতি',
  'শূল',
  'গণ্ড',
  'বৃদ্ধি',
  'ধ্রুব',
  'ব্যাঘাত',
  'হর্ষণ',
  'বজ্র',
  'সিদ্ধি',
  'ব্যতীপাত',
  'বরীয়ান',
  'পরিঘ',
  'শিব',
  'সিদ্ধ',
  'সাধ্য',
  'শুভ',
  'শুক্ল',
  'ব্রহ্ম',
  'ইন্দ্র',
  'বৈধৃতি',
];
const _yogaHi = [
  'विष्कुम्भ',
  'प्रीति',
  'आयुष्मान',
  'सौभाग्य',
  'शोभन',
  'अतिगण्ड',
  'सुकर्मा',
  'धृति',
  'शूल',
  'गण्ड',
  'वृद्धि',
  'ध्रुव',
  'व्याघात',
  'हर्षण',
  'वज्र',
  'सिद्धि',
  'व्यतीपात',
  'वरीयान',
  'परिघ',
  'शिव',
  'सिद्ध',
  'साध्य',
  'शुभ',
  'शुक्ल',
  'ब्रह्म',
  'इन्द्र',
  'वैधृति',
];

String yogaName(int i) => _pick(yogaNames[i], _yogaBn[i], _yogaHi[i]);

const _karanaBn = {
  'Bava': 'বব',
  'Balava': 'বালব',
  'Kaulava': 'কৌলব',
  'Taitila': 'তৈতিল',
  'Gara': 'গর',
  'Vanija': 'বণিজ',
  'Vishti': 'বিষ্টি (ভদ্রা)',
  'Shakuni': 'শকুনি',
  'Chatushpada': 'চতুষ্পদ',
  'Naga': 'নাগ',
  'Kimstughna': 'কিংস্তুঘ্ন',
};
const _karanaHi = {
  'Bava': 'बव',
  'Balava': 'बालव',
  'Kaulava': 'कौलव',
  'Taitila': 'तैतिल',
  'Gara': 'गर',
  'Vanija': 'वणिज',
  'Vishti': 'विष्टि (भद्रा)',
  'Shakuni': 'शकुनि',
  'Chatushpada': 'चतुष्पद',
  'Naga': 'नाग',
  'Kimstughna': 'किंस्तुघ्न',
};

String karanaNameL(String en) =>
    _pick(en, _karanaBn[en] ?? en, _karanaHi[en] ?? en);

// ----------------------------------------------------------------- months

const _lunarBn = [
  'চৈত্র',
  'বৈশাখ',
  'জ্যৈষ্ঠ',
  'আষাঢ়',
  'শ্রাবণ',
  'ভাদ্রপদ',
  'আশ্বিন',
  'কার্তিক',
  'মার্গশীর্ষ',
  'পৌষ',
  'মাঘ',
  'ফাল্গুন',
];
const _lunarHi = [
  'चैत्र',
  'वैशाख',
  'ज्येष्ठ',
  'आषाढ़',
  'श्रावण',
  'भाद्रपद',
  'आश्विन',
  'कार्तिक',
  'मार्गशीर्ष',
  'पौष',
  'माघ',
  'फाल्गुन',
];

String lunarMonthName(LunarMonth m) {
  final name = _pick(
    lunarMonthNames[m.index],
    _lunarBn[m.index],
    _lunarHi[m.index],
  );
  return m.adhik ? '${_pick('Adhik', 'অধিক', 'अधिक')} $name' : name;
}

const _bengaliBn = [
  'বৈশাখ',
  'জ্যৈষ্ঠ',
  'আষাঢ়',
  'শ্রাবণ',
  'ভাদ্র',
  'আশ্বিন',
  'কার্তিক',
  'অগ্রহায়ণ',
  'পৌষ',
  'মাঘ',
  'ফাল্গুন',
  'চৈত্র',
];
const _bengaliHi = [
  'बैशाख',
  'ज्येष्ठ',
  'आषाढ़',
  'श्रावण',
  'भाद्र',
  'आश्विन',
  'कार्तिक',
  'अग्रहायण',
  'पौष',
  'माघ',
  'फाल्गुन',
  'चैत्र',
];

/// "20 Kartik 1433" / "২০ কার্তিক ১৪৩৩".
String bengaliDateLabel(BengaliDate d) {
  final m = _pick(
    bengaliMonthNames[d.month],
    _bengaliBn[d.month],
    _bengaliHi[d.month],
  );
  return '${digits(d.day)} $m ${digits(d.year)}';
}

// ------------------------------------------------------- weekday, season

const _varaEn = [
  'Somavar',
  'Mangalvar',
  'Budhvar',
  'Brihaspativar',
  'Shukravar',
  'Shanivar',
  'Ravivar',
];
const _varaBn = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];
const _varaHi = [
  'सोमवार',
  'मंगलवार',
  'बुधवार',
  'गुरुवार',
  'शुक्रवार',
  'शनिवार',
  'रविवार',
];

/// DateTime.monday ... DateTime.sunday.
String varaName(int weekday) =>
    _pick(_varaEn[weekday - 1], _varaBn[weekday - 1], _varaHi[weekday - 1]);

const _rituBn = ['বসন্ত', 'গ্রীষ্ম', 'বর্ষা', 'শরৎ', 'হেমন্ত', 'শীত'];
const _rituHi = ['वसंत', 'ग्रीष्म', 'वर्षा', 'शरद', 'हेमंत', 'शिशिर'];

String rituName(int sunSign) {
  final i = ((sunSign + 1) % 12) ~/ 2;
  return _pick(rituNames[i], _rituBn[i], _rituHi[i]);
}

// ---------------------------------------------------------------- ordinal

const _ordBn = [
  '১ম',
  '২য়',
  '৩য়',
  '৪র্থ',
  '৫ম',
  '৬ষ্ঠ',
  '৭ম',
  '৮ম',
  '৯ম',
  '১০ম',
  '১১শ',
  '১২শ',
];
const _ordHi = [
  'प्रथम',
  'द्वितीय',
  'तृतीय',
  'चतुर्थ',
  'पंचम',
  'षष्ठ',
  'सप्तम',
  'अष्टम',
  'नवम',
  'दशम',
  'एकादश',
  'द्वादश',
];

/// House ordinal 1-12: "8th" / "৮ম" / "अष्टम".
String ordinal(int n) {
  final en = switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
  if (n < 1 || n > 12) return en;
  return _pick(en, _ordBn[n - 1], _ordHi[n - 1]);
}

String lunarMonthNameByIndex(int i, {bool adhik = false}) {
  final name = _pick(lunarMonthNames[i], _lunarBn[i], _lunarHi[i]);
  return adhik ? '${_pick('Adhik', 'অধিক', 'अधिक')} $name' : name;
}

/// Festival notes are lunar month names ("Ashwin", "Adhik Ashwin") or
/// plain sentences.
String festivalNote(String note) {
  final adhik = note.startsWith('Adhik ');
  final i = lunarMonthNames.indexOf(adhik ? note.substring(6) : note);
  return i < 0 ? tr(note) : lunarMonthNameByIndex(i, adhik: adhik);
}
