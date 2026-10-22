import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/models/models.dart';

void main() {
  test('BankNotificationParser parses Nequi, Nu, Lulo, ARQ, Morse and ignores OTP', () {
    final sp = SpaceModel.fromTemplate('complete', first: true);
    for (final s in kBankSamples) {
      final res = BankNotificationParser.parse(
        rawText: s.text,
        rawTitle: s.title,
        rawApp: s.pkg,
        space: sp,
        fxRate: 4200,
      );
      expect(res.ok, isTrue, reason: 'Failed for ${s.bank}');
      expect(res.bank, equals(s.bank));
      expect(res.amount, greaterThan(0));
    }

    final otp = BankNotificationParser.parse(
      rawText: 'Tu clave dinámica de Nequi es 918273',
      rawTitle: 'Nequi',
      rawApp: 'com.nequi.MobileApp',
      space: sp,
      fxRate: 4200,
    );
    expect(otp.ok, isFalse);
    expect(otp.ignored, isTrue);
  });
}
