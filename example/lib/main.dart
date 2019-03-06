import 'package:flutter/material.dart';
import 'package:locate/locate.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements LocationDataCallBack {
  // implementing LocationDataCallBack is required in order to get live location data feed in onData method.
  // which will eventually update a StateFulWidget by calling setState(), and passing location data to appropriate widgets.

  Locate _locate; // main entry point for retrieving location data
  bool
      _areWeGettingLocationUpdate; // holds state information, helps to change widget appearance and behaviour.
  String myText; // this gets displayed in center of screen

  @override
  void onData(Map<String, String> myLocation) {
    // this method acts as callback for location data update.
    // Try updating your UI here, using received data.
    setState(() {
      myText =
          'Current Location : ${myLocation['longitude']}, ${myLocation['latitude']}\nUpdated at : ${DateTime.fromMillisecondsSinceEpoch(int.parse(myLocation['time'], radix: 10)).toString()}';
    });
  }

  @override
  void initState() {
    // state initialization
    super.initState();
    myText = "I'm Location Data Fetcher :)"; // initial text to display
    _areWeGettingLocationUpdate =
        false; // cause we're not getting any update yet
    _locate = Locate(
        this); // in constructor of Locate class, we are passing instance of abstract class LocationDataCallBack which is implemented in this stateful widget
    // so it's onData method is also overridden with in this class.
  }

  @override
  void dispose() {
    super.dispose();
    if (_areWeGettingLocationUpdate) {
      _locate
          .stopLocationUpdate(); // if we're still receiving location data from platform,
      // request to stop location data is sent.
    }
  }

  void startLocationUpdate() {
    _locate
        .requestLocationPermission(provider: LocationProvider.GPS)
        .then((bool val1) {
      if (val1) {
        _locate.enableLocation().then((bool val2) {
          if (val2) {
            _locate
                .startLocationUpdate(
                    locationServiceProvider:
                        LocationServiceProvider.GMSBasedLocation)
                .then((bool val3) {
              if (val3) {
                setState(() {
                  _areWeGettingLocationUpdate = true;
                  myText = 'Started Location Update';
                });
              }
            });
          }
        });
      }
    });
  }

  void stopLocationUpdate() {
    _locate.stopLocationUpdate().then((bool val) {
      if (val) {
        setState(() {
          _areWeGettingLocationUpdate = false;
          myText = 'Stopped Location Update';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Locate Example'),
          textTheme: TextTheme(title: TextStyle(color: Colors.black)),
          backgroundColor: Colors.cyanAccent,
        ),
        body: Center(
          child: Text(
            myText,
            maxLines: 2,
            overflow: TextOverflow.fade,
          ),
        ),
        floatingActionButton: Builder(
          builder: (BuildContext ctx) {
            return FloatingActionButton(
              onPressed: _areWeGettingLocationUpdate
                  ? stopLocationUpdate
                  : startLocationUpdate,
              child: _areWeGettingLocationUpdate
                  ? Icon(
                      Icons.stop,
                      color: Colors.red,
                    )
                  : Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
              backgroundColor: _areWeGettingLocationUpdate
                  ? Colors.white
                  : Colors.cyanAccent,
              elevation: 12,
              tooltip: _areWeGettingLocationUpdate
                  ? 'Stop Location'
                  : 'Get Location',
            );
          },
        ),
      ),
    );
  }
}
