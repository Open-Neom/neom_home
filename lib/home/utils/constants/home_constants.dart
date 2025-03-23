import 'package:flutter/material.dart';
import 'package:neom_audio_player/audio_player_root_page.dart';
import 'package:neom_booking/booking/ui/booking_home_page.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_events/events/ui/events_page.dart';
import 'package:neom_timeline/neom_timeline.dart';

import '../../../home/widgets/menu_model.dart';

class HomeConstants {

  static List<Widget> homePages = [const TimelinePage(), const EventsPage(), const BookingHomePage(), const AudioPlayerRootPage()];

  static const int firstTabIndex = 0;
  static const int secondTabIndex = 1;
  static const int thirdTabIndex = 2;
  static const int forthTabIndex = 3;

  static final List<MenuModel> bottomMenuItems = [
    MenuModel(AppTranslationConstants.createPost, AppTranslationConstants.createPostMsg, Icons.colorize, AppRouteConstants.postUpload),
    // MenuModel(AppTranslationConstants.videoUpload, AppTranslationConstants.uploadVideoMsg, Icons.colorize, AppRouteConstants.videoUpload),
    MenuModel(AppTranslationConstants.organizeEvent, AppTranslationConstants.organizeEventMsg, Icons.event, AppRouteConstants.createEventType),
    MenuModel(AppTranslationConstants.shareComment, AppTranslationConstants.shareCommentMsg, Icons.info, AppRouteConstants.createPostText),
  ];

}
