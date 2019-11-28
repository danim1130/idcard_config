import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/prefer_sdk/html.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'ID Card configuration'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class RelativePoint {
  final double x;
  final double y;

  RelativePoint(this.x, this.y);

  Map<String, dynamic> toJson() {
    return {"x": this.x, "y": this.y,};
  }


}

class ScreenRelativeRect {
  final RelativePoint start;
  final RelativePoint end;

  ScreenRelativeRect(this.start, this.end);

  Map<String, dynamic> toJson() {
    return {"start": this.start.toJson(), "end": this.end.toJson(),};
  }


}

const List<String> selectionTypes = [
  "name", "date", "city", "text", "barcode", "datagram"
];

class FieldData {
  final ScreenRelativeRect positionRect;
  final TextEditingController controller;
  final String type;

  FieldData({this.positionRect, this.controller, this.type});

  FieldData.empty()
      : positionRect = null,
        type = "text",
        controller = TextEditingController();

  FieldData copy(
          {ScreenRelativeRect positionRect,
          TextEditingController controller,
          String type}) =>
      FieldData(
          positionRect: positionRect ?? this.positionRect,
          controller: controller ?? this.controller,
          type: type ?? this.type);

  Map<String, dynamic> toJson() {
    return {
      "positionRect": this.positionRect.toJson(),
      "key": this.controller.text,
      "type": this.type,
    };
  }


}

class CardConfiguration{
  final String imageName;
  final List<FieldData> fields;

  CardConfiguration(this.imageName, this.fields);

  Map<String, dynamic> toJson() {
    return {"imageName": this.imageName, "fields": this.fields.map((f) => f.toJson()).toList(),};
  }
}

GlobalKey _containerKey = GlobalKey();

class _MyHomePageState extends State<MyHomePage> {
  String _imageName;
  Uint8List _image = Uint8List(0);
  RelativePoint _dragStartPos;
  int _selectedFieldPosition;

  List<FieldData> _fields = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: <Widget>[
            Builder(builder: (context) {
              MediaQuery.of(context);
              List<Rect> currentRects = [];
              if (_image.length != 0) {
                if ((_containerKey?.currentContext?.findRenderObject() as RenderBox) != null) {
                  var size = (_containerKey.currentContext.findRenderObject() as RenderBox).size;
                  currentRects = _fields.map((f) {
                    var currentRect = f.positionRect;
                    if (currentRect == null) {
                      return null;
                    } else {
                      return Rect.fromLTWH(
                          currentRect.start.x * size.width,
                          currentRect.start.y * size.height,
                          (currentRect.end.x - currentRect.start.x) *
                              size.width,
                          (currentRect.end.y - currentRect.start.y) *
                              size.height);
                    }
                  }).toList();
                }
                return Expanded(
                  child: Wrap(
                      runAlignment: WrapAlignment.center,
                      children: <Widget>[
                        Stack(children: <Widget>[
                          Opacity(
                            opacity: 0.99,
                            child: Image.memory(
                              _image,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                          ...currentRects.where((e) => e != null).map((rect) => Positioned.fromRect(child: Container(color: Colors.red.withOpacity(0.5),), rect: rect,)),
                          Positioned.fill(
                            child: GestureDetector(
                              key: _containerKey,
                              onPanStart: _onDragStart,
                              onPanUpdate: _onDragUpdate,
                              onPanEnd: _onDragEnd,
                              behavior: HitTestBehavior.opaque,
                            ),
                          ),
                        ]),
                      ]),
                );
              } else {
                return AspectRatio(
                  aspectRatio: 1.0 / 1.0,
                  child: Center(
                    child: RaisedButton(
                      onPressed: _startFilePicker,
                      child: Text("Upload an image!"),
                    ),
                  ),
                );
              }
            }),
            SizedBox(
              width: 400,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, position) {
                        return ListTile(
                          title: SizedBox(
                            height: 30,
                            child: TextField(
                              controller: _fields[position].controller,
                              onTap: () {
                                _onFieldSelected(position);
                              },
                            ),
                          ),
                          selected: position == _selectedFieldPosition,
                          trailing: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _fields[position].type,
                                  items: selectionTypes.map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  )).toList(),
                                  onChanged: (item){
                                    setState(() {
                                      _fields[position] = _fields[position].copy(type: item);
                                    });
                                  },
                                ),
                              ),
                              GestureDetector(child: Icon(Icons.delete), onTap: () {_onDeleteItem(position);},),
                            ],
                          ),
                        );
                      },
                      itemCount: _fields.length,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      MaterialButton(
                        color: Colors.lightBlueAccent,
                        textColor: Colors.white,
                        disabledColor: Colors.grey,
                        disabledTextColor: Colors.white,
                        onPressed: _image.length == 0 ? null : _onAddNewFieldPressed,
                        child: Text("Add new field"),
                      ),
                      SizedBox(width: 16,),
                      MaterialButton(
                        color: Colors.lightBlueAccent,
                        textColor: Colors.white,
                        disabledColor: Colors.grey,
                        disabledTextColor: Colors.white,
                        onPressed: _image.length == 0 ? null : _onGenerateConfigurationFile,
                        child: Text("Generate Configuration"),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _onGenerateConfigurationFile(){
    var config = CardConfiguration(_imageName, _fields);
    String jsonData = Uri.encodeComponent(jsonEncode(config.toJson()));
    new AnchorElement(href: "data:text/plain;charset=utf-8,$jsonData")
      ..setAttribute("download", "card_config.json")
      ..click();
  }

  _onDeleteItem(int position){
    setState(() {
      _fields.removeAt(position);
      if (_selectedFieldPosition == position){
        _selectedFieldPosition = null;
      } else if (_selectedFieldPosition > position){
        _selectedFieldPosition -= 1;
      }
    });
  }

  _onAddNewFieldPressed() {
    setState(() {
      _fields.add(FieldData.empty());
    });
  }

  _onFieldSelected(int position) {
    setState(() {
      _selectedFieldPosition = position;
    });
  }

  _onDragStart(DragStartDetails start) {
    setState(() {
      var currentContainer =
          _containerKey.currentContext.findRenderObject() as RenderBox;
      if (currentContainer != null) {
        var currentSize = currentContainer.size;
        _dragStartPos = RelativePoint(
            start.localPosition.dx / currentSize.width,
            start.localPosition.dy / currentSize.height);
      }
    });
  }

  _onDragUpdate(DragUpdateDetails event) {
    setState(() {
      var currentContainer =
          _containerKey.currentContext.findRenderObject() as RenderBox;
      if (currentContainer != null && _selectedFieldPosition != null) {
        var currentSize = currentContainer.size;
        var point = RelativePoint(event.localPosition.dx / currentSize.width,
            event.localPosition.dy / currentSize.height);
        var startPoint = RelativePoint(
            min(point.x, _dragStartPos.x), min(point.y, _dragStartPos.y));
        var endPoint = RelativePoint(
            max(point.x, _dragStartPos.x), max(point.y, _dragStartPos.y));
        var currentRect = ScreenRelativeRect(startPoint, endPoint);
        _fields[_selectedFieldPosition] = _fields[_selectedFieldPosition].copy(positionRect: currentRect);
      }
    });
  }

  _onDragEnd(DragEndDetails details) {}

  _startFilePicker() async {
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      // read file content as dataURL
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        final reader = new FileReader();

        reader.onLoadEnd.listen((e) {
          var test = reader.result as String;
          var data = test.split(",")[1];
          setState(() {
            _imageName = file.name;
            _image = base64Decode(data);
            _fields = [];
          });
        });
        reader.readAsDataUrl(file);
      }
    });
  }
}
