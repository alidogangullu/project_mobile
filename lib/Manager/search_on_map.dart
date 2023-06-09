/*
import 'dart:convert';
import 'package:project_mobile/Manager/nearby_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SearchOnMap extends StatefulWidget {
  const SearchOnMap({super.key});

  @override
  State<SearchOnMap> createState() => _SearchOnMapState();
}

class _SearchOnMapState extends State<SearchOnMap> {
  String apiKey = 'AIzaSyALegH2yH-If8_Gkshob13fKzdHjQ4oxuc';
  String radius = "50";

  dynamic latitude = 31.5111093;
  dynamic longtiude = 74.27964;

  NearbyPlacesResponse nearbyPlacesResponse = NearbyPlacesResponse();
  late GoogleMapController googleMapController;

  static const CameraPosition initialCameraPosition =
      CameraPosition(target: LatLng(37.4272131123, -122.434533453), zoom: 14);

  Set<Marker> markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yakın Yerler"),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: markers,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          googleMapController = controller;
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: const Text("Buton 2"),
            onPressed: () async {
              getNearbyPlaces();

              Position position = await _determinePosition();

              googleMapController.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(position.latitude, position.longitude),
                      zoom: 14)));

              markers.clear();

              markers.add(
                Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: LatLng(position.latitude, position.longitude)),
              );
            },
            label: const Text("Yakın Yerleri Bul"),
            icon: const Icon(Icons.person),
          )
        ],
      ),
    );
  }

  void getNearbyPlaces() async {
    Position position = await _determinePosition();
    var url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=' +
            position.latitude.toString() +
            ',' +
            position.longitude.toString() +
            '' +
            '&radius=' +
            radius +
            '&key=' +
            apiKey);

    var response = await http.post(url);

    nearbyPlacesResponse =
        NearbyPlacesResponse.fromJson(jsonDecode(response.body));

    setState(() {
      if (nearbyPlacesResponse.results != null) {
        for (int i = 0; i < nearbyPlacesResponse.results!.length; i++) {
          markers.add(Marker(
              markerId: MarkerId(nearbyPlacesResponse.results![i].placeId!),
              position: LatLng(
                  nearbyPlacesResponse.results![i].geometry!.location!.lat!,
                  nearbyPlacesResponse.results![i].geometry!.location!.lng!),
              infoWindow: InfoWindow(
                  title: nearbyPlacesResponse.results![i].name,
                  snippet: nearbyPlacesResponse.results![i].vicinity)));
        }
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error("Yer Lokasyonu Devre Dışı");
    }
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("Yer Lokasyon İzni Rededildi");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Yer Lokasyon izni sonsuze dek reddedildi");
    }

    Position position = await Geolocator.getCurrentPosition();

    return position;
  }
}
 */