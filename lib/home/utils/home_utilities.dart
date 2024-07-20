
import 'package:flutter/material.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import 'constants/home_constants.dart';

class HomeUtilities {

  static List<Widget> getHomePages() {
    switch (AppFlavour.appInUse) {
      case AppInUse.c:
        return HomeConstants.cHomePages;
      case AppInUse.g:
        return HomeConstants.gHomePages;
      case AppInUse.e:
        return HomeConstants.eHomePages;
    }
  }

}
