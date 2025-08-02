import 'package:logger/logger.dart';
import 'dart:io';


Logger getLogger() {
  return Logger(
    printer: PrettyPrinter(),
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(file: File('${DateTime.now().toIso8601String().substring(0,7)}.log')),
    ]),
    level: Level.error
  );
}
