// ignore_for_file: uri_does_not_exist, undefined_identifier

import 'package:sqflite_common_ffi_web/sqflite_common_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void initWebDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
