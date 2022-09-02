//@dart=2.9
import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:flutter/material.dart';

class BlinkIcon extends StatefulWidget{
  @override
  _BlinkIconState createState() => _BlinkIconState();
}
class _BlinkIconState extends State<BlinkIcon> with SingleTickerProviderStateMixin{
  AnimationController _controller;
  Animation<Color> _colorAnimation;
  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _colorAnimation = ColorTween(begin: Colors.white, end: HexColor(Constants.red))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
      setState(() {});
    });
    _controller.forward();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Icon(Icons.email_outlined, size: 20, color: _colorAnimation.value,);
      },
    );
  }
  @override
  dispose() {
    _controller.dispose(); // you need this
    super.dispose();
  }
}