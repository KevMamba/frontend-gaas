import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:async';
import 'dart:typed_data';
import 'signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:convert';

class DataChannelSample extends StatefulWidget {
  static String tag = 'call_sample';

  final String ip;

  DataChannelSample({Key key, @required this.ip}) : super(key: key);

  @override
  _DataChannelSampleState createState() =>
      _DataChannelSampleState(serverIP: ip);
}

class _DataChannelSampleState extends State<DataChannelSample> {
  Signaling _signaling;
  List<dynamic> _peers;
  var _selfId;
  bool _inCalling = false;
  final String serverIP;
  RTCDataChannel _dataChannel;
  Timer _timer;
  var _text = '';
  _DataChannelSampleState({Key key, @required this.serverIP});
  int sampleRate = 32768;
  int blockSize = 4096;
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  Uint8List bm;
  Uint8List bin;
  var jsonbody;
  int width;
  int height;
  ZLibDecoder decoder = new ZLibDecoder();
  FocusNode focusNode = FocusNode();
  var specialKeyLookup = {
    "Arrow Left": "Left",
    "Arrow Right": "Right",
    "Arrow Down": "Down",
    "Arrow Up": "Up",
  };
  var key;

  @override
  initState() {
    super.initState();
    _mPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    initBitmap(720, 480);
    _connect();
  }

  void initBitmap(int jsonwidth, int jsonheight) {
    width = jsonwidth;
    height = jsonheight;
    int filesize = width * height * 3 + 54;
    int j;
    bm = new Uint8List(filesize);
    bm[0] = 'B'.codeUnitAt(0);
    bm[1] = 'M'.codeUnitAt(0);

    // File size
    String sizeStr = filesize.toRadixString(16).padLeft(8, '0');
    j = 8;
    for (int i = 2; i < 6; i++) {
      bm[i] = int.parse(sizeStr.substring(j - 2, j), radix: 16);
      j = j - 2;
    }

    // reserved field (in hex. 00 00 00 00)
    for (int i = 6; i < 10; i++) bm[i] = 0;

    // offset of pixel data inside the image
    //The offset, i.e. starting address, of the byte where the bitmap data
    // (pixel array) can be found.
    bm[10] = 0x36;
    for (int i = 11; i < 14; i++) bm[i] = 0;

    // -- BITMAP HEADER -- //

    // header size
    bm[14] = 40;
    for (int i = 15; i < 18; i++) bm[i] = 0;

    // width of the image
    String widthStr = width.toRadixString(16).padLeft(8, '0');
    j = 8;
    for (int i = 18; i < 22; i++) {
      bm[i] = int.parse(widthStr.substring(j - 2, j), radix: 16);
      j = j - 2;
    }

    // height of the image
    String heightStr = height.toRadixString(16).padLeft(8, '0');
    j = 8;
    for (int i = 22; i < 26; i++) {
      bm[i] = int.parse(heightStr.substring(j - 2, j), radix: 16);
      j = j - 2;
    }

    // no of color planes, must be 1
    bm[26] = 1;
    bm[27] = 0;

    // number of bits per pixel
    bm[28] = 24; // 1 byte
    bm[29] = 0;

    // compression method (no compression here)
    for (int i = 30; i < 34; i++) bm[i] = 0;

    // raw bitmap data size, all zeros
    for (int i = 34; i < 38; i++) bm[i] = 0;

    // horizontal resolution of the image - pixels per meter (3780)
    bm[38] = 0xc4;
    bm[39] = 0x0e;
    bm[40] = 0;
    bm[41] = 0;

    // vertical resolution of the image - pixels per meter (3780)
    bm[42] = 0xc4;
    bm[43] = 0x03;
    bm[44] = 0;
    bm[45] = 0;

    // color palette information
    for (int i = 46; i < 50; i++) bm[i] = 0;

    // number of important colors
    // if 0 then all colors are important
    for (int i = 50; i < 54; i++) bm[i] = 0;
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) await _mPlayer.stopPlayer();
  }

  @override
  deactivate() {
    stopPlayer();
    _mPlayer.closeAudioSession();
    _mPlayer = null;
    super.deactivate();
    if (_signaling != null) _signaling.close();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  void feedHim(Uint8List data) {
    if (_mPlayer.isStopped) {
      _mPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: sampleRate,
      );
    }
    int start = 0;
    int totalLength = data.length;
    while (totalLength > 0 && _mPlayer != null && !_mPlayer.isStopped) {
      int ln = totalLength > blockSize ? blockSize : totalLength;
      _mPlayer.foodSink.add(FoodData(data.sublist(start, start + ln)));
      totalLength -= ln;
      start += ln;
    }
  }

  void _connect() async {
    if (_signaling == null) {
      _signaling = Signaling(serverIP)..connect();

      _signaling.onDataChannelMessage = (dc, RTCDataChannelMessage data) {
        setState(() {
          if (data.isBinary) {
            bin = data.binary;
            if (bin[0] == 'A'.codeUnitAt(0) &&
                bin[1] == 'U'.codeUnitAt(0)) //audio data
              feedHim(bin.sublist(2, bin.length));
            else {
              //video data
              bin = decoder.convert(bin);
              bm = Uint8List.fromList(bm.sublist(0, 54) + bin);
            }
          } else {
            jsonbody = json.decode(data.text);
            //need the width and height of the image
            initBitmap(jsonbody["width"], jsonbody["height"]);
          }
        });
      };

      _signaling.onDataChannel = (channel) {
        _dataChannel = channel;
      };

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            {
              this.setState(() {
                _inCalling = true;
              });
              //_timer =
              //    Timer.periodic(Duration(seco//Image.memory(bytes),nds: 1), _handleDataChannelTest);
              break;
            }
          case SignalingState.CallStateBye:
            {
              this.setState(() {
                _inCalling = false;
              });
              if (_timer != null) {
                _timer.cancel();
                _timer = null;
              }
              _dataChannel = null;
              _text = '';
              break;
            }
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };

      _signaling.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
          _peers = event['peers'];
        });
      });
    }
  }

  _invitePeer(context, peerId) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'data', false);
    }
  }

  _buildRow(context, peer) {
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self
            ? peer['name'] + '[Your self]'
            : peer['name'] + '[' + peer['user_agent'] + ']'),
        onTap: () => _invitePeer(context, peer['id']),
        trailing: Icon(Icons.sms),
        subtitle: Text('id: ' + peer['id']),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);
    return Scaffold(
      body: _inCalling
          ? ListView(
              children: [
                Container(child: Image.memory(bm)),
                RawKeyboardListener(
                    autofocus: true,
                    focusNode: focusNode,
                    onKey: (RawKeyEvent event) {
                      if (event.runtimeType.toString() == "RawKeyDownEvent") {
                        print(event.data.logicalKey);
                        // Send actual key label if normal key
                        // Else Special Key Lookup using map
                        if (specialKeyLookup
                            .containsKey(event.data.logicalKey.debugName))
                          key =
                              specialKeyLookup[event.data.logicalKey.debugName];
                        else
                          key = event.data.logicalKey.keyLabel;
                        var msg = List.filled(10, key).join("+");
                        _dataChannel.send(RTCDataChannelMessage(msg));
                      }
                    },
                    child: TextField())
              ],
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: (_peers != null ? _peers.length : 0),
              itemBuilder: (context, i) {
                return _buildRow(context, _peers[i]);
              }),
    );
  }
}
