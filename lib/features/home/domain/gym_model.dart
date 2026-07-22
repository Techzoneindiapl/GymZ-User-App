class PriceSlot {
  const PriceSlot({
    required this.price,
    required this.slot,
  });

  final int price;
  final String slot;

  factory PriceSlot.fromJson(Map<String, dynamic> json) {
    return PriceSlot(
      price: (json['price'] as num?)?.toInt() ?? 0,
      slot: json['slot'] as String? ?? '',
    );
  }
}

class SessionPricing {
  const SessionPricing({
    required this.morningHour,
    required this.primeHour,
    required this.routineHour,
    required this.averagePrice,
  });

  final PriceSlot morningHour;
  final PriceSlot primeHour;
  final PriceSlot routineHour;
  final int averagePrice;

  factory SessionPricing.fromJson(Map<String, dynamic> json) {
    return SessionPricing(
      morningHour: PriceSlot.fromJson(json['morningHour'] as Map<String, dynamic>? ?? {}),
      primeHour: PriceSlot.fromJson(json['primeHour'] as Map<String, dynamic>? ?? {}),
      routineHour: PriceSlot.fromJson(json['routineHour'] as Map<String, dynamic>? ?? {}),
      averagePrice: (json['averagePrice'] as num?)?.toInt() ?? 0,
    );
  }
}

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
    this.galleryPhotos = const [],
    this.introVideo,
    this.sessionPricing,
    this.gender = 'Unisex',
    this.reviewsCount = 0,
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
  final List<String> galleryPhotos;
  final String? introVideo;
  final SessionPricing? sessionPricing;
  final String gender;
  final int reviewsCount;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get timingLabel => '$openingTime – $closingTime';

  GymModel copyWith({
    double? distanceKm,
    List<String>? galleryPhotos,
    String? introVideo,
    SessionPricing? sessionPricing,
    String? gender,
    int? reviewsCount,
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
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      introVideo: introVideo ?? this.introVideo,
      sessionPricing: sessionPricing ?? this.sessionPricing,
      gender: gender ?? this.gender,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }

  int get currentPrice {
    final pricing = sessionPricing;
    if (pricing == null) return pricePerSession;
    
    final now = DateTime.now();
    
    if (_isInSlot(pricing.morningHour.slot, now)) {
      return pricing.morningHour.price;
    }
    if (_isInSlot(pricing.primeHour.slot, now)) {
      return pricing.primeHour.price;
    }
    if (_isInSlot(pricing.routineHour.slot, now)) {
      return pricing.routineHour.price;
    }
    
    return pricing.averagePrice > 0 ? pricing.averagePrice : pricePerSession;
  }

  String get activeSlotLabel {
    final pricing = sessionPricing;
    if (pricing == null) return '';
    
    final now = DateTime.now();
    
    if (_isInSlot(pricing.morningHour.slot, now)) {
      return 'Morning Hour (${pricing.morningHour.slot})';
    }
    if (_isInSlot(pricing.primeHour.slot, now)) {
      return 'Prime Hour (${pricing.primeHour.slot})';
    }
    if (_isInSlot(pricing.routineHour.slot, now)) {
      return 'Routine Hour (${pricing.routineHour.slot})';
    }
    
    return '';
  }

  int getPriceForTime({required int hour, required int minute}) {
    final pricing = sessionPricing;
    if (pricing == null) return pricePerSession;
    
    final dummyTime = DateTime(2026, 1, 1, hour, minute);
    
    if (_isInSlot(pricing.morningHour.slot, dummyTime)) {
      return pricing.morningHour.price;
    }
    if (_isInSlot(pricing.primeHour.slot, dummyTime)) {
      return pricing.primeHour.price;
    }
    if (_isInSlot(pricing.routineHour.slot, dummyTime)) {
      return pricing.routineHour.price;
    }
    
    return pricing.averagePrice > 0 ? pricing.averagePrice : pricePerSession;
  }

  String getSlotLabelForTime({required int hour, required int minute}) {
    final pricing = sessionPricing;
    if (pricing == null) return '';
    
    final dummyTime = DateTime(2026, 1, 1, hour, minute);
    
    if (_isInSlot(pricing.morningHour.slot, dummyTime)) {
      return 'Morning Hour (${pricing.morningHour.slot})';
    }
    if (_isInSlot(pricing.primeHour.slot, dummyTime)) {
      return 'Prime Hour (${pricing.primeHour.slot})';
    }
    if (_isInSlot(pricing.routineHour.slot, dummyTime)) {
      return 'Routine Hour (${pricing.routineHour.slot})';
    }
    
    return '';
  }


  int _parseToMinutes(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    timeStr = timeStr.replaceAll(' ', '');
    final isPm = timeStr.contains('PM');
    final isAm = timeStr.contains('AM');
    
    final timePart = timeStr.replaceAll(RegExp(r'[A-Z]'), '');
    final parts = timePart.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    
    if (isPm && hour != 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }
    return hour * 60 + minute;
  }

  bool _isInSlot(String slotStr, DateTime time) {
    if (slotStr.isEmpty) return false;
    final parts = slotStr.split(RegExp(r'\s+to\s+|\s*-\s*|\s*–\s*'));
    if (parts.length < 2) return false;

    final startMin = _parseToMinutes(parts[0]);
    final endMin = _parseToMinutes(parts[1]);

    final currentMin = time.hour * 60 + time.minute;

    if (startMin <= endMin) {
      return currentMin >= startMin && currentMin < endMin;
    } else {
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  factory GymModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? '';
    final name = json['gymName'] ?? '';
    
    final rawFacilities = json['facilities'] ?? [];
    List<String> facilities = [];
    if (rawFacilities is List) {
      for (final f in rawFacilities) {
        if (f is String) {
          facilities.add(f);
        } else if (f is Map && f['name'] != null) {
          facilities.add(f['name'].toString());
        }
      }
    }
    
    String category = 'Gym';
    final lowerName = name.toLowerCase();
    if (facilities.any((f) => f.toLowerCase().contains('yoga')) || lowerName.contains('yoga')) {
      category = 'Yoga';
    } else if (facilities.any((f) => f.toLowerCase().contains('zumba')) || lowerName.contains('zumba')) {
      category = 'Zumba';
    } else if (facilities.any((f) => f.toLowerCase().contains('sports')) || lowerName.contains('sports')) {
      category = 'Sports';
    }
    
    final price = (json['averagePrice'] as num?)?.toInt() ?? 0;
    
    String tier = json['tier']?.toString() ?? '';
    if (tier.isEmpty || tier == 'Silver') {
      if (price >= 400) {
        tier = 'Platinum';
      } else if (price >= 300) {
        tier = 'Diamond';
      } else if (price >= 200) {
        tier = 'Gold';
      } else {
        tier = 'Silver';
      }
    }
    
    final workingHours = json['workingHours'] as Map<String, dynamic>?;
    final openingTime = workingHours?['open'] ?? '5 AM';
    final closingTime = workingHours?['close'] ?? '11 PM';
    
    final loc = json['location'] as Map<String, dynamic>?;
    final address = loc?['address'] ?? json['address'] ?? '';
    
    double? parsedLat;
    final rawLat = loc?['latitude'] ?? json['latitude'];
    if (rawLat is num) {
      parsedLat = rawLat.toDouble();
    } else if (rawLat is String) {
      parsedLat = double.tryParse(rawLat);
    }
    final lat = parsedLat ?? 19.0760;

    double? parsedLon;
    final rawLon = loc?['longitude'] ?? json['longitude'];
    if (rawLon is num) {
      parsedLon = rawLon.toDouble();
    } else if (rawLon is String) {
      parsedLon = double.tryParse(rawLon);
    }
    final lon = parsedLon ?? 72.8777;

    final rating = (json['rating'] as num?)?.toDouble() ?? (4.0 + (id.hashCode % 10) / 10.0);

    final media = json['media'] as Map<String, dynamic>?;
    final rawGallery = media?['galleryPhotos'] as List?;
    final galleryPhotos = rawGallery != null ? List<String>.from(rawGallery) : <String>[];
    final introVideo = media?['introVideo'] as String?;

    String imageUrl = json['firstImage'] ?? '';
    if (imageUrl.isEmpty && galleryPhotos.isNotEmpty) {
      imageUrl = galleryPhotos.first;
    }

    final rawInstructions = json['usageInstructions'];
    List<String> usageInstructions = [];
    if (rawInstructions is List) {
      usageInstructions = List<String>.from(rawInstructions);
    } else {
      usageInstructions = const [
        'Gym shoes required',
        'Carry your own water bottle',
        'Show digital check-in pass at the reception',
      ];
    }

    final description = json['description'] ?? 'Premium training facility equipped with modern amenities and certified trainers. Access all features with your GYMZ pass.';
    final gender = json['gender'] ?? 'Unisex';
    final reviewsCount = (json['reviewsCount'] as num?)?.toInt() ?? 0;

    final rawPricing = json['sessionPricing'];
    final sessionPricing = rawPricing != null ? SessionPricing.fromJson(rawPricing as Map<String, dynamic>) : null;

    return GymModel(
      id: id,
      name: name,
      category: category,
      tier: tier,
      distanceKm: 1.2,
      openingTime: openingTime,
      closingTime: closingTime,
      pricePerSession: price,
      rating: rating,
      imageUrl: imageUrl,
      facilities: facilities,
      usageInstructions: usageInstructions,
      address: address,
      description: description,
      latitude: lat,
      longitude: lon,
      galleryPhotos: galleryPhotos,
      introVideo: introVideo,
      sessionPricing: sessionPricing,
      reviewsCount: reviewsCount,
      gender: gender,
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
    gender: 'Unisex',
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
    gender: 'Female',
  ),
];

const List<String> kCategories = ['Gym', 'Yoga', 'Sports', 'Zumba'];

const Map<String, String> kTierColors = {
  'Platinum': 'platinum',
  'Diamond': 'diamond',
  'Gold': 'gold',
  'Silver': 'silver',
};