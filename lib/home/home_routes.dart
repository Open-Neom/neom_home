import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'drawer/quotation/quotation_page.dart';
import 'drawer/settings/about_page.dart';
import 'drawer/settings/account_settings_page.dart';
import 'drawer/settings/blocked_profiles_page.dart';
import 'drawer/settings/content_preferences.dart';
import 'drawer/settings/privacy_and_terms_page.dart';
import 'drawer/settings/settings_and_privacy_page.dart';
import 'search/search_page.dart';
import 'ui/home_page.dart';

class HomeRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.home,
        page: () => const HomePage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.blockedProfiles,
      page: () => const BlockedProfilesPage(),
    ),
    GetPage(
      name: AppRouteConstants.search,
      page: () => const SearchPage(),
    ),
    GetPage(
      name: AppRouteConstants.privacyAndTerms,
      page: () => const PrivacyAndTermsPage(),
    ),
    GetPage(
      name: AppRouteConstants.settingsAccount,
      page: () => const AccountSettingsPage(),
    ),
    GetPage(
      name: AppRouteConstants.settingsPrivacy,
      page: () => const SettingsPrivacyPage(),
    ),
    GetPage(
      name: AppRouteConstants.contentPreferences,
      page: () => const ContentPreferencePage(),
    ),
    GetPage(
      name: AppRouteConstants.about,
      page: () => const AboutPage(),
    ),
    GetPage(
      name: AppRouteConstants.refresh,
      page: () => const HomePage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.quotation,
      page: () => const QuotationPage(),
      transition: Transition.zoom,
    ),
  ];

}
