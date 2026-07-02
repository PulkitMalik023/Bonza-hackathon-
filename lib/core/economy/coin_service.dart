import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/puzzle_ui_flags.dart';

class CoinService extends ChangeNotifier {
  CoinService._();

  static final CoinService instance = CoinService._();

  static const _balanceKey = 'coin_balance';

  int _balance = kInitialCoinBalance;
  bool _loaded = false;

  int get coinBalance => _balance;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_balanceKey) ?? kInitialCoinBalance;
    _loaded = true;
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) {
      return;
    }
    _balance += amount;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, _balance);
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _balance = kInitialCoinBalance;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, _balance);
    notifyListeners();
  }
}
