import 'dart:ffi';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

void printWindowInfo() {
  print('printWindowInfo');
  int window = GetForegroundWindow();
  print('window: ${window.toHexString(64)}');
  int windowNameLength = GetWindowTextLength(window) * 2 + 1;
  if (windowNameLength == 0) {
    int error = GetLastError();
    if (error != 0) {
      print('error: $error');
    } else {
      print('empty title bar');
    }
  } else {
    Pointer<Utf16> windowNamePtr = malloc.allocate<Utf16>(windowNameLength);
    if (GetWindowText(window, windowNamePtr, windowNameLength) == 0) {
      print('error: ${GetLastError()}');
    } else {
      print(
        'name: ${windowNamePtr.toDartString()} (length: $windowNameLength)',
      );
    }
    malloc.free(windowNamePtr);
  }
  Pointer<RECT> rectPtr = malloc.allocate<RECT>(sizeOf<RECT>());
  if (GetWindowRect(window, rectPtr) == 0) {
    print('error: ${GetLastError()}');
  } else {
    print('top: ${rectPtr.ref.top}');
    print('bottom: ${rectPtr.ref.bottom}');
    print('left: ${rectPtr.ref.left}');
    print('right: ${rectPtr.ref.right}');
  }
  malloc.free(rectPtr);
}

void setCursor() {
  int size = 64;
  Pointer<Uint64> bits = calloc.allocate<Uint64>(size * size ~/ 8);
  int i = 0;
  while (i < size * size ~/ 64) {
    bits[i] = 0xFFFFFFFFFFFFFFFF;
    i++;
  }
  int module = GetModuleHandle(nullptr);
  int cursor = CreateCursor(module, 0, 0, size, size, bits, bits);
  if (cursor == 0) {
    print('error: ${GetLastError()}');
  }
  print(SetSystemCursor(cursor, 32512)); // default cursor
}
