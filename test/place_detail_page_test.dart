import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// The map plugin's platform seam replaces native views in widget tests.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:hotline_app/place_models.dart';
import 'package:hotline_app/place_service.dart';
import 'package:hotline_app/tourist_guide_page.dart';

final samplePlace = Place.fromMap({
  'id': 'resort',
  'name': 'Marina Black Sand Resort',
  'category': 'Resort',
  'description':
      'A coastal resort in Tiwi with swimming pools, beachfront cottages and a volcanic black sand shoreline.',
  'full_address': 'Marina Street, Maynonong, Tiwi, 4513 Albay, Philippines',
  'phone': '09985551280',
  'latitude': 13.500502,
  'longitude': 123.616310,
  'distance_label': '11.5 km',
  'is_featured': true,
});

class FakePlaceService implements PlaceService {
  @override
  Future<List<Place>> fetchPlaces({bool rethrowOnError = false}) async => [
    samplePlace,
  ];

  @override
  Future<List<PlaceReview>> fetchReviews(String placeId) async => [
    PlaceReview(
      id: 'r1',
      placeId: placeId,
      rating: 5,
      reviewText: 'A relaxing visit.',
      reviewerName: 'Visitor',
      reviewerPhotoUrl: '',
      createdAt: DateTime(2026, 9, 30),
    ),
  ];

  @override
  Future<void> submitReview({
    required String placeId,
    required int rating,
    required String reviewText,
  }) async {}

}

class FakeMapPlatform extends GoogleMapsFlutterPlatform {
  MapObjects? objects;

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    objects = mapObjects;
    return const ColoredBox(color: Color(0xFFCDF7E5));
  }
}

Future<void> mountDetail(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  double width = 390,
  Place? place,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: PlaceDetailPage(
        place: place ?? samplePlace,
        placeService: FakePlaceService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeMapPlatform maps;
  setUp(() {
    final previous = GoogleMapsFlutterPlatform.instance;
    maps = FakeMapPlatform();
    GoogleMapsFlutterPlatform.instance = maps;
    addTearDown(() => GoogleMapsFlutterPlatform.instance = previous);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'detail sections and existing reviews work in ${brightness.name}',
      (tester) async {
        await mountDetail(tester, brightness: brightness);
        expect(find.text('Marina Black Sand Resort'), findsOneWidget);
        expect(find.text('11.5 km'), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Contact & details'), 250);
        await tester.pumpAndSettle();
        expect(find.text('13.500502, 123.616310'), findsOneWidget);
        expect(maps.objects!.markers.single.position.latitude, 13.500502);
        await tester.scrollUntilVisible(find.text('Write a review'), 250);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Write a review'));
        await tester.pumpAndSettle();
        expect(find.byType(ReviewFormSheet), findsOneWidget);
        expect(find.text('Publish review'), findsOneWidget);
        await tester.tap(find.byTooltip('Close review form'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('A relaxing visit.'), 200);
        await tester.tap(find.text('A relaxing visit.'));
        await tester.pumpAndSettle();
        expect(find.text('Review'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('map buttons open directions and the selected place', (
    tester,
  ) async {
    final urls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        urls.add(call.arguments['url'] as String);
        return true;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      ),
    );
    await mountDetail(tester);
    await tester.scrollUntilVisible(find.text('Directions'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directions'));
    await tester.pumpAndSettle();
    final directions = Uri.parse(urls.single);
    expect(directions.path, '/maps/dir/');
    expect(directions.queryParameters['destination'], '13.500502,123.61631');
    await tester.tap(find.text('Open Maps'));
    await tester.pumpAndSettle();
    expect(Uri.parse(urls.last).queryParameters['q'], '13.500502,123.61631');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large text fits a narrow screen without inventing map coordinates',
    (tester) async {
      final place = Place.fromMap({
        ...samplePlace.toMap(),
        'latitude': null,
        'longitude': null,
      });
      await mountDetail(tester, width: 320, scale: 1.7, place: place);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Directions'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Approximate area · Tiwi'), findsOneWidget);
      expect(maps.objects!.markers, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Contact & details'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
