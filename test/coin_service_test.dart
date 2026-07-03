import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/puzzle_ui_flags.dart';
import 'package:jam_pro/core/economy/coin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CoinService.instance.resetForTest();
  });

  test('starts with initial coin balance', () {
    expect(CoinService.instance.coinBalance, kInitialCoinBalance);
  });

  test('addCoins increases balance', () async {
    await CoinService.instance.addCoins(100);
    expect(
      CoinService.instance.coinBalance,
      kInitialCoinBalance + 100,
    );
  });

  test('load restores persisted balance', () async {
    await CoinService.instance.addCoins(50);
    await CoinService.instance.load();
    expect(
      CoinService.instance.coinBalance,
      kInitialCoinBalance + 50,
    );
  });
}
