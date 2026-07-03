import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/core/network/api_client.dart';
import 'package:gymz_user/core/storage/storage_service.dart';
import 'package:gymz_user/features/home/data/repositories/gym_repository.dart';

void main() {
  late Dio dio;
  late ApiClient apiClient;
  late GymRepository gymRepository;

  setUp(() {
    final storageService = StorageService();
    apiClient = ApiClient(storageService);
    dio = apiClient.dio;
    gymRepository = GymRepository(apiClient);
  });

  group('GymRepository Tests', () {
    test('fetchGyms calls api/v1/user/gyms with parameters and parses data successfully', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/gyms') {
              expect(options.queryParameters['category'], equals('Yoga'));
              expect(options.queryParameters['search'], equals('Sanctuary'));

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'count': 1,
                    'data': [
                      {
                        '_id': '6a4529123902708d568155cf',
                        'gymName': 'Lotus Yoga Sanctuary',
                        'averagePrice': 199,
                        'firstImage': 'https://res.cloudinary.com/dmf79s3lf/image/upload/v1782917433/GymZ/test/image/jvq3ytcze5hb1nabtana.jpg',
                        'location': {
                          'latitude': 18.4539,
                          'longitude': 76.7356,
                          'address': 'navi mumbai'
                        },
                        'workingHours': {
                          'open': '6 AM',
                          'close': '9 PM'
                        },
                        'gender': 'Female',
                        'facilities': [
                          'Yoga',
                          'Zumba'
                        ]
                      }
                    ]
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final result = await gymRepository.fetchGyms(
        category: 'Yoga',
        search: 'Sanctuary',
      );

      expect(result, isNotEmpty);
      expect(result.length, equals(1));
      
      final gym = result.first;
      expect(gym.id, equals('6a4529123902708d568155cf'));
      expect(gym.name, equals('Lotus Yoga Sanctuary'));
      expect(gym.pricePerSession, equals(199));
      expect(gym.imageUrl, equals('https://res.cloudinary.com/dmf79s3lf/image/upload/v1782917433/GymZ/test/image/jvq3ytcze5hb1nabtana.jpg'));
      expect(gym.openingTime, equals('6 AM'));
      expect(gym.closingTime, equals('9 PM'));
      expect(gym.category, equals('Yoga'));
      expect(gym.tier, equals('Silver'));
      expect(gym.address, equals('navi mumbai'));
      expect(gym.facilities, contains('Yoga'));
      expect(gym.facilities, contains('Zumba'));
    });
  });
}
