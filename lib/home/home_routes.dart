import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'search/app_search_page.dart';
import 'settings/about_page.dart';
import 'settings/account_settings_page.dart';
import 'settings/blocked_profiles_page.dart';
import 'settings/content_preferences.dart';
import 'settings/privacy_and_terms_page.dart';
import 'settings/settings_and_privacy_page.dart';
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
    GetPage(
      name: AppRouteConstants.settingsPrivacy,
      page: () => const SettingsPrivacyPage(),
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
      name: AppRouteConstants.contentPreferences,
      page: () => const ContentPreferencePage(),
    ),
    GetPage(
      name: AppRouteConstants.about,
      page: () => const AboutPage(),
    ),
    GetPage(
      name: AppRouteConstants.blockedProfiles,
      page: () => const BlockedProfilesPage(),
    ),
  ];

}
