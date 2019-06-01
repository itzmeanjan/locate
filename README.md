<p align="center"><img src="/logo/logotype-horizontal.png"></p>

# locate

A Flutter plugin to work with Android Location Services(GPS/ Network).

**This flutter plugin is readily availble for [use](https://pub.dev/packages/locate).** 

## usage

This flutter plugin can be used on Android for fetching Location Data using either Google Play Services based Location or LocationManager based Location.

Well this plugin is has **androidX** support enabled.

Even you can specify whether to use Network provider or GPS provider as Location Data Provider.

Don't forget to add following permission in you AndroidManifest.xml.

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

If you're planning to use Google Play Services based FusedLocationProvider, request for *ACCESS_FINE_LOCATION*.

Otherwise you may only request for *ACCESS_COARSE_LOCATION*.

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```


### how to use API

Get an intance of *Locate* class.

```dart
var _locate = Locate();
```

Make sure you first request for Location Permission from user.


```dart
_locate.requestLocationPermission().then((bool result) {
                  if (result)
                    // we're good to go
                  else
                    // you may be interested in letting user know about it, that location access permission is required
                  });
```

Now time to enable Location.

```dart
_locate.enableLocation().then((bool result) {
                      if (result) {
                        // setState(() => _areWeGettingLocationUpdate = true);
                        // here you may be interested in updating UI and the request for location Data.
                        // Location data will be fetched and delivered as Stream<MyLocation>
                      else
                        // user didn't enable location
                      }
                    });
```

And finally, let's request for getting Location Data Feed.

```dart
_locate.getLocationDataFeed()
                          ..listen(
                            // we listen for location data, which is received as stream
                            (MyLocation data) =>
                                setState(() => _locationData.add(data)), // as soon as data received,will update UI/ perform some other task using location data.
                            cancelOnError: true, // if some error occurs, Stream will be closed
                            onError: (e) => print(e), // error is displayed
                          );
```

Aah I just forgot to mention one thing, how to stop listening location update.

```dart
_locate.stopLocationDataFeed().then((bool result) {
  // do some UI updation kind of work/ or something else
});
```

### what's MyLocation

*MyLocation* class can be thought of as a Location Data Container.


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

I've added some companion methods which can be used from *MyLocation*, such as 


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

## important points

You can also set some optional named parameters while invoking methods from *Locate* class.

In case of following method, you can also set *provider*, to be *LocationProvider.Network*, if you want to use Network based Location only.

```dart
requestLocationPermission(
      {String provider: LocationProvider.GPS}); // default value is LocationProvider.GPS
```

Before requesting Location Data Feed, you can also set via which location manager to fetch data and location data provider name.

**Note:: If you are planning use LocationServiceProvider.GMSBasedLocation, for fetching data, make sure you've requested for permission of accessing FINE Location. And also use LocationProvider.GPS as locationProvider parameter's value.** 

Otherwise while using *LocationServiceProvider.LocationManagerBasedLocation* as locationServiceProvider, you may either use *LocationProvider.GPS* or *LocationProvider.Network*, depending upon your requested permissions.

```dart
getLocationDataFeed(
      {String locationServiceProvider:
          LocationServiceProvider.LocationManagerBasedLocation,
      String locationProvider: LocationProvider.GPS});
```

If you've FINE Location access permission, you can simply request for Network Provider based location data.


Hope it was helpful.

Show some <3, to this venture, by putting star on GitHub.
