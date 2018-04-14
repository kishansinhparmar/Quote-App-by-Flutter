import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

void main() => runApp(new MyApp());

const String _appName = "Quote Share";

//Quote text style
const _quoteTextStyle = const TextStyle(
    fontFamily: "Patrick Hand",
    fontSize: 32.0,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal);

// FavQs text logo style
const _favqsTextStyle = const TextStyle(
    fontFamily: "Grand Hotel",
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal);

//Author text style
const _authorTextStyle = const TextStyle(
    fontSize: 20.0, fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);

// REST Api variables
const Url = "https://favqs.com/api/qotd";
const httpHeaders = const {
  'Accept': 'application/json',
};

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appName,
      home: new Home(),
      theme: new ThemeData(
          primaryColor: Colors.white,
          iconTheme: new IconThemeData(color: Colors.black),
          accentColor: Colors.black,
          brightness: Brightness.light),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  // * * * Variables * * *
  bool _defaultSwitch;
  String _themeName;
  Future<String> _response;
  String author;
  String quote;

  // END Variable

  // * * * ICONS * * *
  Icon _iconTag = new Icon(Icons.bookmark_border);
  Icon _iconShare = new Icon(Icons.share);
  Icon _iconInfo = new Icon(Icons.info_outline);
  Icon _iconError = const Icon(
    Icons.error_outline,
    size: 64.0,
  );
  Icon _iconRefresh = new Icon(Icons.refresh);
  Icon _iconSyncPrb = new Icon(Icons.sync_problem);
  Text _lblErrorMsg = new Text("Somwthing went wrong...");

  // END ICONS * * *

  // * * * Common paddiing
  Padding _padding = new Padding(padding: const EdgeInsets.all(4.0));

  // Dialog content
  String _dialogContent;

  //* * * Theme variables * * *
  final ThemeData _darkTheme = new ThemeData(
      primarySwatch: Colors.blueGrey,
      accentColor: Colors.deepOrange,
      brightness: Brightness.dark);

  final ThemeData _lightTheme = new ThemeData(
      primaryColor: Colors.white,
      iconTheme: new IconThemeData(color: Colors.black),
      accentColor: Colors.black,
      brightness: Brightness.light);

  ThemeData _defaultTheme;

  // End Theme variables * * *

  @override
  void initState() {
    super.initState();
    print("initState()");
    _defaultTheme = _lightTheme;
    author = "";
    quote = "";
    _themeName = "Light";
    _defaultSwitch = false;
    _dialogContent =
        "${_appName} app brought to you by Kishansinh Parmar (@imkishansinh)"
        "\n\nQuote comes from www.favqs.com\n\nTry Swipe Left/Right over the quote.";
    _getNewQuote();
  }

  @override
  Widget build(BuildContext context) {
    print("build()");
    return new Theme(
        data: _defaultTheme,
        child: new Scaffold(
          appBar: new AppBar(
            title: new Text(_appName),
            actions: <Widget>[
              new Row(
                children: <Widget>[
                  new Text(_themeName),
                  new Switch(
                      value: _defaultSwitch,
                      onChanged: (bool newValue) {
                        setState(() {
                          _defaultSwitch = newValue;
                          if (newValue) {
                            _themeName = "Dark";
                            _defaultTheme = _darkTheme;
                          } else {
                            _themeName = "Light";
                            _defaultTheme = _lightTheme;
                          }
                        });
                      }),
                  new IconButton(
                      icon: _iconInfo,
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return new Theme(
                                  data: _darkTheme,
                                  child: new AlertDialog(
                                    title: new Text("About ${_appName} app"),
                                    content: new RichText(
                                      text: new TextSpan(
                                        text: _dialogContent,
                                        style: _authorTextStyle,
                                        children: <TextSpan>[
                                          new TextSpan(
                                              text: "\n\nwith thanks "),
                                          new TextSpan(
                                              text: 'FavQs ',
                                              style: _favqsTextStyle),
                                          new TextSpan(
                                              text:
                                                  " ,Tim Sneath (@timsneath) "),
                                        ],
                                      ),
                                    ),
                                  ));
                            });
                      }),
                  new IconButton(
                      icon: _iconShare,
                      onPressed: () {
                        _shareQuote();
                      })
                ],
              )
            ],
          ),
          body: _bodyWidget(),
          floatingActionButton: new FloatingActionButton(
              tooltip: "New Quote",
              child: _iconRefresh,
              onPressed: () {
                setState(() {
                  _getNewQuote();
                });
              }),
        ));
  }

  FutureBuilder<String> _bodyWidget() {
    return new FutureBuilder(
        future: _response,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          print("_bodyWidget()");
          if (snapshot.hasError) {
            return new Center(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Column(
                    children: <Widget>[_iconError, _padding, _lblErrorMsg],
                  )
                ],
              ),
            );
          } else {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return new Center(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Column(
                        children: <Widget>[
                          _iconSyncPrb,
                          _padding,
                          _lblErrorMsg
                        ],
                      )
                    ],
                  ),
                );
                break;

              case ConnectionState.waiting:
                return new Center(
                  child: new CircularProgressIndicator(),
                );
                break;
              default:
                //Decode response string to map
                Map<String, dynamic> map = json.decode(snapshot.data);

                author = map['quote']['author'];
                quote = map['quote']['body'];
                List listTags = map['quote']['tags'];
                List<Widget> widgets = [];
                if (listTags != null) {
                  for (int i = 0; i < listTags.length; i++) {
                    widgets.add(_getTagWidget(listTags[i]));
                  }
                } else {
                  widgets.add(_getTagWidget("NoTag"));
                }

                return new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new Dismissible(
                        key: const Key("Quote"),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          _getNewQuote();
                        },
                        child: new Center(
                            child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Text(
                              "\"" + quote + "\"",
                              style: _quoteTextStyle,
                            ),
                            _padding,
                            new Text(
                              "- " + author,
                              textAlign: TextAlign.end,
                              style: _authorTextStyle,
                            ),
                            _padding,
                            new Row(
                              children: widgets,
                            )
                          ],
                        ))));
            }
          }
        });
  }

  _shareQuote() {
    print("_shareQuote()");
    share(quote + "\n- " + author);
  }

  _getNewQuote() {
    print("_getNewQuote()");
    setState(() {
      _response = http.read(Url, headers: httpHeaders);
    });
  }

  _getTagWidget(String text) {
    print("_getTagWidget(${text})");
    return new Row(
      children: <Widget>[
        _iconTag,
        new Padding(padding: EdgeInsets.fromLTRB(0.0, 0.0, 2.0, 0.0)),
        new Text(
          text.toLowerCase(),
        ),
      ],
    );
  }
}
