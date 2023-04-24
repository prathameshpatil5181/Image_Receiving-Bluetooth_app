import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:photo_view/photo_view.dart';

const List<String> list = <String>['One', 'Two and', 'Three', 'Four'];

class DetailPage extends StatefulWidget {
  final BluetoothDevice server;

  const DetailPage({required this.server});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;

  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  late String _selectedFrameSize;
  late String base64Image = '';
  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  Uint8List? _bytes;

  RestartableTimer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedFrameSize = 'One';
    _getBTConnection();
    _timer = new RestartableTimer(Duration(seconds: 1), _drawImage);
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    _timer?.cancel();
    super.dispose();
  }

  void _getBTConnection() {
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      isConnecting = false;
      isDisconnecting = false;
      setState(() {});
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally');
        } else {
          print('Disconnecting remotely');
        }
        if (this.mounted) {
          setState(() {});
        }
        Navigator.of(context).pop();
      });
    }).catchError((error) {
      Navigator.of(context).pop();
    });
  }

  _drawImage() {
    if (chunks.length == 0 || contentLength == 0) return;

    print("printing base64 string");
    print(base64Image);
    print(base64Image.length);
    print("receiving data");
    print(contentLength);
    _bytes = Uint8List(contentLength);
    int offset = 0;
    _bytes = base64.decode(base64Image);
    print(_bytes?.length);
    // for (final List<int> chunk in chunks) {
    //   _bytes?.setRange(offset, offset + chunk.length, chunk);
    //   // print(chunks);
    //   offset += chunk.length;
    // }

    print(offset);
    setState(() {});

    SVProgressHUD.show();
    SVProgressHUD.dismiss(delay: Duration(milliseconds: 2000));
    contentLength = 0;
    chunks.clear();
  }

  void _onDataReceived(Uint8List data) {
    if (data != null && data.length > 0) {
      chunks.add(data);
      contentLength += data.length;
      base64Image += utf8.decode(data);
      _timer?.reset();
    }

    print("Data Length: ${data.length}, chunks: ${chunks.length}");
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text)));
        print("printing the sending message");
        print(text);
        print(utf8.encode(text));
        // SVProgressHUD.show();
        await connection?.output.allSent;
      } catch (e) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ${widget.server.name} ...')
              : isConnected
                  ? Text('Connected with ${widget.server.name}')
                  : Text('Disconnected with ${widget.server.name}')),
        ),
        body: SafeArea(
          child: isConnected
              ? Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        selectFrameSize(),
                        shotButton(),
                      ],
                    ),
                    photoFrame(),
                  ],
                )
              : const Center(
                  child: Text(
                    "Connecting...",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
        ));
  }

  Widget photoFrame() {
    return Expanded(
      child: Container(
        width: double.infinity,
        child: _bytes != null
            ? PhotoView(
                enableRotation: true,
                initialScale: PhotoViewComputedScale.covered,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                minScale: PhotoViewComputedScale.contained * 0.8,
                imageProvider:
                    Image.memory(_bytes!, fit: BoxFit.fitWidth).image,
              )
            : Container(),
      ),
    );
  }

  Widget shotButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.red)),
        onPressed: () {
          base64Image = '';
          _sendMessage(_selectedFrameSize);
        },
        color: Colors.red,
        textColor: Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Request',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget selectFrameSize() {
    return Container(
        margin: const EdgeInsets.all(16.0),
        width: 150,
        height: 50,
        child: DropdownButton<String>(
          value: _selectedFrameSize,
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          iconEnabledColor: Colors.deepPurpleAccent,
          isExpanded: true,
          onChanged: (String? value) {
            // This is called when the user selects an item.
            setState(() {
              _selectedFrameSize = value!;
            });
          },
          items: list.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ));
  }
}
