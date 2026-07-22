class ReviewModel {
  ReviewModel({
    required this.id,
    required this.customerId,
    required this.gymId,
    required this.gymName,
    required this.gymImageUrl,
    required this.gymTier,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.vendorReply,
  });

  final String id;
  final String customerId;
  final String gymId;
  final String gymName;
  final String gymImageUrl;
  final String gymTier;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? vendorReply;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final gym = json['gymId'] as Map<String, dynamic>? ?? {};
    final media = gym['media'] as Map<String, dynamic>?;
    final photos = media?['galleryPhotos'] as List?;
    final imageUrl = (photos != null && photos.isNotEmpty) ? photos.first as String : '';
    
    final replyMap = json['vendorReply'] as Map<String, dynamic>?;
    final replyText = replyMap?['text'] as String?;

    return ReviewModel(
      id: json['_id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      gymId: gym['_id'] as String? ?? '',
      gymName: gym['gymName'] as String? ?? gym['name'] as String? ?? '',
      gymImageUrl: imageUrl,
      gymTier: gym['tier'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      vendorReply: (replyText != null && replyText.isNotEmpty) ? replyText : null,
    );
  }
}
