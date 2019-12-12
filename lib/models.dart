import 'package:flutter/material.dart';

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
  final String language;

  CardConfiguration(this.imageName, this.fields, this.language);

  Map<String, dynamic> toJson() {
    return {"imageName": this.imageName, "fields": this.fields.map((f) => f.toJson()).toList(), "language": this.language, "version": "0.0.1"};
  }
}