import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/restroom_model.dart';

class NavigationPage extends StatefulWidget {
  final RestroomModel restroom;
  const NavigationPage({super.key, required this.restroom});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  
  LatLng? _currentPosition;
  List<LatLng> _polylineCoordinates = [];
  String _distance = '';
  String _duration = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndRoute();
  }

  Future<void> _getCurrentLocationAndRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _getPolyline();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not get your location. Please check GPS settings.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getPolyline() async {
    if (_currentPosition == null) return;

    // Fetch API key from .env file
    final String apiKey = dotenv.get('GOOGLE_MAPS_API_KEY_ANDROID', fallback: '');

    if (apiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'API Key not found in .env file.';
          _isLoading = false;
        });
      }
      return;
    }

    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&'
        'destination=${widget.restroom.latitude},${widget.restroom.longitude}&'
        'mode=walking&'
        'key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          if (mounted) {
            setState(() {
              _distance = leg['distance']['text'];
              _duration = leg['duration']['text'];
              _polylineCoordinates = _decodePolyline(route['overview_polyline']['points']);
              _isLoading = false;
            });
            _fitMapToRoute();
          }
        } else {
          debugPrint('Directions API error: ${data['status']}');
          debugPrint('Error Message: ${data['error_message']}');
          
          String msg = 'Directions unavailable';
          if (data['status'] == 'REQUEST_DENIED') {
            msg = 'API Access Denied. Ensure Directions API is enabled and Billing is active.';
            // Add technical hint if available
            if (data['error_message'] != null) {
              msg += '\n\nDetail: ${data['error_message']}';
            }
          } else if (data['status'] == 'ZERO_RESULTS') {
            msg = 'No walking path found to this location.';
          }
          
          if (mounted) {
            setState(() {
              _errorMessage = msg;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error (${response.statusCode}). Please try again later.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fitMapToRoute() async {
    final GoogleMapController controller = await _mapController.future;
    if (_polylineCoordinates.isEmpty) return;

    double minLat = _polylineCoordinates.first.latitude;
    double minLng = _polylineCoordinates.first.longitude;
    double maxLat = _polylineCoordinates.first.latitude;
    double maxLng = _polylineCoordinates.first.longitude;

    for (var point in _polylineCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      100,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${widget.restroom.restroomName}'),
        backgroundColor: const Color(0xFFA8D5D5),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.restroom.latitude, widget.restroom.longitude),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            polylines: {
              if (_polylineCoordinates.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _polylineCoordinates,
                  color: const Color(0xFFEC9B9B),
                  width: 5,
                ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(widget.restroom.latitude, widget.restroom.longitude),
                infoWindow: InfoWindow(
                  title: widget.restroom.restroomName,
                  snippet: _distance.isNotEmpty ? '$_distance • $_duration away' : null,
                ),
              ),
            },
          ),
          
          if (_distance.isNotEmpty && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFF5D4D4),
                      child: Icon(Icons.directions_walk, color: Color(0xFFEC9B9B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Estimated Arrival',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$_duration ($_distance)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFA8D5D5))),
            
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        const Text(
                          'Navigation Error',
                          style: TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _getCurrentLocationAndRoute(),
        backgroundColor: const Color(0xFFA8D5D5),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
