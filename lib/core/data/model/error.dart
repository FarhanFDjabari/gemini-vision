import 'dart:io';

abstract class Error implements HttpException {
  final int code;
  @override
  final String message;

  Error(this.code, this.message);
}
