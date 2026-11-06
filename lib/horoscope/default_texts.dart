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

// ---------------------------------------------------------------- Bengali

const defaultGocharBn = <HoroscopeText>[
  HoroscopeText(
    'নিজের রাশিতে চন্দ্র',
    'আজ অনুভূতি প্রবল থাকবে এবং নিজের প্রয়োজনের দিকে বেশি নজর যাবে। '
        'স্বাস্থ্যের যত্ন নিন, সময়মতো খাওয়া-দাওয়া করুন এবং একটু বিশ্রাম নিন। '
        'ব্যক্তিগত কোনো কাজ শুরু করার জন্য ভালো দিন, তর্কের জন্য নয়।',
  ),
  HoroscopeText(
    'অর্থ ও পরিবারের দিকে মন',
    'সঞ্চয়, খাবার ও পারিবারিক বিষয়ে মন যাবে। খরচের আগে ভাবুন এবং কথা '
        'বলার সময় সাবধান থাকুন, আজ বাক্য সংবেদনশীল। পরিবারের সঙ্গে খাওয়া বা '
        'ফোনে কথা আনন্দ দেবে।',
  ),
  HoroscopeText(
    'সাহস ও যোগাযোগ',
    'উদ্যম ও আত্মবিশ্বাস বেশি থাকবে। যে ফোন, বার্তা বা ছোট যাত্রা পিছিয়ে '
        'রেখেছেন, আজ সেরে ফেলুন। ভাই-বোন ও প্রতিবেশীরা সাহায্য করতে পারেন।',
  ),
  HoroscopeText(
    'ঘর ও মনের শান্তি',
    'মন অস্থির বা আরামের অভাব বোধ হতে পারে। বাড়ির কাছাকাছি থাকুন, '
        'পরিবারে তর্ক এড়িয়ে চলুন এবং জমি-বাড়ি বা গাড়ির সিদ্ধান্ত পিছিয়ে দিন। '
        'মায়ের সঙ্গে বা শান্ত জায়গায় সময় কাটালে ভালো লাগবে।',
  ),
  HoroscopeText(
    'পড়াশোনা, সন্তান ও সৃজনশীলতা',
    'মন সক্রিয় থাকলেও এদিক-ওদিক যেতে পারে। পড়াশোনা, সৃজনশীল কাজ ও '
        'সন্তানের সঙ্গে সময় কাটানোর জন্য ভালো, তবে ফাটকা ও টাকা নিয়ে তাড়াহুড়ো '
        'সিদ্ধান্ত এড়িয়ে চলুন। প্রতিশ্রুতি ছোট ও বাস্তবসম্মত রাখুন।',
  ),
  HoroscopeText(
    'বাধার উপর জয়',
    'জমে থাকা কাজ শেষ করা, সমস্যার মোকাবিলা ও প্রতিযোগিতার জন্য খুব ভালো '
        'দিন। স্বাস্থ্যচর্চা ও অন্যের সেবায় ভালো ফল মিলবে। পাওনা টাকা বা ঋণের '
        'বিষয় এগোতে পারে।',
  ),
  HoroscopeText(
    'সম্পর্ক ও মানুষজন',
    'সম্পর্ক, সাক্ষাৎ ও চুক্তির জন্য শুভ। জীবনসঙ্গী বা ব্যবসার অংশীদার পাশে '
        'থাকবেন। সামাজিক পরিকল্পনা, একসঙ্গে ভ্রমণ ও সৎ উদ্দেশ্যে করা চুক্তির '
        'জন্য ভালো।',
  ),
  HoroscopeText(
    'চন্দ্রাষ্টম: ধীরে চলুন',
    'চন্দ্র আপনার রাশি থেকে অষ্টমে, প্রথাগতভাবে সতর্ক থাকার দিন। বড় '
        'সিদ্ধান্ত, ঝুঁকিপূর্ণ যাত্রা ও নতুন দায়িত্ব এড়িয়ে চলুন। বিশ্রাম নিন, '
        'সাবধানে গাড়ি চালান ও মেজাজ ঠান্ডা রাখুন। প্রায় দুই দিনে এই সময় কেটে যাবে।',
  ),
  HoroscopeText(
    'গুরুজন, ভক্তি ও ভাগ্য',
    'শিক্ষক, গুরুজন ও ধর্মকর্মের মাধ্যমে আশীর্বাদ আসবে। প্রার্থনা, শেখা ও '
        'দূরযাত্রার পরিকল্পনার জন্য ভালো। বৈষয়িক বিষয়ে ফল মিশ্র, তাই ধৈর্য ধরুন।',
  ),
  HoroscopeText(
    'কাজ ও স্বীকৃতি',
    'কর্মক্ষেত্রে আপনার পরিশ্রম নজরে আসবে। ঊর্ধ্বতনদের সঙ্গে বৈঠক, '
        'গুরুত্বপূর্ণ কাজ ও দায়িত্ব নেওয়ার জন্য ভালো। আত্মবিশ্বাসের সঙ্গে কাজ '
        'করুন এবং যা শুরু করবেন তা শেষ করুন।',
  ),
  HoroscopeText(
    'লাভ ও সুখবর',
    'এই চক্রের সেরা দিনগুলির একটি। আয়, বন্ধুদের সাহায্য ও মনোবাসনা পূরণের '
        'সম্ভাবনা। যা দরকার চেয়ে নিন এবং বন্ধুদের সঙ্গে আনন্দ করুন।',
  ),
  HoroscopeText(
    'বিশ্রাম ও ছেড়ে দেওয়া',
    'খরচ ও ক্লান্তি বাড়তে পারে। খরচে লাগাম দিন, ভালো করে ঘুমোন এবং '
        'গুরুত্বপূর্ণ কাজ শুরু করবেন না। ধ্যান, দান ও পুরনো কাজ চুপচাপ শেষ '
        'করার জন্য ভালো দিন।',
  ),
];

