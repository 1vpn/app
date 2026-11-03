import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The portrait reference handset.
const kPortraitViewport = Size(360, 800);

/// The landscape reference handset.
const kLandscapeViewport = Size(800, 360);

/// The landscape tablet smoke size.
const kTabletLandscapeViewport = Size(1024, 768);

/// Sizes the test view to [size] logical pixels for the rest of the test.
///
/// Sets the view, not only the surface. The layout mode reads
/// [MediaQuery.sizeOf], and a surface size alone leaves it at the test
/// default of 800x600.
Future<void> setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
