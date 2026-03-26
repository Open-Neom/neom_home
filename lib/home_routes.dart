import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/web/fil_guadalajara_page.dart';

class HomeRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.filGuadalajara,
      page: () => const FilGuadalajaraPage(),
      transition: Transition.rightToLeft,
    ),
  ];

}
