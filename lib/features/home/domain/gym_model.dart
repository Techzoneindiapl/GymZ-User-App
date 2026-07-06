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
    required this.latitude,
    required this.longitude,
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
  final double latitude;
  final double longitude;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get timingLabel => '$openingTime – $closingTime';

  GymModel copyWith({
    double? distanceKm,
  }) {
    return GymModel(
      id: id,
      name: name,
      category: category,
      tier: tier,
      distanceKm: distanceKm ?? this.distanceKm,
      openingTime: openingTime,
      closingTime: closingTime,
      pricePerSession: pricePerSession,
      rating: rating,
      imageUrl: imageUrl,
      facilities: facilities,
      usageInstructions: usageInstructions,
      address: address,
      description: description,
      latitude: latitude,
      longitude: longitude,
    );
  }

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
    
    final lat = (loc?['latitude'] as num?)?.toDouble() ?? 19.0760;
    final lon = (loc?['longitude'] as num?)?.toDouble() ?? 72.8777;

    // Generate a deterministic rating based on ID
    final rating = 4.0 + (id.hashCode % 10) / 10.0;

    return GymModel(
      id: id,
      name: name,
      category: category,
      tier: tier,
      distanceKm: 1.2, // Default distance placeholder (overwritten dynamically)
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
      latitude: lat,
      longitude: lon,
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
    latitude: 19.0782,
    longitude: 72.8801,
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
    latitude: 19.0805,
    longitude: 72.8752,
  ),
];

const List<String> kCategories = ['Gym', 'Yoga', 'Sports', 'Zumba'];

const Map<String, String> kTierColors = {
  'Platinum': 'platinum',
  'Diamond': 'diamond',
  'Gold': 'gold',
  'Silver': 'silver',
};