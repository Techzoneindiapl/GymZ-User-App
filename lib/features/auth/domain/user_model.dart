class UserModel {
  const UserModel({
    required this.name,
    required this.gender,
    required this.phone,
    required this.email,
    required this.pincode,
    this.selfieUrl,
    required this.location,
    required this.memberId,
    this.token,
    this.gymsCount = 0,
    this.sessionsCount = 0,
    this.memberSinceDays = 0,
  });

  final String name;
  final String gender;
  final String phone;
  final String email;
  final String pincode;
  final String? selfieUrl;
  final String location;
  final String memberId;
  final String? token;
  final int gymsCount;
  final int sessionsCount;
  final int memberSinceDays;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Determine user's ID or member ID from whatever format the backend returns.
    // Fallback to generating a deterministic member ID if not present in the payload.
    final id = json['member_id'] ?? json['id']?.toString() ?? json['memberId'] ?? json['uniqueId'] ?? 'GZ-${DateTime.now().year}-${json['phone']?.substring(json['phone']!.length - 5) ?? "00000"}';

    return UserModel(
      name: json['name'] ?? json['fullName'] ?? '',
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? json['mobileNumber'] ?? '',
      email: json['email'] ?? json['emailAddress'] ?? '',
      pincode: json['pincode'] ?? '',
      selfieUrl: json['selfie'] ?? json['selfieUrl'] ?? json['avatar'] ?? json['avatarPath'],
      location: json['location'] ?? '',
      memberId: id,
      token: json['token'] ?? json['accessToken'],
      gymsCount: json['gymsCount'] ?? 0,
      sessionsCount: json['sessionsCount'] ?? 0,
      memberSinceDays: json['memberSinceDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'phone': phone,
      'email': email,
      'pincode': pincode,
      'selfie': selfieUrl,
      'location': location,
      'member_id': memberId,
      'gymsCount': gymsCount,
      'sessionsCount': sessionsCount,
      'memberSinceDays': memberSinceDays,
      if (token != null) 'token': token,
    };
  }

  UserModel copyWith({
    String? name,
    String? gender,
    String? phone,
    String? email,
    String? pincode,
    String? selfieUrl,
    String? location,
    String? memberId,
    String? token,
    int? gymsCount,
    int? sessionsCount,
    int? memberSinceDays,
  }) {
    return UserModel(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      pincode: pincode ?? this.pincode,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      location: location ?? this.location,
      memberId: memberId ?? this.memberId,
      token: token ?? this.token,
      gymsCount: gymsCount ?? this.gymsCount,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      memberSinceDays: memberSinceDays ?? this.memberSinceDays,
    );
  }
}
