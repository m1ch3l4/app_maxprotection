import 'package:equatable/equatable.dart';

class Idbean extends Equatable{
  final int number;
  final String text;

  const Idbean(this.number,this.text);

  @override
  // TODO: implement props
  List<Object> get props => [number];
}