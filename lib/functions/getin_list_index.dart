int getinListindex(num index, int length) {
  num out = 0;
  if (index >= length) {
    out = index - (index ~/ length) * length;
  } else {
    out = index;
  }

  return out.toInt();
}
