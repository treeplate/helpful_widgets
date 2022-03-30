class Uint8ListTape extends Tape {
  final Uint8List storage = Uint8List(1);

  int get bitsPerElement => 8;

  bool read(int index) {
    int macroIndex = (index / 8).floor();
    int subIndex = index % 8;
    int macro = storage.elementAt(macroIndex);
    int subIndexAsDivisor = pow(2, 7 - subIndex).toInt();
    return (macro / subIndexAsDivisor).floor().isOdd;
  }

  void write(int index, bool value) {
    int macroIndex = (index / 8).floor();
    int subIndex = index % 8;
    int macro = storage.elementAt(macroIndex);
    int mask = pow(2, 7 - subIndex).toInt();
    if (value) {
      storage[macroIndex] = macro | mask;
    } else {
      storage[macroIndex] = macro & -mask;
    }
  }

  void loadIndex(int index) {
    if (index ~/ 8 > storage.length) {
      storage.add(0);
    }
    if (index ~/ 8 > storage.length) {
      throw Exception(
        "Need to allocate storage one uint8 at a time (tried to loadIndex $index)",
      );
    }
  }

  @override
  void loadStart() {
    storage.insert(0, 0);
  }
}
