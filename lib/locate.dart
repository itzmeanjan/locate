import 'dart:async';
import 'package:flutter/services.dart';
import 'my_location.dart';

class Locate {
  static Locate _locate;
  factory Locate(LocationDataCallBack callBack) {
    // this class uses singleton architecture
    // i.e. you can't create multiple instances of this class
    if (_locate == null) _locate = Locate._internal(callBack);
    return _locate;
  }

  Locate._internal(this._locationDataCallBack); // this is the constructor now

  LocationDataCallBack _locationDataCallBack;

  static const MethodChannel _methodChannel =
      const MethodChannel('com.example.itzmeanjan.locate.methodChannel');

  EventChannel _eventChannel; // now this is an interesting part
  // it helps us to get a stream of location data from platform.

  bool _areWeGettingLocationUpdate =
      false; // location service state holder, the name is descriptive enough

  MyLocation _currentLocation = MyLocation(
      // this class holds current location data
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null);

  Future<bool> requestLocationPermission({String provider: 'gps'}) async {
    // whenever you require location data, first make sure you have called this method,
    // to check whether location permission is available or not.
    // if permission is already granted, it'll simply return true
    // is runtime permission is denied by user, it'll return false.
    // decision to perform further operation needs to be taken by watching this methods result
    // well it's async ;)
    try {
      return await _methodChannel.invokeMethod(
          'requestLocationPermission', <String, int>{
        'id': provider == 'gps' ? 0 : 1
      }).then((dynamic result) => result == 1 ? true : false);
    } on PlatformException {
      return false;
    }
  }

  Future<bool> enableLocation() async {
    // as you've already got permission from user to access device location,
    // lets get to enabling location
    // if user accepts the request to enable android device location
    // we get true in return else false
    try {
      return await _methodChannel
          .invokeMethod('enableLocation')
          .then((dynamic result) => result == 1 ? true : false);
    } on PlatformException {
      return false;
    }
  }

  void _onData(dynamic event) {
    // updating location data holder
    _currentLocation.longitude = event['longitude'];
    _currentLocation.latitude = event['latitude'];
    _currentLocation.time =
        DateTime.fromMillisecondsSinceEpoch(event['time'], isUtc: true);
    _currentLocation.altitude = event['altitude'];
    _currentLocation.bearing = event['bearing'];
    _currentLocation.speed = event['speed'];
    _currentLocation.accuracy = event['accuracy'];
    _currentLocation.verticalAccuracy = event['verticalAccuracy'];
    _currentLocation.bearingAccuracy = event['bearingAccuracy'];
    _currentLocation.speedAccuracy = event['speedAccuracy'];
    _currentLocation.provider = event['provider'];
    _currentLocation.satelliteCount = event['satelliteCount'];
    _locationDataCallBack.onData({
      // sends data back to listener, in form of Map<String, String>
      'longitude': _currentLocation.longitude.toString(),
      'latitude': _currentLocation.latitude.toString(),
      'time': _currentLocation.time.millisecondsSinceEpoch.toString(),
      'altitude': _currentLocation.altitude.toString(),
      'bearing': _currentLocation.bearing.toString(),
      'speed': _currentLocation.speed.toString(),
      'accuracy': _currentLocation.accuracy.toString(),
      'verticalAccuracy': _currentLocation.verticalAccuracy.toString(),
      'bearingAccuracy': _currentLocation.bearingAccuracy.toString(),
      'speedAccuracy': _currentLocation.speedAccuracy.toString(),
      'provider': _currentLocation.provider,
      'satelliteCount': _currentLocation.satelliteCount.toString()
    });
  }

  void _onError(dynamic error) {
    //doing nothing useful yet
    print('[!]Something went wrong');
  }

  Future<bool> startLocationUpdate(
      {String locationServiceProvider: '1',
      String locationProvider: 'gps'}) async {
    // we start location update request here.
    // this method takes two optional positional parameters `locationServiceProvider` and `locationProvider`
    // `locationServiceProvider` -> which is nothing but location service provider selector
    // i.e. whether to get location data by using GoogleMobileServices based Fused Location Provider
    // or platform based LocationManager
    // `locationProvider` -> which identifies what kind of location service i.e. GPS/ Network, to use
    // when we want to get platform's LocationManager based Location data.
    // in case of GMSBasedLocationService, no need to send this parameter
    // remember one important thing, GMSBasedLocationService requires Access_Fine_Location permission.
    try {
      if (_areWeGettingLocationUpdate)
        return false; // if already getting location data, just
      _eventChannel = // eventChannel is established
          const EventChannel('com.example.itzmeanjan.locate.eventChannel');
      // be careful to keep this eventChannelName same in both sides, platform side and DartSide
      return await _methodChannel
          .invokeMethod('startLocationUpdate', <String, String>{
        'locationServiceProvider': locationServiceProvider,
        'locationProvider': locationProvider
      }).then((dynamic result) {
        // platform method gets invoked, where also eventChannel is set up.
        if (result == 1) {
          _eventChannel.receiveBroadcastStream().listen(_onData,
              onError: _onError); // registers broadcastListener
          // whenever data comes in, it calls _onData, which eventually calls locationDataCallBack, after extracting data
          _areWeGettingLocationUpdate = true;
          return true;
        }
        return false;
      });
    } on PlatformException {
      return false;
    }
  }

  Future<bool> stopLocationUpdate() async {
    // at last location service can be stopped by calling this method.
    try {
      if (!_areWeGettingLocationUpdate) return false;
      return await _methodChannel
          .invokeMethod('stopLocationUpdate')
          .then((dynamic result) {
        // platform method invocation, to stop location service
        if (result == 1) {
          _eventChannel = null; // eventChannel is destroyed
          _areWeGettingLocationUpdate = false;
          return true;
        }
        return false;
      });
    } on PlatformException {
      return false;
    }
  }

  bool gettingLocationUpdate() {
    // if you need to know whether we're still getting location data, this can be queried by calling this method
    return _areWeGettingLocationUpdate;
  }
}

abstract class LocationDataCallBack {
  // this is a very important class
  // you need to implement this class in one StateFulWidget, where you'd like to get the location data feed.
  // then you have to also override this below method called onData().
  // which will receive current Location in form of Map<String, String>
  // UI updating in StateFulWidget can be performed by calling setState() from overridden onData().
  void onData(Map<String, String> myLocation) {}
}

class LocationServiceProvider {
  // simple data holder class
  static const String GMSBasedLocation = '0';
  static const String LocationManagerBasedLocation = '1';
}

class LocationProvider {
  static const String Network = 'network';
  static const String GPS = 'gps';
}
