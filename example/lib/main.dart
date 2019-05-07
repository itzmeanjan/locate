import 'package:flutter/material.dart';
import 'package:locate/locate.dart';
import 'package:locate/my_location.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locate _locate; // main entry point for retrieving location data
  bool
      _areWeGettingLocationUpdate; // holds state information, helps to change widget appearance and behaviour
  List<MyLocation> _locationData;

  @override
  void initState() {
    super.initState();
    _locate = Locate();
    _areWeGettingLocationUpdate = false;
    _locationData = [];
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
        body: ListView.builder(
          itemBuilder: (context, index) => ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Icon(Icons.location_on),
                    Expanded(
                      child: Text(
                          '${_locationData[index].longitude}, ${_locationData[index].latitude} at ${_locationData[index].altitude}m'),
                    ),
                  ],
                ),
                subtitle: Text(_locationData[index].getParsedTimeString()),
              ),
          itemCount: _locationData.length,
          padding: EdgeInsets.all(6),
        ),
        floatingActionButton: Builder(
          builder: (BuildContext ctx) {
            return FloatingActionButton(
              onPressed: () {
                if (!_areWeGettingLocationUpdate)
                  _locate.requestLocationPermission().then((bool result) {
                    if (result)
                      _locate.enableLocation().then((bool result) {
                        if (result)
                          _locate.getLocationDataFeed()
                            ..listen(
                              (MyLocation data) =>
                                  setState(() => _locationData.add(data)),
                              cancelOnError: true,
                              onError: (e) => print(e),
                            );
                      });
                  });
                else
                  _locate.stopLocationDataFeed().then((bool result) {
                    print(result
                        ? 'Stopped location data feed'
                        : 'failed to stop location data feed');
                  });
              },
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
