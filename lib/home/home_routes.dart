import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'search/app_search_page.dart';
import 'ui/home_page.dart';

class HomeRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.home,
        page: () => const HomePage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.refresh,
      page: () => const HomePage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.search,
      page: () => const AppSearchPage(),
    ),
  ];

}
