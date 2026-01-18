import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

class LocationService {
  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    if (kIsWeb) {
      return _getAddressFromWeb(latitude, longitude);
    }
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a nice address string
        String address = "";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += "${place.subLocality}, ";
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += "${place.locality}";
        }
        return address.isNotEmpty ? address : "Unknown Location";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Unknown Location";
  }

  static Future<String> _getAddressFromWeb(double latitude, double longitude) async {
    try {
      final dio = Dio();
      // Using OpenStreetMap Nominatim (Free, but slow/limited)
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': latitude,
          'lon': longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'FoodDeliveryApp/1.0',
          },
        ),
      );

      if (response.data != null && response.data['address'] != null) {
        final address = response.data['address'];
        final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? '';
        final city = address['city'] ?? address['town'] ?? address['state'] ?? '';
        
        if (suburb.isNotEmpty && city.isNotEmpty) {
          return "$suburb, $city";
        } else if (city.isNotEmpty) {
          return city;
        }
      }
    } catch (e) {
      print("Web geocoding error: $e");
    }
    return "Unknown (Web)";
  }
}
