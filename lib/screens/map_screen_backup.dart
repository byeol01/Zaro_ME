import 'dart:convert';
import 'dart:async';
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
  bool _isRouteFound = false;
  String? _lastSearchedGeoJson;

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _routeMarkers = {};
  List<Map<String, dynamic>> _allTrashCanData = [];
  final Set<Marker> _visibleTrashCanMarkers = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  String _currentInstruction = "경로를 검색해주세요.";

  BitmapDescriptor? _myLocationIcon;
  final Set<Marker> _myLocationMarker = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _loadTrashCanData();
    _loadMyLocationIcon();
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _endAddressController.dispose();
    _mapController?.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMyLocationIcon() async {
    final ImageConfiguration config = createLocalImageConfiguration(context, size: const Size(48, 48));
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      config,
      'assets/images/my_location_arrow.png',
    );
    if (mounted) {
      setState(() {
        _myLocationIcon = icon;
      });
    }
  }

  void _toggleNavigation() async {
    if (_positionStreamSubscription == null) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치 서비스를 활성화해주세요.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('위치 권한이 필요합니다.')));
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.'),
            ),
          );
        }
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            setState(() {
              _currentPosition = position;
              _updateMyLocationMarker();
              _moveCameraToCurrentPosition();
              _checkNavigationStep();
            });
          });

      if (_navigationSteps.isNotEmpty) {
        setState(() {
          _currentInstruction =
          "경로 안내를 시작합니다. 첫 번째 경유지: ${_navigationSteps.first['maneuver']}";
        });
      }
    } else {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      setState(() {
        _currentInstruction = "경로 안내가 종료되었습니다.";
        _myLocationMarker.clear();
      });
    }
  }
  
  void _updateMyLocationMarker() {
    if (_myLocationIcon != null && _currentPosition != null) {
      final marker = Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: _myLocationIcon!,
        rotation: _currentPosition!.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true, 
        zIndex: 2,
      );
      setState(() {
        _myLocationMarker.clear();
        _myLocationMarker.add(marker);
      });
    }
  }

  void _moveCameraToCurrentPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 17.0,
            bearing: _currentPosition!.heading,
          ),
        ),
      );
    }
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
    _lastSearchedGeoJson = geoJsonData;
    _polylines.clear();
    _routeMarkers.clear();
    _visibleTrashCanMarkers.clear();
    _navigationSteps.clear();
    _currentStepIndex = 0;
    setState(() {
      _currentInstruction = "경로를 검색해주세요.";
    });

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
        if (feature['properties']?['maneuver'] != null) {
          _navigationSteps.add({
            'position': LatLng(coordinates[1], coordinates[0]),
            'maneuver': feature['properties']['maneuver'],
          });
        }
      }
    }

    _displayTrashCansNearRoute(allRoutePoints);

    if (_mapController != null && allRoutePoints.isNotEmpty) {
      final bounds = _boundsFromLatLngList(allRoutePoints);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    }

    setState(() {
      _isRouteFound = true;
    });
  }

  void _checkNavigationStep() {
    if (_navigationSteps.isEmpty ||
        _currentStepIndex >= _navigationSteps.length) {
      if (_currentInstruction != "목적지에 도착했습니다.") {
        setState(() {
          _currentInstruction = "목적지에 도착했습니다.";
        });
      }
      return;
    }

    final nextStep = _navigationSteps[_currentStepIndex];
    final nextPosition = nextStep['position'] as LatLng;

    if (_currentPosition != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        nextPosition.latitude,
        nextPosition.longitude,
      );

      if (distance < 20) {
        _currentStepIndex++;
      }

      if (_currentStepIndex < _navigationSteps.length) {
        final instruction = _navigationSteps[_currentStepIndex]['maneuver'];
        final distanceToNext = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _navigationSteps[_currentStepIndex]['position'].latitude,
          _navigationSteps[_currentStepIndex]['position'].longitude,
        );
        setState(() {
          _currentInstruction = "${distanceToNext.round()}m 후, $instruction";
        });
      } else {
        setState(() {
          _currentInstruction = "목적지에 도착했습니다.";
        });
      }
    }
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
    setState(() {
      _isRouteFound = false;
      _polylines.clear();
      _routeMarkers.clear();
      _visibleTrashCanMarkers.clear();
      _myLocationMarker.clear();
      _lastSearchedGeoJson = null;
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _currentPosition = null;
      _currentInstruction = "경로를 검색해주세요.";
    });

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

  void _resetMap() {
    setState(() {
      _startAddressController.clear();
      _endAddressController.clear();
      _polylines.clear();
      _routeMarkers.clear();
      _visibleTrashCanMarkers.clear();
      _myLocationMarker.clear();
      _isRouteFound = false;
      _lastSearchedGeoJson = null;
      _isSearchCardVisible = true;
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _currentPosition = null;
      _currentInstruction = "경로를 검색해주세요.";
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  void _showRouteInfo() {
    if (_lastSearchedGeoJson == null) return;

    final Map<String, dynamic> decodedJson = jsonDecode(_lastSearchedGeoJson!);
    final features = decodedJson['features'];
    final startNode = features.firstWhere(
          (f) => f['id'] == 'start_node',
      orElse: () => null,
    );

    if (startNode == null) return;

    final properties = startNode['properties'];
    final double totalDistance = properties['totalDistance'] ?? 0.0;
    final int totalTime = properties['totalTime'] ?? 0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '경로 요약 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '총 거리: ${totalDistance.toStringAsFixed(2)}m',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '예상 소요 시간: ${(totalTime / 60).ceil()}분',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: false,
            myLocationButtonEnabled: true,
            polylines: _polylines,
            markers: _routeMarkers.union(_visibleTrashCanMarkers).union(_myLocationMarker),
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
          if (_isRouteFound && _positionStreamSubscription != null)
            Positioned(
              top: 100,
              left: 10,
              right: 10,
              child: Center(
                child: Card(
                  elevation: 4,
                  color: Colors.black.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      _currentInstruction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_isRouteFound)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showRouteInfo,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('경로 정보'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleNavigation,
                      icon: Icon(
                        _positionStreamSubscription == null
                            ? Icons.navigation_outlined
                            : Icons.stop_circle_outlined,
                      ),
                      label: Text(
                        _positionStreamSubscription == null ? '안내 시작' : '안내 중지',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _resetMap,
                      icon: const Icon(Icons.refresh),
                      label: const Text('초기화'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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