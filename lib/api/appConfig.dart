import 'package:flutter/material.dart';

class AppConfig extends InheritedWidget {
  AppConfig({required this.appDisplayName,required this.appInternalId,
    required Widget child}):super(child: child);

  final String appDisplayName;
  final int appInternalId;

  static AppConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

}