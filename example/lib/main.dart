import 'package:flutter/material.dart';
import 'package:locate/locate.dart';
import 'package:locate/my_location.dart';
import 'package:flutter/services.dart' show SystemChrome;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          textTheme: TextTheme(
            title: TextStyle(
              color: Colors.cyanAccent,
            ),
            subtitle: TextStyle(
              color: Colors.cyan,
            ),
          ),
          accentIconTheme: IconThemeData(
            color: Colors.cyanAccent,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.black,
          ),
          iconTheme: IconThemeData(
            color: Colors.cyanAccent,
          ),
          appBarTheme: AppBarTheme(
              color: Colors.black45,
              actionsIconTheme: IconThemeData(
                color: Colors.red,
              ),
              textTheme: TextTheme(
                  title: TextStyle(
                color: Colors.tealAccent,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              )),
              iconTheme: IconThemeData(
                color: Colors.red,
              )),
          scaffoldBackgroundColor: Colors.black45,
        ),
        title: 'Locate',
        home: MyHome(),
      );
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> with TickerProviderStateMixin {
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
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.restoreSystemUIOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Locate',
          textScaleFactor: 1.5,
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.restore),
              onPressed: () => setState(() => _locationData = [])),
        ],
      ),
      body: _areWeGettingLocationUpdate
          ? _locationData.length == 0
              ? Center(
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.black45,
                    valueColor:
                        Tween<Color>(begin: Colors.cyanAccent, end: Colors.cyan)
                            .animate(
                      AnimationController(
                        vsync: this,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemBuilder: (context, index) => ListTile(
                        title: Text(
                          '${_locationData[index].longitude.roundToDouble()}, ${_locationData[index].latitude.roundToDouble()} with altitude ${_locationData[index].altitude} m',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                          ),
                        ),
                        subtitle: Text(
                          '${_locationData[index].getParsedTimeString()} from ${_locationData[index].provider.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                          ),
                        ),
                        leading: Icon(
                          Icons.location_on,
                          color: Colors.cyanAccent,
                        ),
                      ),
                  itemCount: _locationData.length,
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 12,
                    left: 4,
                    right: 4,
                  ),
                )
          : Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.info_outline),
                  Text(
                    ' No Incoming Location Data Feed',
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                ],
              ),
            ),
      floatingActionButton: Builder(
        builder: (BuildContext ctx) {
          return FloatingActionButton(
            onPressed: () {
              if (!_areWeGettingLocationUpdate)
                _locate.requestLocationPermission().then((bool result) {
                  if (result)
                    _locate.enableLocation().then((bool result) {
                      if (result) {
                        setState(() => _areWeGettingLocationUpdate = true);
                        _locate.getLocationDataFeed()
                          ..listen(
                            (MyLocation data) =>
                                setState(() => _locationData.add(data)),
                            cancelOnError: true,
                            onError: (e) => print(e),
                          );
                      }
                    });
                });
              else
                _locate.stopLocationDataFeed().then((bool result) =>
                    setState(() => _areWeGettingLocationUpdate = false));
            },
            child: _areWeGettingLocationUpdate
                ? Icon(
                    Icons.stop,
                    color: Colors.red,
                  )
                : Icon(
                    Icons.my_location,
                    color: Colors.cyanAccent,
                  ),
            elevation: 12,
            tooltip:
                _areWeGettingLocationUpdate ? 'Stop Location' : 'Get Location',
          );
        },
      ),
    );
  }
}
