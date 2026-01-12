import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  late Process serverProcess;
  final port = '8088'; // Using a different port for testing
  final url = 'http://localhost:$port';

  setUpAll(() async {
    // Start the server
    serverProcess = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
      workingDirectory: 'backend',
    );

    // Wait for the server to be ready
    await serverProcess.stdout
        .transform(utf8.decoder)
        .firstWhere((log) => log.contains('Server listening on port $port'));
  });

  tearDownAll(() {
    // Stop the server
    serverProcess.kill();
  });

  group('Server API Tests', () {
    test('GET /buildings returns a list of buildings', () async {
      final response = await http.get(Uri.parse('$url/buildings'));
      expect(response.statusCode, 200);
      final buildings = jsonDecode(response.body) as List;
      expect(buildings.length, 2);
      expect(buildings[0]['name'], 'Sunrise Apartments');
    });

    test('POST /buildings creates a new building', () async {
      final response = await http.post(
        Uri.parse('$url/buildings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'New Building', 'floors': 10}),
      );
      expect(response.statusCode, 201);
      final newBuilding = jsonDecode(response.body) as Map<String, dynamic>;
      expect(newBuilding['name'], 'New Building');
      expect(newBuilding['floors'], 10);
      expect(newBuilding.containsKey('id'), isTrue);

      // Verify the building was added
      final getResponse = await http.get(Uri.parse('$url/buildings'));
      final buildings = jsonDecode(getResponse.body) as List;
      expect(buildings.length, 3);
      expect(buildings.last['name'], 'New Building');
    });

    test('GET /buildings/<buildingId>/flats returns flats for a building', () async {
      final response = await http.get(Uri.parse('$url/buildings/1/flats'));
      expect(response.statusCode, 200);
      final flats = jsonDecode(response.body) as List;
      expect(flats.length, 20);
      expect(flats[0]['flatNumber'], 'A1');
    });

    test('GET /buildings/<buildingId>/flats returns 404 for non-existent building', () async {
      final response = await http.get(Uri.parse('$url/buildings/99/flats'));
      expect(response.statusCode, 404);
      expect(response.body, 'Building not found');
    });
  });
}
