import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';

class PlantRepository {
  final _db = Supabase.instance.client;

  Future<PlantModel?> getById(String id) async {
    try {
      final row = await _db
          .from('plants')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return PlantModel.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<PlantModel>> getAll() async {
    try {
      final rows = await _db
          .from('plants')
          .select()
          .order('common_name');
      final list = (rows as List).map((r) => PlantModel.fromJson(r)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _indianSeedPlants;
  }

  Future<PlantModel?> getPlantOfDay() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final row = await _db
          .from('plants')
          .select()
          .eq('potd_date', today)
          .maybeSingle();
      if (row != null) return PlantModel.fromJson(row);

      final rows = await _db
          .from('plants')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List).isNotEmpty) return PlantModel.fromJson(rows.first);
    } catch (_) {}
    // Fallback: rotate seed plants by day-of-year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _indianSeedPlants[dayOfYear % _indianSeedPlants.length];
  }

  Future<List<PlantModel>> search(String query) async {
    try {
      final rows = await _db
          .from('plants')
          .select()
          .or('common_name.ilike.%$query%,scientific_name.ilike.%$query%,family.ilike.%$query%')
          .order('common_name')
          .limit(50);
      return (rows as List).map((r) => PlantModel.fromJson(r)).toList();
    } catch (_) {
      final q = query.toLowerCase();
      return _indianSeedPlants
          .where((p) =>
              p.commonName.toLowerCase().contains(q) ||
              p.scientificName.toLowerCase().contains(q))
          .toList();
    }
  }
}

// ─── 20 Indian seed plants ─────────────────────────────────────────────────────

