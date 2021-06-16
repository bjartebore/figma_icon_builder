import 'dart:ui';
import 'package:flutter/material.dart';

abstract class PaintedIcon extends Widget {
  PaintedIcon withColor(Color color);

  PaintedIcon withSize(Size size);
}