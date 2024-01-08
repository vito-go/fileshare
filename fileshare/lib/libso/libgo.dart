import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeAddLib = getLibGo();

DynamicLibrary getLibGo() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libgo.so');
  }
  if (Platform.isLinux) {
    print("Directory.current: ${Directory.current}");
    return DynamicLibrary.open(path.join(
        kDebugMode ? "" : path.dirname(Platform.resolvedExecutable),
        "lib/libgo_linux.so"));
  }
  if (Platform.isWindows) {
    print("Directory.current: ${Directory.current}");
    return DynamicLibrary.open(path.join(
        kDebugMode ? "" : path.dirname(Platform.resolvedExecutable),
        "lib/libgo_windows.so"));
  }
  throw "DynamicLibrary Platform: ${Platform.operatingSystem}  implement me";
}

final int Function(Pointer<Utf8> rootDir, bool allowUpload, int port)
    startServer = nativeAddLib
        .lookup<NativeFunction<Int64 Function(Pointer<Utf8>, Bool, Int64)>>(
            'StartServer')
        .asFunction();

final setLogUrl = nativeAddLib.lookupFunction<
    Void Function(Pointer<Utf8>, Pointer<Utf8>, Bool),
    void Function(Pointer<Utf8>, Pointer<Utf8>, bool)>('SetLogUrl');

// _println equal to _printInfo
final _println = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
    void Function(Pointer<Utf8>)>('Println');

final _printWarn = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
    void Function(Pointer<Utf8>)>('PrintWarn');

final _printInfo = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
    void Function(Pointer<Utf8>)>('PrintInfo');

final _printError = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
    void Function(Pointer<Utf8>)>('PrintError');
final setLogDebug = nativeAddLib
    .lookupFunction<Void Function(Bool), void Function(bool)>('SetLogDebug');
final setLogCallerSkip =
    nativeAddLib.lookupFunction<Void Function(Int64), void Function(int)>(
        'SetLogCallerSkip');

void printWarn(String msg) {
  final c = msg.toNativeUtf8();
  _printWarn(c);
  malloc.free(c);
}

void printInfo(String msg) {
  final c = msg.toNativeUtf8();
  _printInfo(c);
  malloc.free(c);
}

// equal to printInfo
void println(String msg) {
  final c = msg.toNativeUtf8();
  _println(c);
  malloc.free(c);
}

void printError(String msg) {
  final c = msg.toNativeUtf8();
  _printError(c);
  malloc.free(c);
}

final closeServer = nativeAddLib.lookupFunction<Void Function(Int64 serverIdx),
    void Function(int serverIdx)>('CloseServer');
