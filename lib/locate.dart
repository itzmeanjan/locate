import 'dart:async' show StreamController;
import 'package:flutter/services.dart'
    show MethodChannel, EventChannel, PlatformException;
import 'my_location.dart';
import 'dart:async' show Completer;
import 'locationProvider.dart';
import 'locationServiceProvider.dart';

class Locate {
  /// Bridge between Platform level & Flutter
  MethodChannel _methodChannel;

  /// Helps us to get a stream of location data feed from platform.
  EventChannel _eventChannel;

  /// location service state holder, the name is descriptive enough
  bool _areWeGettingLocationUpdate;

  /// Controls location data flow from API endpoint
  StreamController streamController;

  /// Main class, which does all heavy lifting, requests location permission, enables location and finally gets you location data feed in Stream<MyLocation> format
  Locate() {
    _methodChannel =
        const MethodChannel('io.github.itzmeanjan.locate.methodChannel');
    _areWeGettingLocationUpdate = false;
  }

  /// whenever you require location data, first make sure you have called this method,
  /// to check whether location permission is available or not.
  /// if permission is already granted, it'll simply return true
  /// is runtime permission is denied by user, it'll return false.
  /// decision to perform further operation needs to be taken by watching this methods result
  /// well it's async ;)
  Future<bool> requestLocationPermission(
      {String provider: LocationProvider.GPS}) async {
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

    /// closes stream of data
    stop() => streamController.close();

    /// cancels location update and closes stream of location data
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

    /// initializes location data feed subscription
    init() {
      try {
        if (!areWeGettingLocationUpdate()) {
          _eventChannel =
              const EventChannel('io.github.itzmeanjan.locate.eventChannel');
          _methodChannel.invokeMethod('startLocationUpdate', <String, String>{
            'locationServiceProvider': locationServiceProvider,
            'locationProvider': locationProvider
          }).then((dynamic result) {
            if (result == 1) {
              _eventChannel.receiveBroadcastStream().listen(
                    onData,
                    onError: (e) => streamController
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

    if (!areWeGettingLocationUpdate()) {
      streamController = StreamController<MyLocation>(
        onCancel: cancel,
        onListen: init,
      );
    }

    return streamController.stream;
  }

  /// Stops live location data feed from Platform
  Future<bool> stopLocationDataFeed() {
    var completer = Completer<bool>();
    try {
      _methodChannel.invokeMethod('stopLocationUpdate').then((result) {
        if (result == 1) {
          _eventChannel = null;
          _areWeGettingLocationUpdate = false;
          completer.complete(true);
        }
      });
    } on PlatformException {
      streamController.close();
      completer.complete(false);
    }
    return completer.future;
  }

  /// If you need to know whether we're still getting location data, this can be queried by calling this method
  bool areWeGettingLocationUpdate() => _areWeGettingLocationUpdate;
}
