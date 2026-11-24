import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_palette.dart';

/// Menyimpan pilihan mode (gelap / terang) dan memberi tahu layar yang memakainya.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  bool _isDark = true;

  bool get isDark => _isDark;
  AppPalette get palette => _isDark ? AppPalette.dark : AppPalette.light;

  /// Baca pilihan yang tersimpan. Default: gelap.
  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    final dark = saved != 'light';
    if (dark != _isDark) {
      _isDark = dark;
      notifyListeners();
    }
  }

  Future<void> setDark(bool value) async {
    if (value == _isDark) return;
    _isDark = value;
    notifyListeners();
    await _storage.write(key: _key, value: value ? 'dark' : 'light');
  }
}

/// Meneruskan [ThemeController] ke seluruh pohon widget. Layar yang membaca
/// `context.palette` otomatis dibangun ulang saat mode berganti.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier ??
      ThemeController.instance;
}

/// Pasang di `MaterialApp(builder: ...)`: memuat pilihan tersimpan dan
/// menyediakan [ThemeScope] di atas semua halaman.
class ThemeHost extends StatefulWidget {
  const ThemeHost({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeHost> createState() => _ThemeHostState();
}

class _ThemeHostState extends State<ThemeHost> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.load();
  }

  @override
  Widget build(BuildContext context) =>
      ThemeScope(controller: ThemeController.instance, child: widget.child);
}

extension PaletteContext on BuildContext {
  AppPalette get palette => ThemeScope.of(this).palette;
}