final _indianSeedPlants = <PlantModel>[
  PlantModel(
    id: 'seed_01',
    commonName: 'Tulsi',
    scientificName: 'Ocimum tenuiflorum',
    family: 'Lamiaceae',
    emoji: '🌿',
    description: 'Holy Basil (Tulsi) is a sacred plant in Hindu tradition, revered for its medicinal and spiritual significance. It thrives in tropical climates and is found in most Indian households.',
    confidence: 1.0,
    regionPills: ['India', 'South Asia'],
    habitat: 'Tropical gardens',
    height: '30–60 cm',
    bloomSeason: 'Year-round',
    climate: 'Tropical',
    careData: CareData(soil: 'Well-draining loam', sunlight: 'Full sun', water: 'Regular', ph: '6.0–7.5', temperature: '20–35°C'),
    uses: UsesData(medicinal: 'Treats colds, fever, stress and respiratory issues', culinary: 'Used in teas and Ayurvedic recipes', cosmetic: 'Skin and hair care preparations'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Sacred to Vishnu; worshipped daily in Indian homes.',
    funFacts: ['Considered the "Queen of Herbs" in Ayurveda', 'Its essential oil has powerful antimicrobial properties'],
    distributionCountries: ['India', 'Nepal', 'Sri Lanka', 'Bangladesh'],
  ),
  PlantModel(
    id: 'seed_02',
    commonName: 'Neem',
    scientificName: 'Azadirachta indica',
    family: 'Meliaceae',
    emoji: '🌳',
    description: 'Neem is one of India\'s most valuable medicinal trees, often called the "village pharmacy". Every part of the tree has therapeutic use, from bark to leaves to seeds.',
    confidence: 1.0,
    regionPills: ['India', 'Africa', 'SE Asia'],
    habitat: 'Dry tropical forests',
    height: '15–20 m',
    bloomSeason: 'Feb–May',
    climate: 'Tropical / Semi-arid',
    careData: CareData(soil: 'Sandy loam', sunlight: 'Full sun', water: 'Low – drought tolerant', ph: '6.2–7.0', temperature: '21–32°C'),
    uses: UsesData(medicinal: 'Antibacterial, antifungal; used in Ayurveda for skin diseases', cosmetic: 'Neem oil for hair and skin care', industrial: 'Natural pesticide and fertiliser'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Considered a divine tree; used in religious ceremonies across India.',
    funFacts: ['Called "Sarva Roga Nivarini" (cure of all ailments)', 'Neem twigs are used as natural toothbrushes'],
    distributionCountries: ['India', 'Pakistan', 'Bangladesh', 'Myanmar', 'Kenya'],
  ),
  PlantModel(
    id: 'seed_03',
    commonName: 'Ashwagandha',
    scientificName: 'Withania somnifera',
    family: 'Solanaceae',
    emoji: '🌱',
    description: 'Ashwagandha is a powerful adaptogen used extensively in Ayurvedic medicine. Its root is used to reduce stress, boost energy, and improve concentration.',
    confidence: 1.0,
    regionPills: ['India', 'North Africa', 'Mediterranean'],
    habitat: 'Dry shrubland',
    height: '35–75 cm',
    bloomSeason: 'June–July',
    climate: 'Arid to semi-arid',
    careData: CareData(soil: 'Sandy, well-draining', sunlight: 'Full sun', water: 'Low', ph: '7.5–8.0', temperature: '25–35°C'),
    uses: UsesData(medicinal: 'Adaptogen for stress, fatigue and cognitive function'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Core herb in Ayurveda for over 3,000 years.',
    funFacts: ['Name means "smell of horse" referring to its strength-giving properties', 'Classified as a Rasayana (rejuvenating) herb'],
    distributionCountries: ['India', 'Nepal', 'Egypt', 'Morocco'],
  ),
  PlantModel(
    id: 'seed_04',
    commonName: 'Banana',
    scientificName: 'Musa paradisiaca',
    family: 'Musaceae',
    emoji: '🍌',
    description: 'The banana plant is one of the oldest and most widely cultivated plants in India. Every part — fruit, flower, stem, and leaf — is used in Indian cuisine and culture.',
    confidence: 1.0,
    regionPills: ['India', 'Tropical worldwide'],
    habitat: 'Tropical lowlands',
    height: '3–9 m',
    bloomSeason: 'Year-round',
    climate: 'Tropical humid',
    careData: CareData(soil: 'Rich, well-draining loam', sunlight: 'Full sun', water: 'High', ph: '5.5–7.0', temperature: '26–32°C'),
    uses: UsesData(medicinal: 'Rich in potassium; aids digestion and heart health', culinary: 'Fruit, flower and stem used in Indian cooking'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Banana leaves are used as sacred serving plates in South Indian rituals.',
    funFacts: ['India is the world\'s largest banana producer', 'The banana plant is technically a giant herb, not a tree'],
    distributionCountries: ['India', 'Philippines', 'Brazil', 'Ecuador'],
  ),
  PlantModel(
    id: 'seed_05',
    commonName: 'Jasmine',
    scientificName: 'Jasminum sambac',
    family: 'Oleaceae',
    emoji: '🌸',
    description: 'Mogra or Arabian Jasmine is India\'s most beloved flowering plant, worn in hair and used in garlands. Its intoxicating fragrance is iconic across South and Southeast Asia.',
    confidence: 1.0,
    regionPills: ['India', 'SE Asia'],
    habitat: 'Gardens, hedgerows',
    height: '0.5–3 m (shrub/vine)',
    bloomSeason: 'Mar–Oct',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Rich, well-draining', sunlight: 'Full sun to partial shade', water: 'Moderate', ph: '6.0–7.5', temperature: '15–35°C'),
    uses: UsesData(medicinal: 'Used for anxiety, headaches and skin conditions', cosmetic: 'Jasmine oil in perfumes and hair oils', culinary: 'Jasmine tea'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'National flower of the Philippines; sacred in Hindu and Buddhist worship.',
    funFacts: ['Flowers are harvested only at night when fragrance peaks', 'One kilogram of jasmine absolute requires 8 million flowers'],
    distributionCountries: ['India', 'Philippines', 'Thailand', 'Indonesia'],
  ),
  PlantModel(
    id: 'seed_06',
    commonName: 'Coconut Palm',
    scientificName: 'Cocos nucifera',
    family: 'Arecaceae',
    emoji: '🥥',
    description: 'The coconut palm is called the "Tree of Life" in India. It is indispensable to coastal Indian cooking, medicine, and crafts, with over 100 documented uses.',
    confidence: 1.0,
    regionPills: ['Coastal India', 'Tropical worldwide'],
    habitat: 'Coastal lowlands',
    height: '20–30 m',
    bloomSeason: 'Year-round',
    climate: 'Tropical coastal',
    careData: CareData(soil: 'Sandy loam, well-draining', sunlight: 'Full sun', water: 'Moderate to high', ph: '5.5–7.0', temperature: '27–32°C'),
    uses: UsesData(medicinal: 'Coconut oil for skin, hair, and digestive health', culinary: 'Coconut milk, oil, and flesh core to South Indian cuisine', industrial: 'Coir for rope, mats, and fuel'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Integral to Kerala culture; used in every major Hindu ritual.',
    funFacts: ['A coconut palm can produce up to 200 coconuts per year', 'Coconut water is nearly isotonic to human blood plasma'],
    distributionCountries: ['India', 'Sri Lanka', 'Philippines', 'Brazil', 'Indonesia'],
  ),
  PlantModel(
    id: 'seed_07',
    commonName: 'Marigold',
    scientificName: 'Tagetes erecta',
    family: 'Asteraceae',
    emoji: '🌼',
    description: 'Indian Marigold (Genda) is the most widely used flower in India for garlands, festivals, and religious offerings. Its vivid orange-yellow blooms are a symbol of auspiciousness.',
    confidence: 1.0,
    regionPills: ['India', 'Mexico', 'Worldwide'],
    habitat: 'Gardens, fields',
    height: '30–90 cm',
    bloomSeason: 'Oct–Mar',
    climate: 'Subtropical to temperate',
    careData: CareData(soil: 'Fertile, well-draining', sunlight: 'Full sun', water: 'Moderate', ph: '6.0–7.5', temperature: '18–28°C'),
    uses: UsesData(medicinal: 'Anti-inflammatory; used for skin wounds and conjunctivitis', culinary: 'Edible petals used in salads and teas', cosmetic: 'Natural dye for cosmetics and textiles'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Most popular flower for Hindu, Muslim, and Sikh religious ceremonies.',
    funFacts: ['India produces over 60% of the world\'s marigold crop', 'Natural pest repellent — companion planted with vegetables'],
    distributionCountries: ['India', 'Mexico', 'China', 'USA'],
  ),
  PlantModel(
    id: 'seed_08',
    commonName: 'Mango',
    scientificName: 'Mangifera indica',
    family: 'Anacardiaceae',
    emoji: '🥭',
    description: 'The mango is India\'s national fruit and is deeply woven into Indian culture, cuisine, and mythology. India is home to over 1,000 mango cultivars.',
    confidence: 1.0,
    regionPills: ['India', 'South Asia', 'Tropical worldwide'],
    habitat: 'Tropical forests and orchards',
    height: '10–40 m',
    bloomSeason: 'Dec–Mar (fruit: Apr–Jun)',
    climate: 'Tropical and subtropical',
    careData: CareData(soil: 'Deep, well-draining loam', sunlight: 'Full sun', water: 'Moderate; drought-tolerant once established', ph: '5.5–7.5', temperature: '24–30°C'),
    uses: UsesData(medicinal: 'Rich in vitamin C and antioxidants; aids digestion', culinary: 'Eaten fresh, pickled (aam achar), juiced, and in curries'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'National fruit of India; mango leaves are used in Hindu rituals and wedding decorations.',
    funFacts: ['India produces 40% of the world\'s mangoes', 'The Alphonso mango from Maharashtra is called the "King of Mangoes"'],
    distributionCountries: ['India', 'China', 'Thailand', 'Pakistan', 'Mexico'],
  ),
  PlantModel(
    id: 'seed_09',
    commonName: 'Lotus',
    scientificName: 'Nelumbo nucifera',
    family: 'Nelumbonaceae',
    emoji: '🪷',
    description: 'The sacred lotus is India\'s national flower, symbolising purity, enlightenment, and rebirth. It grows in muddy ponds yet emerges spotless and beautiful.',
    confidence: 1.0,
    regionPills: ['India', 'SE Asia', 'Australia'],
    habitat: 'Ponds, lakes, wetlands',
    height: '60–150 cm above water',
    bloomSeason: 'Jun–Sep',
    climate: 'Tropical to warm temperate',
    careData: CareData(soil: 'Clay-rich submerged soil', sunlight: 'Full sun', water: 'Aquatic – always submerged', ph: '6.5–8.0', temperature: '23–35°C'),
    uses: UsesData(medicinal: 'Seeds and rhizomes treat diarrhoea and bleeding disorders', culinary: 'Lotus seeds, root, and stem eaten across Asia'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'National flower of India; central symbol in Buddhism and Hinduism.',
    funFacts: ['Lotus leaves are self-cleaning due to their microscopic surface texture', 'Seeds can remain viable for over 1,000 years'],
    distributionCountries: ['India', 'China', 'Japan', 'Vietnam', 'Australia'],
  ),
  PlantModel(
    id: 'seed_10',
    commonName: 'Amla',
    scientificName: 'Phyllanthus emblica',
    family: 'Phyllanthaceae',
    emoji: '🍈',
    description: 'Indian Gooseberry (Amla) is one of the richest natural sources of Vitamin C and a cornerstone of Ayurvedic medicine. Its tart green berries are used in hundreds of formulations.',
    confidence: 1.0,
    regionPills: ['India', 'South Asia', 'SE Asia'],
    habitat: 'Dry deciduous forests',
    height: '8–18 m',
    bloomSeason: 'Feb–May (fruit: Oct–Feb)',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Sandy loam to clay loam', sunlight: 'Full sun', water: 'Moderate; drought-tolerant', ph: '6.0–8.0', temperature: '10–40°C'),
    uses: UsesData(medicinal: 'Boosts immunity, improves digestion, and strengthens hair', culinary: 'Eaten raw, pickled, or as amla candy and juice', cosmetic: 'Amla oil is widely used for hair strengthening'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Sacred in Hinduism; the tree is worshipped during Amalaki Ekadashi.',
    funFacts: ['Contains 20× more Vitamin C than an orange', 'A key ingredient in Chyawanprash, India\'s most famous herbal tonic'],
    distributionCountries: ['India', 'Sri Lanka', 'Myanmar', 'China', 'Malaysia'],
  ),
  PlantModel(
    id: 'seed_11',
    commonName: 'Hibiscus',
    scientificName: 'Hibiscus rosa-sinensis',
    family: 'Malvaceae',
    emoji: '🌺',
    description: 'The China Rose (Hibiscus) is beloved across India for its large, showy flowers. It is a common sight in temple gardens and widely used in Ayurvedic hair-care.',
    confidence: 1.0,
    regionPills: ['India', 'Tropical Asia'],
    habitat: 'Tropical gardens',
    height: '1–5 m',
    bloomSeason: 'Year-round',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Rich, well-draining', sunlight: 'Full sun to partial shade', water: 'Regular', ph: '6.0–7.5', temperature: '16–32°C'),
    uses: UsesData(medicinal: 'Treats hair loss, high blood pressure, and inflammation', culinary: 'Hibiscus tea and jams', cosmetic: 'Hibiscus oil and hair masks'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Offered to Goddess Kali; worn in hair in South Indian tradition.',
    funFacts: ['Over 200 species of Hibiscus exist globally', 'Hibiscus tea is rich in anthocyanins with antioxidant properties'],
    distributionCountries: ['India', 'China', 'Malaysia', 'Thailand'],
  ),
  PlantModel(
    id: 'seed_12',
    commonName: 'Aloe Vera',
    scientificName: 'Aloe barbadensis miller',
    family: 'Asphodelaceae',
    emoji: '🌵',
    description: 'Aloe Vera is a succulent plant used worldwide for its thick gel-filled leaves. It has been used in Indian medicine for over 6,000 years for burns, skin care, and digestion.',
    confidence: 1.0,
    regionPills: ['India', 'Africa', 'Mediterranean'],
    habitat: 'Dry, rocky areas and gardens',
    height: '60–100 cm',
    bloomSeason: 'Feb–Jun',
    climate: 'Arid to tropical',
    careData: CareData(soil: 'Sandy, well-draining', sunlight: 'Full sun to partial shade', water: 'Low – drought tolerant', ph: '7.0–8.5', temperature: '13–27°C'),
    uses: UsesData(medicinal: 'Treats burns, wounds, and digestive problems', cosmetic: 'Widely used in moisturisers, hair gels, and sunscreens', culinary: 'Aloe juice consumed as a health drink'),
    iucnStatus: 'Least Concern',
    funFacts: ['The gel is 99% water', 'Aloe barbadensis was found in the tomb of Egyptian pharaohs'],
    distributionCountries: ['India', 'Egypt', 'USA', 'Mexico', 'China'],
  ),
  PlantModel(
    id: 'seed_13',
    commonName: 'Moringa',
    scientificName: 'Moringa oleifera',
    family: 'Moringaceae',
    emoji: '🌿',
    description: 'Moringa (Drumstick tree) is called the "Miracle Tree" for its extraordinary nutritional density. Every part — leaves, pods, seeds, and roots — is edible and medicinal.',
    confidence: 1.0,
    regionPills: ['India', 'Africa', 'Tropical worldwide'],
    habitat: 'Tropical and subtropical gardens',
    height: '3–12 m',
    bloomSeason: 'Year-round',
    climate: 'Tropical semi-arid',
    careData: CareData(soil: 'Sandy or loamy, well-draining', sunlight: 'Full sun', water: 'Low – very drought tolerant', ph: '6.3–7.0', temperature: '25–35°C'),
    uses: UsesData(medicinal: 'Rich in antioxidants; treats malnutrition and inflammation', culinary: 'Drumstick pods and leaves used in South Indian curries and sambar'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Used in Ayurveda for over 4,000 years; being promoted by UN as a solution to food insecurity.',
    funFacts: ['Contains 7× more Vitamin C than oranges and 4× more calcium than milk', 'One of the fastest growing trees — can grow 3 metres in a year'],
    distributionCountries: ['India', 'Ethiopia', 'Philippines', 'Tanzania'],
  ),
  PlantModel(
    id: 'seed_14',
    commonName: 'Indian Rosewood',
    scientificName: 'Dalbergia latifolia',
    family: 'Fabaceae',
    emoji: '🌲',
    description: 'Indian Rosewood (Shisham) is one of India\'s most prized timber trees, famous for its beautiful grain and durability. It is also valued in traditional medicine.',
    confidence: 1.0,
    regionPills: ['India', 'Indonesia'],
    habitat: 'Tropical deciduous forests',
    height: '25–40 m',
    bloomSeason: 'Mar–Apr',
    climate: 'Tropical monsoon',
    careData: CareData(soil: 'Deep, well-draining alluvial', sunlight: 'Full sun', water: 'Moderate', ph: '6.5–7.5', temperature: '11–40°C'),
    uses: UsesData(medicinal: 'Bark used for skin diseases; wood oil has antimicrobial properties', industrial: 'Premium furniture, musical instruments, and decorative veneers'),
    iucnStatus: 'Vulnerable',
    culturalSignificance: 'Used in the finest Indian furniture and veena musical instruments.',
    funFacts: ['Listed as a CITES Appendix II species due to over-harvesting', 'A slow-growing tree that can live over 500 years'],
    distributionCountries: ['India', 'Indonesia', 'Sri Lanka'],
  ),
  PlantModel(
    id: 'seed_15',
    commonName: 'Brahmi',
    scientificName: 'Bacopa monnieri',
    family: 'Plantaginaceae',
    emoji: '🌱',
    description: 'Brahmi is a creeping aquatic herb considered one of Ayurveda\'s most powerful brain tonics. It has been used for thousands of years to enhance memory and cognitive function.',
    confidence: 1.0,
    regionPills: ['India', 'Nepal', 'Sri Lanka'],
    habitat: 'Wetlands, ponds, rice fields',
    height: '10–30 cm',
    bloomSeason: 'Jun–Sep',
    climate: 'Tropical and subtropical',
    careData: CareData(soil: 'Wet, loamy', sunlight: 'Full sun to partial shade', water: 'Very high – semi-aquatic', ph: '6.5–7.5', temperature: '15–30°C'),
    uses: UsesData(medicinal: 'Nootropic; used for memory, anxiety, epilepsy, and ADHD'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Named after Brahma, the Hindu god of creation; considered sacred in Ayurveda.',
    funFacts: ['Modern clinical trials confirm memory-enhancing effects', 'Used by ancient Indian scholars for mental clarity during long study sessions'],
    distributionCountries: ['India', 'Nepal', 'Sri Lanka', 'Taiwan', 'Florida'],
  ),
  PlantModel(
    id: 'seed_16',
    commonName: 'Peepal',
    scientificName: 'Ficus religiosa',
    family: 'Moraceae',
    emoji: '🌳',
    description: 'The Sacred Fig (Peepal) is one of the most spiritually significant trees in Indian culture, venerated by Hindus, Buddhists, and Jains alike. Gautama Buddha attained enlightenment beneath a Peepal tree.',
    confidence: 1.0,
    regionPills: ['India', 'Nepal', 'South Asia'],
    habitat: 'Forest edges, roadsides, temples',
    height: '15–25 m',
    bloomSeason: 'Feb–Mar (figs: Apr–Jun)',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Well-draining loam to sandy', sunlight: 'Full sun', water: 'Low to moderate', ph: '5.5–7.5', temperature: '15–40°C'),
    uses: UsesData(medicinal: 'Bark and leaves treat skin diseases, asthma, and diabetes in Ayurveda'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'The Bodhi tree under which Buddha attained enlightenment was a Peepal. Worshipped every Saturday in India.',
    funFacts: ['Releases oxygen even at night — one of very few plants to do so', 'Can live over 3,000 years; some trees in India are over 2,500 years old'],
    distributionCountries: ['India', 'Nepal', 'Sri Lanka', 'Myanmar', 'Indonesia'],
  ),
  PlantModel(
    id: 'seed_17',
    commonName: 'Sandalwood',
    scientificName: 'Santalum album',
    family: 'Santalaceae',
    emoji: '🌿',
    description: 'Indian Sandalwood is the world\'s most valuable wood, prized for its rich, warm fragrance that persists for decades. It is central to Indian religious and beauty traditions.',
    confidence: 1.0,
    regionPills: ['India', 'Australia', 'Indonesia'],
    habitat: 'Dry deciduous forests',
    height: '4–10 m',
    bloomSeason: 'May–Jun',
    climate: 'Tropical dry to semi-arid',
    careData: CareData(soil: 'Rocky, well-draining', sunlight: 'Full sun', water: 'Low', ph: '6.0–7.5', temperature: '12–35°C'),
    uses: UsesData(medicinal: 'Antiseptic and anti-inflammatory; treats skin disorders', cosmetic: 'Sandalwood paste used for skin brightening and cooling', industrial: 'Fine furniture, incense, and perfumery'),
    iucnStatus: 'Vulnerable',
    culturalSignificance: 'Used in Hindu, Buddhist, and Jain rituals; sandalwood paste applied to deities and devotees.',
    funFacts: ['The heartwood develops its fragrance only after 15–20 years', 'Karnataka in India produces the finest quality sandalwood in the world'],
    distributionCountries: ['India', 'Australia', 'Indonesia', 'New Caledonia'],
  ),
  PlantModel(
    id: 'seed_18',
    commonName: 'Bitter Gourd',
    scientificName: 'Momordica charantia',
    family: 'Cucurbitaceae',
    emoji: '🥒',
    description: 'Bitter Gourd (Karela) is one of the most medicinally important vegetables in India, used in traditional medicine to manage diabetes. Its distinctive bitterness comes from momordicin compounds.',
    confidence: 1.0,
    regionPills: ['India', 'South Asia', 'Africa'],
    habitat: 'Tropical gardens',
    height: 'Vine up to 5 m',
    bloomSeason: 'Jun–Sep',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Fertile, well-draining loam', sunlight: 'Full sun', water: 'Moderate', ph: '6.0–6.7', temperature: '24–30°C'),
    uses: UsesData(medicinal: 'Lowers blood sugar; anti-diabetic properties well-documented', culinary: 'Stir-fried, stuffed, or juiced in Indian cuisine'),
    iucnStatus: 'Least Concern',
    funFacts: ['Contains polypeptide-p, a plant insulin that mimics human insulin', 'One of the most bitter edible plants in the world'],
    distributionCountries: ['India', 'China', 'Philippines', 'Ghana', 'Caribbean'],
  ),
  PlantModel(
    id: 'seed_19',
    commonName: 'Curry Leaf',
    scientificName: 'Murraya koenigii',
    family: 'Rutaceae',
    emoji: '🌿',
    description: 'The curry leaf tree is native to India and Sri Lanka and is an indispensable ingredient in South Indian and Sri Lankan cuisine. Its aromatic leaves are used fresh in tempering.',
    confidence: 1.0,
    regionPills: ['India', 'Sri Lanka', 'SE Asia'],
    habitat: 'Tropical forest edges',
    height: '4–6 m',
    bloomSeason: 'Mar–May',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Well-draining sandy loam', sunlight: 'Full sun to partial shade', water: 'Moderate', ph: '6.0–7.0', temperature: '16–38°C'),
    uses: UsesData(medicinal: 'Lowers cholesterol and blood sugar; aids digestion', culinary: 'Leaves are essential tempering herb in South Indian dishes like sambar, rasam and chutney', cosmetic: 'Leaf paste applied to hair to prevent greying'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Inseparable from South Indian cooking; used in Ayurveda for hair and skin.',
    funFacts: ['Despite the name, curry leaves are not related to curry powder', 'Rich in iron, calcium, and vitamins A, B, C, and E'],
    distributionCountries: ['India', 'Sri Lanka', 'Myanmar', 'Thailand'],
  ),
  PlantModel(
    id: 'seed_20',
    commonName: 'Indian Paintbrush',
    scientificName: 'Butea monosperma',
    family: 'Fabaceae',
    emoji: '🌺',
    description: 'Flame of the Forest (Palash) is one of India\'s most spectacular flowering trees, turning forests brilliant orange-red in spring. It is the state flower of Jharkhand and Uttar Pradesh.',
    confidence: 1.0,
    regionPills: ['India', 'Nepal', 'SE Asia'],
    habitat: 'Dry and moist deciduous forests',
    height: '10–15 m',
    bloomSeason: 'Feb–Apr',
    climate: 'Tropical to subtropical',
    careData: CareData(soil: 'Sandy to clayey, tolerates poor soil', sunlight: 'Full sun', water: 'Low – drought tolerant', ph: '5.0–7.5', temperature: '10–48°C'),
    uses: UsesData(medicinal: 'Bark, leaves, and flowers used in Ayurveda for wound healing and skin diseases', industrial: 'Lac host plant; flowers produce natural yellow dye for Holi'),
    iucnStatus: 'Least Concern',
    culturalSignificance: 'Called "Flame of the Forest"; its flowers are used to make the Holi dye. Sacred to Lord Brahma.',
    funFacts: ['The tree sheds all its leaves before flowering, making the orange blooms even more vivid', 'It is a major host for the lac insect, source of commercial shellac'],
    distributionCountries: ['India', 'Nepal', 'Sri Lanka', 'Myanmar', 'Thailand'],
  ),
];