const defaultTaraBn = <HoroscopeText>[
  HoroscopeText(
    'জন্ম তারা',
    'আজকের নক্ষত্র আপনার জন্ম নক্ষত্র। সবকিছু সহজ রাখুন এবং শরীর-মনের যত্ন নিন।',
  ),
  HoroscopeText(
    'সম্পৎ তারা',
    'ধনের তারা। অর্থ, কেনাকাটা ও নতুন উদ্যোগের জন্য শুভ।',
  ),
  HoroscopeText(
    'বিপৎ তারা',
    'বাধার তারা। ছোটখাটো দেরি হতে পারে; পরিকল্পনা আবার দেখে নিন এবং নতুন '
        'উদ্যোগ এড়িয়ে চলুন।',
  ),
  HoroscopeText(
    'ক্ষেম তারা',
    'মঙ্গলের তারা। স্বাস্থ্য, আরাম ও ধীর-স্থির অগ্রগতির জন্য ভালো।',
  ),
  HoroscopeText(
    'প্রত্যক তারা',
    'বিরোধের তারা। লোকে বিরোধিতা করতে পারে; ধৈর্য রাখুন এবং সংঘাত এড়িয়ে চলুন।',
  ),
  HoroscopeText(
    'সাধক তারা',
    'সাফল্যের তারা। প্রচেষ্টা সফল হবে; লক্ষ্য পূরণের ভালো দিন।',
  ),
  HoroscopeText(
    'নৈধন তারা',
    'কঠিন তারা। ঝুঁকি নেবেন না, সাবধানে যাতায়াত করুন এবং গুরুত্বপূর্ণ '
        'সিদ্ধান্ত পিছিয়ে দিন।',
  ),
  HoroscopeText(
    'মিত্র তারা',
    'বন্ধুত্বপূর্ণ তারা। বন্ধুদের কাছ থেকে সাহায্য আসবে; সহযোগিতার জন্য ভালো।',
  ),
  HoroscopeText(
    'পরম মিত্র তারা',
    'অত্যন্ত বন্ধুত্বপূর্ণ তারা। আজ সহজেই সহায়তা ও ভালো ফল মিলবে।',
  ),
];

// ------------------------------------------------------------------ Hindi

