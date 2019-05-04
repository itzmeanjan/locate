import 'dart:async' show StreamController;
import 'package:flutter/services.dart'
    show MethodChannel, EventChannel, PlatformException;
import 'my_location.dart';

class Locate {
  // Bridge between Platform level & Flutter
  MethodChannel _methodChannel;

  // Helps us to get a stream of location data feed from platform.
  EventChannel _eventChannel;

  // location service state holder, the name is descriptive enough
  bool _areWeGettingLocationUpdate;

  /// Main class, which does all heavy liftings, requests location permission, enables location and finally gets you location data feed in Stream<MyLocation> format
  Locate() {
    _methodChannel =
        const MethodChannel('io.github.itzmeanjan.locate.methodChannel');
    _areWeGettingLocationUpdate = false;
  }

  Future<bool> requestLocationPermission(
      {String provider: LocationProvider.GPS}) async {
    // whenever you require location data, first make sure you have called this method,
    // to check whether location permission is available or not.
    // if permission is already granted, it'll simply return true
    // is runtime permission is denied by user, it'll return false.
    // decision to perform further operation needs to be taken by watching this methods result
    // well it's async ;)
    try {
      return await _methodChannel.invokeMethod(
          'requestLocationPermission', <String, int>{
        'id': provider == LocationProvider.GPS ? 0 : 1
      }).then((dynamic result) => result == 1 ? true : false);
    } on PlatformException {
      return false;
    }
  }

  /// As you've already got permission from user to access device location,
  /// Lets get to enabling location
  /// If user accepts the request to enable android device location
  /// We get true in return else false
  Future<bool> enableLocation() async {
    try {
      return await _methodChannel
          .invokeMethod('enableLocation')
          .then((dynamic result) => result == 1 ? true : false);
    } on PlatformException {
      return false;
    }
  }

  /// We start location data feed request here.
  /// This method takes two optional positional parameters `locationServiceProvider` and `locationProvider`
  /// `locationServiceProvider` -> which is nothing but location service provider selector
  /// i.e. whether to get location data by using GoogleMobileServices based Fused Location Provider
  /// or platform based LocationManager
  /// `locationProvider` -> which identifies what kind of location service i.e. GPS/ Network, to use
  /// when we want to get platform's LocationManager based Location data.
  /// in case of GMSBasedLocationService, no need to send this parameter
  /// *** Remember one important thing, GMSBasedLocationService requires Access_Fine_Location permission.***
  Stream<MyLocation> getLocationDataFeed(
      {String locationServiceProvider:
          LocationServiceProvider.LocationManagerBasedLocation,
      String locationProvider: LocationProvider.GPS}) {
    StreamController streamController;

    MyLocation extractLocationData(dynamic event) => MyLocation(
        event['longitude'],
        event['latitude'],
        DateTime.fromMillisecondsSinceEpoch(event['time'], isUtc: true),
        event['altitude'],
        event['bearing'],
        event['speed'],
        event['accuracy'],
        event['verticalAccuracy'],
        event['bearingAccuracy'],
        event['speedAccuracy'],
        event['provider'],
        event['satelliteCount']);

    onData(dynamic event) {
      if (!streamController.isClosed && !streamController.isPaused)
        streamController.add(extractLocationData(event));
    }

    stop() => streamController.close();

    cancel() async {
      try {
        await _methodChannel.invokeMethod('stopLocationUpdate').then((result) {
          if (result == 1) {
            _eventChannel = null;
            _areWeGettingLocationUpdate = false;
          }
        });
      } on PlatformException {} finally {
        stop();
      }
    }

    init() {
      try {
        if (!gettingLocationUpdate()) {
          _eventChannel =
              const EventChannel('io.github.itzmeanjan.locate.eventChannel');
          _methodChannel.invokeMethod('startLocationUpdate', <String, String>{
            'locationServiceProvider': locationServiceProvider,
            'locationProvider': locationProvider
          }).then((dynamic result) {
            if (result == 1) {
              _eventChannel.receiveBroadcastStream().listen(
                    onData,
                    onError: () => streamController
                        .addError("Error: Can't Get Location Data"),
                  ); // registers broadcastListener
              _areWeGettingLocationUpdate = true;
            }
          });
        }
      } on PlatformException {
        stop();
      }
    }

    if (!gettingLocationUpdate()) {
      streamController = StreamController<MyLocation>(
        onCancel: cancel,
        onListen: init,
      );
    }

    return streamController.stream;
  }

  /// If you need to know whether we're still getting location data, this can be queried by calling this method
  bool gettingLocationUpdate() => _areWeGettingLocationUpdate;
}

/// How to get Location data from system, either using android location manager or using google mobile service base location mamager
class LocationServiceProvider {
  static const String GMSBasedLocation = '0';
  static const String LocationManagerBasedLocation = '1';
}

/// Location data provider identifier, either GPS and Network based fine location data or Network based coarse location data
class LocationProvider {
  static const String Network = 'network';
  static const String GPS = 'gps';
}
