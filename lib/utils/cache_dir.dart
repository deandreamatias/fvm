import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/helpers.dart';

class CacheDirectory {
  final int files;
  final int size;
  final String redableSize;
  final Directory dir;
  CacheDirectory({this.files = 0, this.size = 0, this.dir})
      : redableSize = filesize(size);

  factory CacheDirectory.fromPath(String path) {
    final dir = Directory(path);
    final dirStat = dirStatSync(path);
    return CacheDirectory(
        dir: dir, files: dirStat['fileNum'], size: dirStat['size']);
  }
}

CacheDirectory getCacheDirectory({String path}) {
  path ??= kVersionsDir.path;
  return CacheDirectory.fromPath(path);
}