const defaultGocharHi = <HoroscopeText>[
  HoroscopeText(
    'अपनी राशि में चंद्रमा',
    'आज भावनाएँ प्रबल रहेंगी और आप अपनी ज़रूरतों पर ज़्यादा ध्यान देंगे। '
        'सेहत का ख़याल रखें, समय पर भोजन करें और थोड़ा आराम करें। कोई निजी '
        'काम शुरू करने के लिए अच्छा दिन है, बहस के लिए नहीं।',
  ),
  HoroscopeText(
    'धन और परिवार पर ध्यान',
    'बचत, भोजन और पारिवारिक मामलों पर ध्यान जाएगा। ख़र्च से पहले सोचें और '
        'शब्द सोच-समझकर बोलें, आज वाणी संवेदनशील है। परिवार के साथ भोजन या '
        'बातचीत से ख़ुशी मिलेगी।',
  ),
  HoroscopeText(
    'साहस और संवाद',
    'ऊर्जा और आत्मविश्वास ऊँचा रहेगा। जो फ़ोन, संदेश या छोटी यात्रा टाल रहे '
        'थे, आज कर लें। भाई-बहन और पड़ोसी मददगार हो सकते हैं।',
  ),
  HoroscopeText(
    'घर और मन की शांति',
    'बेचैनी या आराम की कमी महसूस हो सकती है। घर के पास रहें, परिवार में बहस '
        'से बचें और संपत्ति या वाहन के निर्णय टाल दें। माँ के साथ या किसी शांत '
        'जगह समय बिताना अच्छा रहेगा।',
  ),
  HoroscopeText(
    'पढ़ाई, संतान और रचनात्मकता',
    'मन सक्रिय रहेगा पर भटक सकता है। पढ़ाई, रचनात्मक काम और बच्चों के साथ '
        'समय के लिए अच्छा, पर सट्टे और पैसों के जल्दबाज़ी वाले फ़ैसलों से बचें। '
        'वादे छोटे और व्यावहारिक रखें।',
  ),
  HoroscopeText(
    'बाधाओं पर विजय',
    'अटके काम निपटाने, समस्याओं से निपटने और प्रतियोगिता के लिए बहुत अच्छा '
        'दिन। सेहत की दिनचर्या और दूसरों की सेवा से अच्छे परिणाम मिलेंगे। बकाया '
        'या ऋण के मामले आगे बढ़ सकते हैं।',
  ),
  HoroscopeText(
    'साझेदारी और लोग',
    'रिश्तों, मुलाक़ातों और सौदों के लिए शुभ। जीवनसाथी या व्यावसायिक साझेदार '
        'का साथ मिलेगा। सामाजिक योजनाओं, साथ यात्रा और ईमानदारी से किए गए '
        'समझौतों के लिए अच्छा।',
  ),
  HoroscopeText(
    'चंद्राष्टम: धीरे चलें',
    'चंद्रमा आपकी राशि से आठवें भाव में है, यह परंपरागत रूप से सावधानी का '
        'दिन है। बड़े फ़ैसले, जोखिम भरी यात्रा और नई ज़िम्मेदारियों से बचें। आराम '
        'करें, सावधानी से वाहन चलाएँ और ग़ुस्से पर क़ाबू रखें। लगभग दो दिन में यह '
        'समय बीत जाएगा।',
  ),
  HoroscopeText(
    'गुरुजन, आस्था और भाग्य',
    'शिक्षकों, बड़ों और धार्मिक कार्यों से आशीर्वाद मिलेगा। प्रार्थना, अध्ययन '
        'और लंबी यात्रा की योजना के लिए अच्छा। भौतिक मामलों में परिणाम मिले-जुले '
        'रहेंगे, धैर्य रखें।',
  ),
  HoroscopeText(
    'काम और सम्मान',
    'कार्यस्थल पर आपकी मेहनत पर ध्यान जाएगा। वरिष्ठों से मुलाक़ात, महत्वपूर्ण '
        'कामों और ज़िम्मेदारी लेने के लिए अच्छा। आत्मविश्वास से काम करें और जो '
        'शुरू करें उसे पूरा करें।',
  ),
  HoroscopeText(
    'लाभ और शुभ समाचार',
    'इस चक्र के सबसे अच्छे दिनों में से एक। आय, मित्रों की मदद और '
        'इच्छापूर्ति की संभावना। जो चाहिए वह माँगें और मित्रों के साथ आनंद लें।',
  ),
  HoroscopeText(
    'विश्राम और त्याग',
    'ख़र्च और थकान बढ़ सकती है। ख़र्च पर लगाम रखें, अच्छी नींद लें और '
        'महत्वपूर्ण काम शुरू न करें। ध्यान, दान और पुराने काम चुपचाप पूरे करने '
        'के लिए अच्छा दिन।',
  ),
];

const defaultTaraHi = <HoroscopeText>[
  HoroscopeText(
    'जन्म तारा',
    'आज का नक्षत्र आपका जन्म नक्षत्र है। चीज़ें सरल रखें और तन-मन का ध्यान रखें।',
  ),
  HoroscopeText(
    'संपत तारा',
    'धन का तारा। पैसों के मामलों, ख़रीदारी और नए प्रयासों के लिए शुभ।',
  ),
  HoroscopeText(
    'विपत तारा',
    'बाधाओं का तारा। छोटी-मोटी देरी हो सकती है; योजनाएँ दोबारा जाँचें और नए '
        'काम शुरू न करें।',
  ),
  HoroscopeText(
    'क्षेम तारा',
    'कल्याण का तारा। सेहत, आराम और स्थिर प्रगति के लिए अच्छा।',
  ),
  HoroscopeText(
    'प्रत्यक तारा',
    'विरोध का तारा। लोग विरोध कर सकते हैं; धैर्य रखें और टकराव से बचें।',
  ),
  HoroscopeText(
    'साधक तारा',
    'सफलता का तारा। प्रयास सफल होंगे; लक्ष्य पूरे करने के लिए अच्छा दिन।',
  ),
  HoroscopeText(
    'नैधन तारा',
    'कठिन तारा। जोखिम न लें, सावधानी से यात्रा करें और महत्वपूर्ण निर्णय टाल दें।',
  ),
  HoroscopeText(
    'मित्र तारा',
    'मित्रवत तारा। मित्रों से मदद मिलेगी; सहयोग के लिए अच्छा।',
  ),
  HoroscopeText(
    'परम मित्र तारा',
    'अत्यंत मित्रवत तारा। आज सहयोग और अच्छे परिणाम आसानी से मिलेंगे।',
  ),
];

/// Built-in texts for a language code ('en', 'bn', 'hi').
(List<HoroscopeText>, List<HoroscopeText>) defaultTextsFor(String lang) =>
    switch (lang) {
      'bn' => (defaultGocharBn, defaultTaraBn),
      'hi' => (defaultGocharHi, defaultTaraHi),
      _ => (defaultGochar, defaultTara),
    };
