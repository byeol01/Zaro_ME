import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _startAddressController = TextEditingController();
  final TextEditingController _endAddressController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchCardVisible = true;

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _routeMarkers = {};

  List<Map<String, dynamic>> _allTrashCanData = [];
  final Set<Marker> _visibleTrashCanMarkers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _loadTrashCanData();
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _endAddressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTrashCanData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/trash_cans_seoul.json',
      );
      final List<dynamic> data = jsonDecode(jsonString);
      _allTrashCanData = data.cast<Map<String, dynamic>>();
      print("${_allTrashCanData.length}개의 쓰레기통 원본 데이터를 로드했습니다.");
    } catch (e) {
      print("쓰레기통 데이터 로딩 오류: $e");
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final apiKey = dotenv.env['KAKAO_REST_API_KEY'];
    if (apiKey == null) {
      return null;
    }
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=$address',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $apiKey'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['documents'].isNotEmpty) {
          final doc = data['documents'][0];
          return LatLng(double.parse(doc['y']), double.parse(doc['x']));
        }
      }
    } catch (e) {
      print("카카오 주소 변환 API 호출 중 오류 발생: $e");
    }
    return null;
  }

  Future<String?> _fetchRoute(LatLng start, LatLng end) async {
    final apiKey = dotenv.env['X_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    final headers = {'x-api-key': apiKey};
    final url = Uri.parse(
      'https://ar-navi-server-neyqoupnca-du.a.run.app/pathfinder?startY=${start.latitude}&startX=${start.longitude}&endY=${end.latitude}&endX=${end.longitude}&option=safe&service=auto',
    );
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(
          "경로 탐색 API 오류: 상태 코드 ${response.statusCode}, 응답: ${response.body}",
        );
      }
    } catch (e) {
      print("경로 탐색 API 호출 중 예외 발생: $e");
    }
    return null;
  }

  void _parseGeoJsonAndDraw(String geoJsonData) {
    _polylines.clear();
    _routeMarkers.clear();
    _visibleTrashCanMarkers.clear();

    final Map<String, dynamic> decodedJson = jsonDecode(geoJsonData);
    final List<dynamic> features = decodedJson['features'];
    List<LatLng> allRoutePoints = [];

    for (final feature in features) {
      final geometry = feature['geometry'];
      if (geometry == null) continue;
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];
      if (type == 'LineString') {
        final List<LatLng> points = [];
        for (final point in coordinates) {
          points.add(LatLng(point[1], point[0]));
        }
        allRoutePoints.addAll(points);
        _polylines.add(
          Polyline(
            polylineId: PolylineId(feature['id'].toString()),
            points: points,
            color: Colors.red,
            width: 5,
          ),
        );
      } else if (type == 'Point') {
        final point = LatLng(coordinates[1], coordinates[0]);
        allRoutePoints.add(point);
        _routeMarkers.add(
          Marker(
            markerId: MarkerId(feature['id'].toString()),
            position: point,
            infoWindow: InfoWindow(
              title: 'ID: ${feature['id']}',
              snippet: feature['properties']['maneuver'] ?? '경유지',
            ),
          ),
        );
      }
    }

    _displayTrashCansNearRoute(allRoutePoints);

    if (_mapController != null && allRoutePoints.isNotEmpty) {
      final bounds = _boundsFromLatLngList(allRoutePoints);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    }

    setState(() {});
  }

  void _displayTrashCansNearRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;
    for (final trashCanData in _allTrashCanData) {
      final lat = trashCanData['lat'];
      final lng = trashCanData['lng'];
      final name = trashCanData['name'] ?? '정보 없음';
      if (lat == null || lng == null) continue;
      final trashCanPosition = LatLng(lat, lng);
      for (final routePoint in routePoints) {
        final distance = Geolocator.distanceBetween(
          trashCanPosition.latitude,
          trashCanPosition.longitude,
          routePoint.latitude,
          routePoint.longitude,
        );
        if (distance <= 30) {
          _visibleTrashCanMarkers.add(
            Marker(
              markerId: MarkerId('trash_can_${name}_${lat}'),
              position: trashCanPosition,
              infoWindow: InfoWindow(title: '가로 쓰레기통', snippet: name),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow,
              ),
            ),
          );
          break;
        }
      }
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _searchRoute() async {
    FocusScope.of(context).unfocus();
    final startAddress = _startAddressController.text;
    final endAddress = _endAddressController.text;
    if (startAddress.isEmpty || endAddress.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('출발지와 도착지를 모두 입력해주세요.')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        _getCoordinatesFromAddress(startAddress),
        _getCoordinatesFromAddress(endAddress),
      ]);
      final startCoords = results[0];
      final endCoords = results[1];
      if (startCoords == null || endCoords == null) {
        throw Exception('주소를 좌표로 변환하는데 실패했습니다. 주소를 확인해주세요.');
      }
      final geoJsonData = await _fetchRoute(startCoords, endCoords);
      if (geoJsonData == null) {
        throw Exception('경로 데이터를 받아오는데 실패했습니다.');
      }
      _parseGeoJsonAndDraw(geoJsonData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류: ${e.toString().replaceAll("Exception: ", "")}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            polylines: _polylines,
            markers: _routeMarkers.union(_visibleTrashCanMarkers),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (_) {
              if (_isSearchCardVisible) {
                setState(() {
                  _isSearchCardVisible = false;
                });
              }
              FocusScope.of(context).unfocus();
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isSearchCardVisible ? 10.0 : -300.0,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _startAddressController,
                      decoration: const InputDecoration(
                        labelText: '출발지',
                        prefixIcon: Icon(Icons.trip_origin),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                        floatingLabelStyle: TextStyle(color: Colors.green),
                      ),
                      cursorColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _endAddressController,
                      decoration: const InputDecoration(
                        labelText: '도착지',
                        prefixIcon: Icon(Icons.place),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                        floatingLabelStyle: TextStyle(color: Colors.green),
                      ),
                      cursorColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchRoute,
                        icon: const Icon(Icons.search),
                        label: const Text('길찾기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSearchCardVisible = !_isSearchCardVisible;
          });
        },
        backgroundColor: Colors.green,
        child: Icon(_isSearchCardVisible ? Icons.close : Icons.search),
      ),
    );
  }
}
