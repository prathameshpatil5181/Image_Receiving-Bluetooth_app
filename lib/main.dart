import 'package:bluetoothapp/BluetoothDeviceListEntry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:bluetoothapp/detailpage.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  List<BluetoothDevice>devices = <BluetoothDevice>[];

  @override
  void initState() {
    // TODO: implement initState
    print("init");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("init 2");
    _getBTState();
    _stateChangeListner();
  }

  @override
  void dispose(){
    print("here dispose");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _listBondedDevices();
    }
  }

  _getBTState() {
    print("here get");
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
      if(_bluetoothState.isEnabled){
        _listBondedDevices();
      }
      setState(() {});
    });
  }

  _stateChangeListner() {
    print("state");
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      _bluetoothState = state;
      if(_bluetoothState.isEnabled){
      _listBondedDevices();
      }
      else{
        devices.clear();
      }
      print("State isEnabled: ${state.isEnabled}");
      setState(() {});
    });
  }

  _listBondedDevices() {
    FlutterBluetoothSerial.instance.getBondedDevices().then((
        List<BluetoothDevice> bondedDevices) {
      devices = bondedDevices;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Photo Reciever")
        ),
        body: Container(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                    title: Text('Enable Bluetooth'),
                    value: _bluetoothState.isEnabled,
                    onChanged: (bool value) {
                      future() async {
                        if (value) {
                          await FlutterBluetoothSerial.instance
                              .requestEnable();
                        } else {
                          await FlutterBluetoothSerial.instance
                              .requestDisable();
                        }
                      }
                      future().then((_) {
                        setState(() {});
                      });
                    }),
                ListTile(
                  title: Text("Bluetooth Status"),
                  subtitle: Text(_bluetoothState.toString()),
                  trailing: MaterialButton(
                      child: Text("Settings"),
                      onPressed: () {
                        FlutterBluetoothSerial.instance.openSettings();
                      },
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: devices
                        .map((_device) => BluetoothDeviceListEntry(
                      device: _device,
                      enabled: true,
                      onTap: () {
                        print("Item");
                        _startCameraConnect(context, _device);
                      },
                    ))
                        .toList(),
                  ),
                )
              ],
            ),
        ),
    );

  }
  void _startCameraConnect(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return DetailPage(server: server);
    }));
  }
}
