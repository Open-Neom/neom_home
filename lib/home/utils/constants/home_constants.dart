import 'package:flutter/material.dart';
import 'package:neom_audio_player/neom_audio_player_app.dart';
import 'package:neom_booking/booking/ui/booking_home_page.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_events/events/ui/events_page.dart';
import 'package:neom_inbox/inbox/ui/inbox_page.dart';
import 'package:neom_timeline/neom_timeline.dart';

import '../../../home/widgets/menu_model.dart';

class HomeConstants {

  static final eHomePages = [const TimelinePage(), const EventsPage(), const EventsPage(), const InboxPage()]; ///FOR RELEASE 4 must be AUDIOPLAYER
  static final gHomePages = [const TimelinePage(), const BookingHomePage(), const EventsPage(), const NeomAudioPlayerApp()];
  static final cHomePages = [const TimelinePage(), const BookingHomePage(), const EventsPage(), const NeomAudioPlayerApp()];

  static const int firstTabIndex = 0;
  static const int secondTabIndex = 1;
  static const int thirdTabIndex = 2;
  static const int forthTabIndex = 3;

  static final List<MenuModel> bottomMenuItems = [
    MenuModel(AppTranslationConstants.createPost, AppTranslationConstants.createPostMsg, Icons.colorize, AppRouteConstants.postUpload),
    MenuModel(AppTranslationConstants.organizeEvent, AppTranslationConstants.organizeEventMsg, Icons.event, AppRouteConstants.createEventType),
    MenuModel(AppTranslationConstants.shareComment, AppTranslationConstants.shareCommentMsg, Icons.info, AppRouteConstants.createPostText),
  ];

}
