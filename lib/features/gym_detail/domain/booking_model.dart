class BookingModel {
  final String id;
  final String customerId;
  final String gymId;
  final String gymName;
  final String gymAddress;
  final List<String> galleryPhotos;
  final String bookingDate;
  final String timeSlot;
  final double price;
  final String status;
  final String bookingId;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.gymId,
    required this.gymName,
    required this.gymAddress,
    required this.galleryPhotos,
    required this.bookingDate,
    required this.timeSlot,
    required this.price,
    required this.status,
    required this.bookingId,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final gymJson = json['gymId'];
    String gId = '';
    String gName = '';
    String gAddress = '';
    List<String> photos = [];

    if (gymJson is Map<String, dynamic>) {
      gId = gymJson['_id']?.toString() ?? gymJson['id']?.toString() ?? '';
      gName = gymJson['gymName'] ?? '';
      gAddress = gymJson['address'] ?? '';
      
      final mediaJson = gymJson['media'];
      if (mediaJson is Map<String, dynamic>) {
        final photosJson = mediaJson['galleryPhotos'];
        if (photosJson is List) {
          photos = photosJson.map((e) => e.toString()).toList();
        }
      }
    } else if (gymJson is String) {
      gId = gymJson;
    }

    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return BookingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      gymId: gId,
      gymName: gName,
      gymAddress: gAddress,
      galleryPhotos: photos,
      bookingDate: json['bookingDate'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      price: (json['price'] ?? 0.0) is int
          ? (json['price'] ?? 0).toDouble()
          : (json['price'] as num).toDouble(),
      status: json['status'] ?? 'booked',
      bookingId: json['bookingId'] ?? '',
      createdAt: parsedDate,
    );
  }
}
