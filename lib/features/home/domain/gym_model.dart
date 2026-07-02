class GymModel {
  const GymModel({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.distanceKm,
    required this.openingTime,
    required this.closingTime,
    required this.pricePerSession,
    required this.rating,
    required this.imageUrl,
    this.facilities = const [],
    this.usageInstructions = const [],
    this.address = '',
    this.description = '',
  });

  final String id;
  final String name;
  final String category;
  final String tier;
  final double distanceKm;
  final String openingTime;
  final String closingTime;
  final int pricePerSession;
  final double rating;
  final String imageUrl;
  final List<String> facilities;
  final List<String> usageInstructions;
  final String address;
  final String description;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get timingLabel => '$openingTime – $closingTime';
}

const List<GymModel> kSampleGyms = [
  GymModel(
    id: 'g1',
    name: 'Iron Forge Studio',
    category: 'Gym',
    tier: 'Platinum',
    distanceKm: 0.8,
    openingTime: '5:00 AM',
    closingTime: '11:00 PM',
    pricePerSession: 249,
    rating: 4.9,
    imageUrl: '',
    address: '12, Linking Road, Bandra West, Mumbai',
    description: 'Premium strength-focused gym with Olympic platforms, sleds and a recovery zone.',
    facilities: ['Cardio', 'Weight Training', 'Steam', 'Shower', 'Boxing', 'Martial Arts'],
    usageInstructions: ['Gym shoes required', 'Carry your own water bottle', 'No outside food'],
  ),
  GymModel(
    id: 'g2',
    name: 'Lotus Yoga Sanctuary',
    category: 'Yoga',
    tier: 'Diamond',
    distanceKm: 1.2,
    openingTime: '6:00 AM',
    closingTime: '9:00 PM',
    pricePerSession: 199,
    rating: 4.8,
    imageUrl: '',
    address: '7, Hill Road, Bandra West, Mumbai',
    description: 'Holistic yoga center offering Hatha, Vinyasa and meditation sessions.',
    facilities: ['Yoga Mats', 'Steam', 'Meditation Room', 'Locker'],
    usageInstructions: ['Bring your own mat', 'Arrive 5 min early', 'Silence phones'],
  ),
];

const List<String> kCategories = ['Gym', 'Yoga', 'Sports', 'Zumba'];

const Map<String, String> kTierColors = {
  'Platinum': 'platinum',
  'Diamond': 'diamond',
  'Gold': 'gold',
  'Silver': 'silver',
};