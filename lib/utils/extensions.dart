import 'package:smooth_corner/smooth_corner.dart';

import '../config.dart';

extension ChatifyExtansion on Widget {
  // Box extension
  Widget boxExtension() => SmoothContainer(child: this).decorated(
    border: Border.all(color: appCtrl.appTheme.textBoxColor.withOpacity(0.15)),
          color: appCtrl.isTheme
              ? appCtrl.appTheme.accentTxt
              : appCtrl.appTheme.white,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r18)),
          );
}
