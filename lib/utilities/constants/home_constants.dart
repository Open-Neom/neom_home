import 'package:flutter/material.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import '../../domain/models/bottom_menu_item.dart';
import 'home_translation_constants.dart';

class HomeConstants {

  static final List<BottomMenuItem> bottomMenuItems = [
    BottomMenuItem(CommonTranslationConstants.createPost, HomeTranslationConstants.createPostMsg, Icons.create, AppRouteConstants.mediaUpload),
    BottomMenuItem(HomeTranslationConstants.organizeEvent, HomeTranslationConstants.organizeEventMsg, Icons.event, AppRouteConstants.createEventType),
    BottomMenuItem(HomeTranslationConstants.shareComment, HomeTranslationConstants.shareCommentMsg, Icons.info, AppRouteConstants.createPostText),
  ];

}
