import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/core/network/api_client.dart';
import 'package:gymz_user/core/storage/storage_service.dart';
import 'package:gymz_user/features/home/data/repositories/gym_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late ApiClient apiClient;
  late GymRepository gymRepository;

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

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

    test('fetchGymDetails calls api/v1/user/gyms/{id} and parses details successfully', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/gyms/6a4529123902708d568155cf') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': '6a4529123902708d568155cf',
                      'gymName': 'Test Platinum Gym',
                      'averagePrice': 450,
                      'workingHours': {
                        'open': '5 AM',
                        'close': '11 PM'
                      },
                      'facilities': [
                        {
                          'name': 'Steam Bath',
                          'icon': 'hot_tub',
                          'category': 'Gym'
                        },
                        {
                          'name': 'Yoga',
                          'icon': 'self_improvement',
                          'category': 'Yoga'
                        }
                      ],
                      'media': {
                        'galleryPhotos': [
                          'https://gymz.com/photo1.jpg',
                          'https://gymz.com/photo2.jpg'
                        ]
                      },
                      'description': 'Premium gym description',
                      'tier': 'Platinum',
                      'rating': 4.8,
                      'usageInstructions': [
                        'Gym shoes required'
                      ],
                      'sessionPricing': {
                        'morningHour': {
                          'price': 350,
                          'slot': '5 AM to 10 AM'
                        },
                        'primeHour': {
                          'price': 500,
                          'slot': '5 PM to 9 PM'
                        },
                        'routineHour': {
                          'price': 400,
                          'slot': '10 AM to 5 PM'
                        },
                        'averagePrice': 450
                      }
                    }
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final gym = await gymRepository.fetchGymDetails('6a4529123902708d568155cf');

      expect(gym.id, equals('6a4529123902708d568155cf'));
      expect(gym.name, equals('Test Platinum Gym'));
      expect(gym.pricePerSession, equals(450));
      expect(gym.tier, equals('Platinum'));
      expect(gym.rating, equals(4.8));
      expect(gym.description, equals('Premium gym description'));
      expect(gym.facilities, contains('Steam Bath'));
      expect(gym.facilities, contains('Yoga'));
      expect(gym.galleryPhotos, hasLength(2));
      expect(gym.galleryPhotos.first, equals('https://gymz.com/photo1.jpg'));
      expect(gym.imageUrl, equals('https://gymz.com/photo1.jpg'));
      expect(gym.usageInstructions, contains('Gym shoes required'));
      expect(gym.sessionPricing, isNotNull);
      expect(gym.sessionPricing!.morningHour.price, equals(350));
      expect(gym.sessionPricing!.morningHour.slot, equals('5 AM to 10 AM'));
      expect(gym.sessionPricing!.primeHour.price, equals(500));
      expect(gym.sessionPricing!.routineHour.price, equals(400));
      expect(gym.sessionPricing!.averagePrice, equals(450));
    });
  });
}
