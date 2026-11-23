import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Single source of truth for the selected Mongolian script font family
/// across all features (editor, library, calendar reader).
class FontService extends GetxController {
  static const _key = 'app_font_family';
  final _box = GetStorage();

  final fontFamily = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final saved = _box.read<String>(_key);
    fontFamily.value =
        (saved != null && saved.isNotEmpty) ? saved : 'z52tsagaantig';
  }

  void setFont(String family) {
    fontFamily.value = family;
    _box.write(_key, family);
  }
}
