import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/service/shared/ping/batch.dart';
import 'package:onexray/service/shared/ping/state.dart';

void main() {
  test("empty ping batch returns no results", () async {
    final results = await PingBatchRunner.run(const [], PingState());

    expect(results, isEmpty);
  });

  test("ping batch rejects more than five configs", () async {
    final sources = List.generate(
      PingBatchRunner.maxBatchSize + 1,
      (_) => const PingBatchSource("{}"),
    );

    await expectLater(
      PingBatchRunner.run(sources, PingState()),
      throwsArgumentError,
    );
  });

  test('per-item responses map delay and error; a missing delay fails', () {
    final measured = PingBatchResult.fromResponse(
      PingBatchItemResponse(false, 10000, 'timeout'),
    );
    expect(measured.success, isFalse);
    expect(measured.delay, 10000);
    expect(measured.error, 'timeout');

    final missing = PingBatchResult.fromResponse(
      PingBatchItemResponse(true, null, 'bridge error'),
    );
    expect(missing.success, isFalse);
    expect(missing.error, 'bridge error');
  });
}
