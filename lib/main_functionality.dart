import 'dart:core';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/call_sample/call_sample.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'src/call_sample/data_channel_sample.dart';
import 'src/route_item.dart';

class MainFunctionality extends StatefulWidget {
  @override
  _MainFunctionalityState createState() => new _MainFunctionalityState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MainFunctionalityState extends State<MainFunctionality> {
  List<RouteItem> items;
  String _server = '';
  SharedPreferences _prefs;

  List<Image> images = [
    Image.asset('assets/images/Game1.jpg'),
    Image.asset('assets/images/Emerald.jpg'),
    Image.asset('assets/images/Mario.jpg'),
    Image.asset('assets/images/Sonic.jpg'),
  ];

  bool _datachannel = false;
  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        leading: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 64,
            minHeight: 104,
            maxWidth: 124,
            maxHeight: 154,
          ),
          child: item.image,
        ),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    int _currentIndex = 0;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: Center(child: Text('Gaming as a Service 🎮')),
          ),
          body: Column(
            children: [
              CarouselSlider(
                  items: images,
                  options: CarouselOptions(
                    height: 250,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 3),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    scrollDirection: Axis.horizontal,
                  )),
              SizedBox(height: 25),
              ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(0.0),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    return _buildRow(context, items[i]);
                  }),
            ],
          )),
    );
  }

  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = _prefs.getString('server') ?? 'demo.cloudwebrtc.com';
    });
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          _prefs.setString('server', _server);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _datachannel
                      ? DataChannelSample(ip: _server)
                      : CallSample(ip: _server)));
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text('Enter server address:'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _server = text;
                });
              },
              decoration: InputDecoration(
                hintText: _server,
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              FlatButton(
                  child: const Text('CONNECT'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.connect);
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'Video Call',
          subtitle: 'P2P Call Sample.',
          image: Image.asset('assets/images/video-call.jpg', fit: BoxFit.cover),
          push: (BuildContext context) {
            _datachannel = false;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Pokemon Emerald',
          subtitle: 'Data Channel Sample',
          image: Image.asset('assets/images/Emerald.jpg', fit: BoxFit.cover),
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Super Mario Bros.',
          subtitle: 'Data Channel Sample',
          image: Image.asset('assets/images/Mario.jpg', fit: BoxFit.cover),
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Sonic Adventure',
          subtitle: 'Data Channel Sample',
          image: Image.asset('assets/images/Sonic.jpg', fit: BoxFit.cover),
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
    ];
  }
}
