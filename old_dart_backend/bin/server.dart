import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

// In-memory data store
final List<Map<String, dynamic>> _buildings = [
  {
    'id': '1',
    'name': 'Sunrise Apartments',
    'floors': 5,
  },
  {
    'id': '2',
    'name': 'Greenwood Complex',
    'floors': 3,
  },
];

final Map<String, List<Map<String, dynamic>>> _flats = {
  '1': List.generate(20, (index) => {
    'id': '1-${index + 1}',
    'flatNumber': 'A${index + 1}',
    'floor': (index / 4).floor() + 1,
    'isAvailable': index % 3 != 0,
  }),
  '2': List.generate(12, (index) => {
    'id': '2-${index + 1}',
    'flatNumber': 'B${index + 1}',
    'floor': (index / 4).floor() + 1,
    'isAvailable': index % 4 != 0,
  }),
};


// Configure routes
final _router = Router()
  ..get('/buildings', _getBuildings)
  ..post('/buildings', _createBuilding)
  ..get('/buildings/<buildingId>/flats', _getFlatsForBuilding);

Response _getBuildings(Request req) {
  return Response.ok(jsonEncode(_buildings), headers: {'Content-Type': 'application/json'});
}

Future<Response> _createBuilding(Request request) async {
  final body = await request.readAsString();
  final postData = jsonDecode(body) as Map<String, dynamic>;
  final newBuilding = {
    'id': '${_buildings.length + 1}',
    'name': postData['name'],
    'floors': postData['floors'],
  };
  _buildings.add(newBuilding);
  return Response(
    201,
    body: jsonEncode(newBuilding),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _getFlatsForBuilding(Request request, String buildingId) {
  if (_flats.containsKey(buildingId)) {
    return Response.ok(jsonEncode(_flats[buildingId]), headers: {'Content-Type': 'application/json'});
  }
  return Response.notFound('Building not found');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
