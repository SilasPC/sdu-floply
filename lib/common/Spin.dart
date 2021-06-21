
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// App wide spinner / loading indicator.
class Spin extends StatelessWidget {

  final double size;
  final Color? color;
  Spin(this.size, [this.color]);

  Widget build(BuildContext context) =>
    SpinKitChasingDots(
      size: size,
      itemBuilder: (ctx, i) => DecoratedBox(
        decoration: BoxDecoration(
          color: color == null ? (
            i.isEven
              ? Colors.green
              : Colors.greenAccent
          ) : color
        )
      )
    );
}