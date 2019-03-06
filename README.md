# locate

A Flutter plugin to work with Android Location Services.

## Important Points ::

  - First of all, this flutter plugin **doesn't** work with IOS Location Service. Only Android Location Service is supported.
  - AndroidX enabled.
  - [Kotlin(1.3.21)](https://kotlinlang.org/) is used for implementation of platform side.
  - Google Play Service Location is used to get precise location using both cellular network and GPS.
  ```api 'com.google.android.gms:play-services-location:16.0.0'```
  - AndroidX Core library used for backward compatibility.
  ```api 'androidx.core:core:1.0.1'```
  - CompileSDK and TargetSDK both are v28.
  

## How to use it ???

  Locate class has a singleton based architecture i.e. only a single instance can be created at a time.
  This class has four important methods that you'll be mostly using, which are as follows.
  
  ### requestLocationPermission() :
  
  - At the beginning try calling **requestLocationPermission()**, to check whether location permission is avaible not not.
  - This method takes one optional positional argument *provider*, which defaults to **gps**.
  - I'd recommend you to use **ACCESS_FINE_LOCATION** in your app to get precise location data.
  - So, better you just don't pass any argument to **requestLocationPermission()**.
  - After it completes in **async** fashion, this returns a bool.
  - If you get true, this means user has permitted you to access FINE_LOCATION of Android Device.
  - Else good luck to you ;)
  
  ### enableLocation() :
  
  - So, if you get true, then lets go, to invoke **enableLocation()**, so that we can request user to enable location of device.
  - This also completes in **async** fashion and then returns true or false based on the result of the Activity.
  
  ### startLocationUpdate() :
  
  - If we get true, we're good to call **startLocationUpdate()**.
  - Well this method takes two optional positional parameters.
  - Imagine you have **ACCESS_FINE_LOCATION** permission for your app, then it'd be always better to invoke **startLocationUpdate()**
  as below :
  ```
    startLocationUpdate(locationServiceProvider: LocationServiceProvider.GMSBasedLocation);
  ```
  - Where LocationServiceProvider is a class holding two const properties : **GMSBasedLocation = '0';** & **LocationManagerBasedLocation = '1';**
  
  - For using GooglePlayService based Location use **LocationServiceProvider.GMSBasedLocation**.
  - And for android.location.LocationManager based Location use **LocationServiceProvider.LocationManagerBasedLocation**.
  - Remember it's required to have **ACCESS_FINE_LOCATION** permission in order to user PlayService based Location using **FusedLocationProviderClient**.
  - If you're satisfied with **ACCESS_COARSE_LOCATION**, then request for that permission using
  ``` requestLocationPermission(provider: LocationProvider.Network); ```
  - Well LocationProvider is also a class with two properties.
  ```
  class LocationProvider {
  static const String Network = 'network';
  static const String GPS = 'gps';
  }
  ```
  - After that invoke **startLocationUpdate()** as follows for only network based Location Data.
  ```
    startLocationUpdate(locationServiceProvider: LocationServiceProvider.LocationManagerBasedLocation, locationProvider: LocationProvider.Network);
  ```
  
  - You could also use it as follows, to use platform based LocationManager and **ACCESS_FINE_LOCATION** combination.
  ```
  startLocationUpdate(locationServiceProvider: LocationServiceProvider.LocationManagerBasedLocation, locationProvider: LocationProvider.GPS);
  ```
  
  - If you take a look at implementation of **startLocationUpdate(){}**, you could find out, that I've registered an EventChannel here, which sets a flow of LocationData Update from Platform Level to Locate class.
  - Locate has a private method **_onData(dynamic event){}**, which gets invoked everytime App receive a Location Update from Platform.
  - This method extracts location data and stores current location info in an instance of **MyLocation class**.
  - If some error occurs, **_onError(dynamic error){}** gets invoked.
  
  
  #### How to get this Location Data in you app's StateFulWidget Class and update that widget in dynamic fashion by calling *setState()* ??
  
   So I've added another *abstract class LocationDataCallBack*, which has *onData(Map<String, String> myLocatoin){}*,
  that needs to be overridden wherever we implement **LocationDataCallBack**.
  
  - In example app's, [main.dart](https://github.com/itzmeanjan/locate/blob/master/example/lib/main.dart), I've implemented LocationDataCallBack in the class which extends State class.
  - Now we can simply take the data from the Map<String, String> and update UI.
  - Sample implementation of **onData**
  ```
    @override
  void onData(Map<String, String> myLocation) {
    setState(() {
      myText =
          'Current Location : ${myLocation['longitude']}, ${myLocation['latitude']}\nUpdated at : ${DateTime.fromMillisecondsSinceEpoch(int.parse(myLocation['time'], radix: 10)).toString()}';
    });
  }
  ```
  
  ### stopLocationUpdate() :
  
  - Now it's time to stop Location service. Lets call **stopLocationUpdate()**. And we're good to go.
  
  - Always invoke methods in order while requesting Location Data using Locate.
  
  - Follow the sequence **requestLocationPermission()** -> **enableLocation()** -> **startLocationUpdate()** -> **stopLocationUpdate()**.
  
  - Now you might ask me one question, **how am I supposed to initialize Locate class ?**
  - In **initState()** of your StateFulWidget, where you implemented **LocationDataCallBack**, just create an instance of Locate class by invoking **Locate(this)**.
  - Locate's constructor takes an instance of **LocationDataCallBack**.
  - Because that's what gets callbacked when new location data is available.
  - So it was simple, was't it ???
  
## Example App ::

  Example App written using **locate** can be found [here](https://github.com/itzmeanjan/locate/tree/master/example).


## Getting Started ::

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

## Courtesy ::

Last but not least, thanks to [flutter](http://flutter.dev), [Dartlang](http://dartlang.org/) and all of those persons who were somehow involved in developing such a great ecosystem, which has made the trouble of developing multiplatform apps significantly lesser.


Hope it was helpful :)
