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

  factory GymModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? '';
    final name = json['gymName'] ?? '';
    final facilities = List<String>.from(json['facilities'] ?? []);
    
    // Determine category based on facilities or name
    String category = 'Gym';
    final lowerName = name.toLowerCase();
    if (facilities.any((f) => f.toLowerCase().contains('yoga')) || lowerName.contains('yoga')) {
      category = 'Yoga';
    } else if (facilities.any((f) => f.toLowerCase().contains('zumba')) || lowerName.contains('zumba')) {
      category = 'Zumba';
    } else if (facilities.any((f) => f.toLowerCase().contains('sports')) || lowerName.contains('sports')) {
      category = 'Sports';
    }
    
    final price = json['averagePrice'] as int? ?? 0;
    
    // Determine tier based on price
    String tier = 'Silver';
    if (price >= 400) {
      tier = 'Platinum';
    } else if (price >= 300) {
      tier = 'Diamond';
    } else if (price >= 200) {
      tier = 'Gold';
    }
    
    // Determine working hours
    final workingHours = json['workingHours'] as Map<String, dynamic>?;
    final openingTime = workingHours?['open'] ?? '5 AM';
    final closingTime = workingHours?['close'] ?? '11 PM';
    
    // Get location coordinates and address
    final loc = json['location'] as Map<String, dynamic>?;
    final address = loc?['address'] ?? '';
    
    // Calculate a simulated realistic distance if coordinates are dummy
    // User mock: 19.0760, 72.8777
    final lat = loc?['latitude'] as double? ?? 19.0760;
    final lon = loc?['longitude'] as double? ?? 72.8777;
    double distance = 1.2;
    if (lat == 19.0760 && lon == 72.8777) {
      distance = 0.5 + (id.hashCode % 15) / 10;
    } else {
      final dLat = (lat - 19.0760) * 111.0;
      final dLon = (lon - 72.8777) * 111.0 * 0.94;
      final dist = dLat * dLat + dLon * dLon;
      if (dist > 2500) {
        distance = 0.5 + (id.hashCode % 20) / 10;
      } else {
        distance = double.parse(dist.toStringAsFixed(1));
        if (distance < 0.1) distance = 0.3;
      }
    }
    
    // Generate a deterministic rating based on ID
    final rating = 4.0 + (id.hashCode % 10) / 10.0;

    return GymModel(
      id: id,
      name: name,
      category: category,
      tier: tier,
      distanceKm: distance,
      openingTime: openingTime,
      closingTime: closingTime,
      pricePerSession: price,
      rating: rating,
      imageUrl: json['firstImage'] ?? '',
      facilities: facilities,
      usageInstructions: const [
        'Gym shoes required',
        'Carry your own water bottle',
        'Show digital check-in pass at the reception',
      ],
      address: address,
      description: 'Premium training facility equipped with modern amenities and certified trainers. Access all features with your GYMZ pass.',
    );
  }
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