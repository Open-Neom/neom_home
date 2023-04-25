import 'package:flutter/material.dart';
import 'package:neom_booking/booking/ui/booking_home_page.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_events/events/ui/events_page.dart';
import 'package:neom_inbox/inbox/ui/inbox_page.dart';
import 'package:neom_itemlists/itemlists/ui/itemlist_page.dart';
import 'package:neom_posts/blog/ui/blog_page.dart';
import 'package:neom_timeline/neom_timeline.dart';
import '../../../home/widgets/menu_model.dart';

class HomeConstants {

  static final emxiHomePages = [const TimelinePage(), const ItemlistPage(), const BlogPage(), const InboxPage()];
  static final gigHomePages = [const TimelinePage(), const ItemlistPage(), const BookingHomePage(), const InboxPage()];
  static final cyberneomHomePages = [const TimelinePage(), const ItemlistPage(), const EventsPage(), const InboxPage()];

  static const int timelineIndex = 0;
  static const int itemlistsIndex = 1;
  static const int eventsIndex = 2;
  static const int inboxIndex = 3;

  static final List<MenuModel> bottomMenuItems = [
    MenuModel(AppTranslationConstants.createPost, AppTranslationConstants.createPostMsg, Icons.colorize, AppRouteConstants.postUpload),
    MenuModel(AppTranslationConstants.organizeEvent, AppTranslationConstants.organizeEventMsg, Icons.event, AppRouteConstants.createEventType),
    MenuModel(AppTranslationConstants.shareComment, AppTranslationConstants.shareCommentMsg, Icons.info, AppRouteConstants.createPostText),
    //TODO
    //MenuModel(GigTranslationConstants.startPoll, GigTranslationConstants.startPollMsg, Icons.equalizer, GigRouteConstants.UNDER_CONSTRUCTION)
  ];

}
