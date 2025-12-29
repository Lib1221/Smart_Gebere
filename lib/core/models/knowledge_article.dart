/// Knowledge base article model for Ethiopian agricultural guides
class KnowledgeArticle {
  final String id;
  final String titleEn;
  final String titleAm;
  final String titleOm;
  final String contentEn;
  final String contentAm;
  final String contentOm;
  final ArticleCategory category;
  final List<String> tags;
  final String? imageUrl;
  final String? videoUrl;
  final int viewCount;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeArticle({
    required this.id,
    required this.titleEn,
    required this.titleAm,
    required this.titleOm,
    required this.contentEn,
    required this.contentAm,
    required this.contentOm,
    required this.category,
    required this.tags,
    this.imageUrl,
    this.videoUrl,
    this.viewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get title by language code
  String getTitle(String languageCode) {
    switch (languageCode) {
      case 'am':
        return titleAm.isNotEmpty ? titleAm : titleEn;
      case 'om':
        return titleOm.isNotEmpty ? titleOm : titleEn;
      default:
        return titleEn;
    }
  }

  /// Get content by language code
  String getContent(String languageCode) {
    switch (languageCode) {
      case 'am':
        return contentAm.isNotEmpty ? contentAm : contentEn;
      case 'om':
        return contentOm.isNotEmpty ? contentOm : contentEn;
      default:
        return contentEn;
    }
  }

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) {
    return KnowledgeArticle(
      id: _asString(json['id'], ''),
      titleEn: _asString(json['titleEn'] ?? json['title'], ''),
      titleAm: _asString(json['titleAm'], ''),
      titleOm: _asString(json['titleOm'], ''),
      contentEn: _asString(json['contentEn'] ?? json['content'], ''),
      contentAm: _asString(json['contentAm'], ''),
      contentOm: _asString(json['contentOm'], ''),
      category: ArticleCategory.fromString(_asString(json['category'], 'general')),
      tags: _asStringList(json['tags']),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      viewCount: _asInt(json['viewCount'], 0),
      isFeatured: _asBool(json['isFeatured'], false),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleAm': titleAm,
      'titleOm': titleOm,
      'contentEn': contentEn,
      'contentAm': contentAm,
      'contentOm': contentOm,
      'category': category.name,
      'tags': tags,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'viewCount': viewCount,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper converters
  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static int _asInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime _asDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

enum ArticleCategory {
  cropGuide('Crop Guide'),
  pestControl('Pest Control'),
  diseaseManagement('Disease Management'),
  soilHealth('Soil Health'),
  irrigation('Irrigation'),
  fertilizer('Fertilizer'),
  harvesting('Harvesting'),
  storage('Storage'),
  marketing('Marketing'),
  weather('Weather'),
  general('General');

  final String displayName;
  const ArticleCategory(this.displayName);

  static ArticleCategory fromString(String value) {
    return ArticleCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ArticleCategory.general,
    );
  }
}

/// Pre-defined Ethiopian crop guides
class EthiopianCropGuides {
  static List<KnowledgeArticle> getDefaultArticles() {
    return [
      KnowledgeArticle(
        id: 'teff-guide',
        titleEn: 'Complete Guide to Growing Teff',
        titleAm: 'ጤፍ ማብቀል ሙሉ መመሪያ',
        titleOm: 'Xaafii Biqilchuu Qajeelfama Guutuu',
        contentEn: '''
# Teff Growing Guide

## Introduction
Teff (Eragrostis tef) is Ethiopia's most important crop, used to make injera. It's highly nutritious, drought-tolerant, and gluten-free.

## Planting Season
- Main season: June to August (Meher)
- Short rains: March to May (Belg) in some areas

## Soil Requirements
- Prefers vertisol (black cotton soil) but adapts to many soil types
- pH 5.5-7.5
- Good drainage essential

## Land Preparation
1. Plow 3-4 times before planting
2. Break clods and level the field
3. Create proper drainage channels

## Seed Rate
- Broadcast: 25-30 kg/ha
- Row planting: 15-20 kg/ha

## Fertilizer Application
- DAP: 100 kg/ha at planting
- Urea: 50-75 kg/ha at tillering (30-35 days after planting)

## Weed Management
- First weeding: 20-25 days after emergence
- Second weeding: 40-45 days after emergence

## Harvesting
- Harvest when 90% of grains turn yellow-brown
- Cut, bundle, and stack for 5-7 days before threshing
- Expected yield: 1.5-2.5 tons/ha with good management

## Common Problems
- Lodging: Avoid excess nitrogen
- Rust: Use resistant varieties
- Birds: Guard during grain filling
''',
        contentAm: '''
# ጤፍ ማብቀል መመሪያ

## መግቢያ
ጤፍ የኢትዮጵያ ዋነኛ ሰብል ሲሆን ለእንጀራ ማምረት ይጠቀማል። በጣም አልሚ፣ ድርቅ መቋቋም የሚችል እና ግሉተን አልባ ነው።

## የመዝራት ወቅት
- ዋና ወቅት: ሰኔ እስከ ነሐሴ (መኸር)
- አጭር ዝናብ: መጋቢት እስከ ግንቦት (በልግ) በአንዳንድ አካባቢዎች

## የአፈር ፍላጎቶች
- ቨርቲሶል (ጥቁር ጥጥ አፈር) ይመርጣል ነገር ግን ለብዙ የአፈር ዓይነቶች ይስማማል
- pH 5.5-7.5
- ጥሩ ፍሳሽ አስፈላጊ ነው

## መሬት ማዘጋጀት
1. ከመዝራት በፊት 3-4 ጊዜ ማረስ
2. ክምር መስበር እና ማስተካከል
3. ተገቢ የፍሳሽ ቦይዎችን መፍጠር

## የዘር መጠን
- በመበተን: 25-30 ኪ.ግ/ሄ
- በመስመር: 15-20 ኪ.ግ/ሄ

## ማዳበሪያ ማድረግ
- DAP: 100 ኪ.ግ/ሄ በሚዘራበት ጊዜ
- ዩሪያ: 50-75 ኪ.ግ/ሄ በተክል ወቅት (ከተዘራ 30-35 ቀናት በኋላ)

## አረም ማስተዳደር
- የመጀመሪያ አረም ማስወገድ: ከብቅለት 20-25 ቀናት በኋላ
- ሁለተኛ አረም ማስወገድ: ከብቅለት 40-45 ቀናት በኋላ

## ማጨድ
- 90% እህል ወደ ቢጫ-ቡናማ ሲቀየር ማጨድ
- ቆርጠው ያስሩ እና ከመውቃት በፊት ለ5-7 ቀናት ያስቀምጡ
- የሚጠበቀው ምርት: በጥሩ አያያዝ 1.5-2.5 ቶን/ሄ

## የተለመዱ ችግሮች
- መውደቅ: ከመጠን ያለፈ ናይትሮጅን ያስወግዱ
- ዝገት: የሚቋቋሙ ዝርያዎችን ይጠቀሙ
- ወፎች: በእህል ሙሌት ወቅት ይጠብቁ
''',
        contentOm: '''
# Qajeelfama Xaafii Biqilchuu

## Seensa
Xaafiin (Eragrostis tef) midhaan Itoophiyaa isa baay'ee barbaachisaa ta'ee fi injeeraa dhahuu ta'a. Baay'ee soorataa, gogiinsa kan dandamatu fi giliitanii bilisaa dha.

## Yeroo Facaasuu
- Yeroo duraa: Waxabajjii hanga Hagayya (Meher)
- Rooba gabaabaa: Bitootessa hanga Caamsaa (Belg) naannoo tokko tokkotti

## Barbaachisummaa Biyyee
- Vartiisoolii (biyyee xiqqaa gurraacha) filata garuu gosa biyyee hedduuf ni mijata
- pH 5.5-7.5
- Dhangala'uu gaarii barbaachisaa dha

## Lafa Qopheessuu
1. Facaasuu dura si'a 3-4 qotuu
2. Kubbaa cabsuu fi sirreessuu
3. Karaa bishaan baasu sirrii uumuu

## Hanga Sanyii
- Facaasuu: 25-30 kg/hek
- Sararaan: 15-20 kg/hek

## Xaa'oo Naquu
- DAP: 100 kg/hek yeroo facaafamu
- Yuriiyaa: 50-75 kg/hek yeroo magariisummaa (guyyaa 30-35 facaasuu booda)

## Aramaa To'achuu
- Aramaa jalqabaa: Guyyaa 20-25 biqiluu booda
- Aramaa lammaffaa: Guyyaa 40-45 biqiluu booda

## Haammachuu
- Firii %90 yeroo magaalaa-burtukaanaa ta'u haammachuu
- Muruu, hidhuun guyyaa 5-7 tumuu dura kuusuu
- Oomisha eegamu: Qooda gaarii waliin 1.5-2.5 toona/hek
''',
        category: ArticleCategory.cropGuide,
        tags: ['teff', 'cereal', 'injera', 'ethiopia'],
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      KnowledgeArticle(
        id: 'fall-armyworm',
        titleEn: 'Managing Fall Armyworm in Maize',
        titleAm: 'በበቆሎ ውስጥ የመኸር ጦር ትል መቆጣጠር',
        titleOm: 'Boqqolloo Keessatti Raamoo Waraanaa Badhaasaa To\'achuu',
        contentEn: '''
# Fall Armyworm Management

## Identification
- Inverted Y-shape on head
- 4 black spots in square pattern on last body segment
- Moths are grayish-brown with white hindwings

## Damage Symptoms
- Ragged holes in leaves
- Sawdust-like frass near whorl
- Damaged tassels and ears
- Tunneling in stems

## Prevention
1. Early planting when rains start
2. Intercrop with beans or cowpeas
3. Plant push-pull companion crops
4. Remove and destroy crop residues

## Control Methods

### Cultural Control
- Handpicking in small fields
- Crush egg masses
- Apply ash or soil in whorls

### Biological Control
- Encourage natural predators (birds, ants, wasps)
- Neem-based products
- Bacillus thuringiensis (Bt)

### Chemical Control (last resort)
- Apply early morning or evening
- Target small larvae (1st-3rd instar)
- Rotate chemical classes

## Scouting
- Check 20-30 plants per field weekly
- Act when 5-10% of plants show damage
''',
        contentAm: '''
# የመኸር ጦር ትል አያያዝ

## ማወቅ
- በራስ ላይ የተገለበጠ Y ቅርጽ
- በመጨረሻው የሰውነት ክፍል ላይ 4 ጥቁር ነጠብጣቦች በካሬ ንድፍ
- ነጭ የኋላ ክንፎች ያሉት ግራጫማ-ቡናማ የእሳት ብራች

## የጉዳት ምልክቶች
- በቅጠሎች ላይ የተበጣጠሱ ቀዳዳዎች
- ከወርል አጠገብ የመጋዝ ብናኝ
- የተበላሹ ታስልስ እና ጆሮዎች
- በግንዶች ውስጥ መቆፈር

## መከላከል
1. ዝናብ ሲጀምር ቀድሞ መዝራት
2. ከባቄላ ወይም ከምስር ጋር ማደባለቅ
3. ማስወገጃ ማጋራት ሰብሎችን መትከል
4. የሰብል ቅሪቶችን ማስወገድ እና ማጥፋት

## የመቆጣጠሪያ ዘዴዎች

### ባህላዊ ቁጥጥር
- በትንንሽ እርሻዎች ውስጥ በእጅ መልቀም
- የእንቁላል ክምችቶችን መደምሰስ
- በወርል ውስጥ አመድ ወይም አፈር መጨመር

### ባዮሎጂካል ቁጥጥር
- ተፈጥሯዊ አዳኞችን ማበረታታት (ወፎች, ጉንዳን, ተርብ)
- በኒም ላይ የተመሰረቱ ምርቶች
- ባሲለስ ቱሪንጂንሲስ (Bt)

### ኬሚካል ቁጥጥር (የመጨረሻ አማራጭ)
- ማለዳ ወይም ምሽት ይተግብሩ
- ትንንሽ ላርቫዎችን ያነጣጥሩ
- የኬሚካል ክፍሎችን ያቀያይሩ
''',
        contentOm: '''
# Raamoo Waraanaa Badhaasaa To'achuu

## Adda Baasuu
- Mataa irratti bifti Y garagalchame
- Tuqaalee gurraacha 4 karaa iskuweerii irratti
- Billachi halluu diimaa-burtukaanaa koola duubaa adii qabu

## Mallattoolee Miidhaa
- Baala irratti holqa bittinnaa'e
- Naannoo whorloo irratti hookoo sawdustii fakkaatu
- Taasalii fi gurraa miidhame

## Ittisuu
1. Roobni yeroo jalqabu dafanii facaasuu
2. Baaqelaa ykn ater waliin makuu
3. Midhaan push-pull dhaabuu
4. Haftee midhaanii balleessuu

## Maloota To'annoo

### To'annoo Aadaa
- Dirree xiqqaa keessatti harkaan funaanuu
- Kuusaa hanqaaquu caccabsuu
- Daara ykn biyyee whorloo keessa naquu

### To'annoo Baayolojikaalaa
- Adamsituu uumamaa jajjabeessuu
- Oomishaalee neem irratti hundaa'an
- Bacillus thuringiensis (Bt)

### To'annoo Keemikaalaa (filannoo dhumaa)
- Ganama ykn galgala fayyadamuu
- Raamoo xixiqqaa irratti xiyyeeffachuu
''',
        category: ArticleCategory.pestControl,
        tags: ['fall armyworm', 'maize', 'pest', 'corn'],
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      KnowledgeArticle(
        id: 'soil-fertility',
        titleEn: 'Improving Soil Fertility Naturally',
        titleAm: 'የአፈር ለምነትን በተፈጥሮ ማሻሻል',
        titleOm: 'Uumamaan Jiraatummaa Biyyee Fooyyessuu',
        contentEn: '''
# Natural Soil Fertility Improvement

## Importance of Soil Health
Healthy soil is the foundation of productive farming. Poor soil leads to poor yields, even with expensive inputs.

## Organic Matter
### Benefits
- Improves water retention
- Provides nutrients slowly
- Supports beneficial organisms
- Improves soil structure

### Sources
1. **Compost**: Decomposed plant materials and manure
2. **Green manure**: Legumes plowed under
3. **Crop residues**: Stalks, leaves left on field
4. **Animal manure**: Well-rotted (2-3 months old)

## Crop Rotation
- Rotate cereals with legumes
- Helps break pest cycles
- Legumes fix nitrogen naturally

### Example Rotation
Year 1: Maize or Sorghum
Year 2: Beans or Chickpeas
Year 3: Teff or Wheat
Year 4: Fallow with legume cover

## Cover Crops
- Plant during off-season
- Prevents erosion
- Adds organic matter
- Examples: Vetch, Clover, Cowpea

## Avoiding Soil Degradation
- Minimize tillage
- Maintain ground cover
- Build terraces on slopes
- Plant trees as windbreaks

## Testing Your Soil
- Observe plant health
- Check for earthworms (sign of healthy soil)
- Professional testing available at regional offices
''',
        contentAm: '''
# የአፈር ለምነትን በተፈጥሮ ማሻሻል

## የአፈር ጤና አስፈላጊነት
ጤናማ አፈር ለምርታማ እርሻ መሰረት ነው። ደካማ አፈር ውድ ግብዓት ቢኖርም እንኳን ወደ ደካማ ምርት ይመራል።

## ኦርጋኒክ ቁስ
### ጥቅሞች
- የውሃ ማቆየትን ያሻሽላል
- ቀስ በቀስ ንጥረ ነገሮችን ያቀርባል
- ጠቃሚ ፍጥረታትን ይደግፋል
- የአፈር መዋቅርን ያሻሽላል

### ምንጮች
1. **ኮምፖስት**: የበሰበሰ የእፅዋት ቁሳቁስ እና ፍግ
2. **አረንጓዴ ፍግ**: በአፈር ውስጥ የተቀላቀሉ ጥራጥሬዎች
3. **የሰብል ቅሪቶች**: ግንድ, ቅጠሎች በእርሻ ላይ የቀሩ
4. **የእንስሳት ፍግ**: በደንብ የበሰበሰ (2-3 ወር)

## የሰብል ሽግግር
- ጥራጥሬዎችን ከእህሎች ጋር ቀያይር
- የተባይ ዑደቶችን ለማቋረጥ ይረዳል
- ጥራጥሬዎች ናይትሮጅንን በተፈጥሮ ያስተካክላሉ

### የሽግግር ምሳሌ
ዓመት 1: በቆሎ ወይም ማሽላ
ዓመት 2: ባቄላ ወይም ሽምብራ
ዓመት 3: ጤፍ ወይም ስንዴ
ዓመት 4: በጥራጥሬ መሸፈኛ ማረፍ

## መሸፈኛ ሰብሎች
- በአነስተኛ ወቅት ይትከሉ
- መሸርሸርን ይከላከላል
- ኦርጋኒክ ቁስ ይጨምራል
- ምሳሌዎች: ቬች, ክሎቨር, ማስር
''',
        contentOm: '''
# Uumamaan Jiraatummaa Biyyee Fooyyessuu

## Barbaachisummaa Fayyummaa Biyyee
Biyyeen fayyaa qabu bu'ura qonnaa oomishaa ti. Biyyeen dadhabaan galii xinnaa fida, galii mi'aawaa waliin iyyuu.

## Wanta Orgaanikii
### Bu'aalee
- Bishaanii qabachuu fooyyessa
- Soorata suuta kenna
- Lubbu-qabeeyyii fayyadamoo deggera
- Sirna biyyee fooyyessa

### Madda
1. **Koomppostii**: Wantoota biqiltuu fi kosii tortoran
2. **Kosii magariisa**: Midhaan agadaa biyyee keessa qotaman
3. **Haftee midhaanii**: Qamphee, baala lafa irratti hafan
4. **Kosii beeyladaa**: Sirriitti tortore (ji'a 2-3)

## Jijjiirraa Midhaanii
- Gosa midhaanii midhaan agadaa waliin jijjiiri
- Marsaa dhukkubaa cabsuuf gargaara
- Midhaan agadaa naaytiroojinii uumamaan sirreessu

### Fakkeenya Jijjiirraa
Waggaa 1: Boqqolloo ykn Mishingaa
Waggaa 2: Baaqela ykn Shumbura
Waggaa 3: Xaafii ykn Qamadii
Waggaa 4: Midhaan agadaan uwwisuu
''',
        category: ArticleCategory.soilHealth,
        tags: ['soil', 'fertility', 'organic', 'compost'],
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

