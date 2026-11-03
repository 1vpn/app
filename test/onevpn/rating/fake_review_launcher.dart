import 'dart:async';

import 'package:onexray/onevpn/rating/rating_prompt.dart';

/// A launcher that counts each review flow open and opens nothing.
///
/// With [hangs], the flow never returns, like a review sheet the user
/// leaves. With [fails], the flow fails.
class FakeReviewLauncher implements OneVpnReviewLauncher {
  FakeReviewLauncher({this.hangs = false, this.fails = false});

  final bool hangs;
  final bool fails;
  int opens = 0;

  @override
  Future<void> openReview() async {
    opens++;
    if (fails) throw StateError('no review flow');
    if (hangs) await Completer<void>().future;
  }
}
