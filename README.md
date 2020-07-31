![logotype-horizontal](./logo/logotype-horizontal.png)

# locate

A Flutter plugin to fetch GPS/ Network based Location Data Feed on Android.

**This flutter plugin is readily availble for [use](https://pub.dev/packages/locate).** 

# intro

`locate` can be used on Android for fetching Location Data Feed.

Two location service providers are available

- Google Mobile Services i.e. GMS based _FusedLocationProvider_ **( this is recommended )**
- Standard Android _LocationManager_ **( in this case you get freedom to choose which provider to use )**
  - Network provider
  - GPS provider

It has **androidX** support, along with latest version of all dependencies.

# installation

- Add `locate` as dependency in in your flutter project's pubspec.yaml

```yaml
dependencies:
  locate: ^1.1.0
```

- Fetch flutter packages from pub.dev

```bash
$ flutter pub get
```

- Import `locate` in your dart code & start getting location data feed

```dart
import 'package:locate/locate.dart';
```

# usage

## permission

- First thing first, add permission declaration in your project's `AndroidManifest.xml`.

  - If you're planning to use Google Mobile Services based _FusedLocationProvider_, request for *ACCESS_FINE_LOCATION*, which automagically selects location data source for you.
  - Otherwise you may only request for 
    - *ACCESS_FINE_LOCATION* _( GPS based location data )_
    - *ACCESS_COARSE_LOCATION* _( Network based location data )_

```xml
<uses-permission android:name="android.permission.ACCESS_{FINE, COARSE}_LOCATION"/>
```

## API

- Get an intance of *Locate*.

```dart
var _locate = Locate();
```

- Let's first request Location Access Permission from user.

```dart
_locate.requestLocationPermission().then((bool result) {
                  if (result)
                    // we're good to go
                  else
                    // let user know it's required
                  });
```

- Time to enable Location.

```dart
_locate.enableLocation().then((bool result) {
                      if (result) {
                        // update UI & request *locate* for location Data
                        setState(() => _areWeGettingLocationUpdate = true);
                        // Location data will be fetched and delivered as Stream<MyLocation>
                      else
                        // user didn't enable location
                      }
                    });
```

- Now we start getting Location Data Feed.

```dart
_locate.getLocationDataFeed()
                          ..listen(
                            // we listen for location data, which is received as stream
                            (MyLocation data) =>
                                setState(() => _locationData.add(data)), // as soon as data received, will update UI/ perform some other task using location data.
                            cancelOnError: true,
                            onError: (e) => print(e),
                          );
```

- Aah I just forgot to mention one thing, *how to stop listening location update ?*

```dart
_locate.stopLocationDataFeed().then((bool result) {
  // do some UI updation kind of work/ or something else
});
```

## what's in **MyLocation** class ?

- *MyLocation* class can be thought of as a Location Data container & manipulator.

```dart
/// constructor of MyLocation
MyLocation(
      this.longitude,
      this.latitude,
      this.time, // in DateTime
      this.altitude, // in meters
      this.bearing, // in degree
      this.speed, // in meters/s
      this.accuracy, // in meters
      this.verticalAccuracy, // in meters
      this.bearingAccuracy, // in meters
      this.speedAccuracy, // in meters/s
      this.provider, // as String,either gps/ network/ fused
      this.satelliteCount);
```

- I've added some companion methods which can be used from *MyLocation*, such as 

```dart
// will fetch you name of direction of movement from bearing value
bearingToDirectionName();

// m/s to km/h converion for speedaccuracy
getSpeedAccuracyInKiloMetersPerHour();

/// same as above, but works on speed
getSpeedInKiloMetersPerHour();

/// displays time in pretty format
getParsedTimeString();
```

## example

Here's an [example](./example) application using all these API(s).

# notes

You can also set some optional named parameters while invoking methods from *Locate* class.

While requesting permission, you can set *provider*
  - *LocationProvider.Network*, if you want to use Network based Location
  - *LocationProvider.GPS*, if you want to use GPS based Location **[ default ]**

Before requesting Location Data Feed, you can also set via which location manager to fetch data and location data provider name.

  - For `LocationServiceProvider.GMSBasedLocation`, make sure you've declared & requested for permission of accessing FINE Location.
  - Otherwise for `LocationServiceProvider.LocationManagerBasedLocation` as `locationServiceProvider`, you may use any of them, depending upon your declared & requested permissions. 
    - `LocationProvider.GPS`
    - `LocationProvider.Network`
