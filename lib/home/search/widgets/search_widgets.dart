import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/verification_level.dart';

import '../app_search_controller.dart';

Widget buildMateSearchList(AppSearchController _) {
  return ListView.builder(
    itemCount: _.sortedProfileLocation.value.length,
    itemBuilder: (context, index) {
      ///DEPRECATED
      ///String distanceBetween = _.sortedProfileLocation.value.keys.elementAt(index).round().toString();
      AppProfile mate = _.sortedProfileLocation.value.values.elementAt(index);
      return mate.name.isNotEmpty && mate.isActive ? GestureDetector(
        child: ListTile(
          onTap: () => mate.id.isNotEmpty ? Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id) : {},
          leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(mate.photoUrl.isNotEmpty ? mate.photoUrl
                    : AppFlavour.getAppLogoUrl(),
                  errorListener: (error) {
                    // Si hay un error, puedes cargar una imagen por defecto
                    AppUtilities.logger.e(error.toString());
                  },
                ),
          ),
          title: Row(
            children:[
              Text(mate.name.capitalize),
              AppTheme.widthSpace5,
              if(mate.verificationLevel != VerificationLevel.none) AppFlavour.getVerificationIcon(mate.verificationLevel, size: 18)
            ]
          ),
          subtitle: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ///DEPRECATED - Not importante right now
                    /// Text(mate.favoriteItems?.isNotEmpty ?? false ? (mate.favoriteItems?.length.toString() ?? ""): ""),
                    Icon(AppFlavour.getAppItemIcon(), color: Colors.blueGrey, size: 15),
                    AppTheme.widthSpace5,
                    Text(mate.mainFeature.tr.capitalize),
                    AppTheme.widthSpace5,
                    ///DEPRECATED - As its showing sensitive data
                    /// Text(" - ${int.parse(distanceBetween) <= 2 ? AppTranslationConstants.aroundYou.tr : '$distanceBetween KM'}"),
                    // if(mate.address.isNotEmpty) Icon(Icons.location_on, color: Colors.blueGrey, size: 15),
                    // if(mate.address.isNotEmpty) AppTheme.widthSpace5,
                    // if(mate.address.isNotEmpty) SizedBox(
                    //   width: AppTheme.fullWidth(context)/3,
                    //   child: Text(mate.address.split(',').first),
                    // )
                  ]
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if(mate.address.isNotEmpty) const Icon(Icons.location_on, color: Colors.blueGrey, size: 15),
                    if(mate.address.isNotEmpty) AppTheme.widthSpace5,
                    if(mate.address.isNotEmpty) SizedBox(
                      width: AppTheme.fullWidth(context)*0.66,
                      child: Text(mate.address.split(',').first),
                    )
                  ]
              ),
              // if(mate.address.isNotEmpty) SizedBox(
              //   // width: AppTheme.fullWidth(context)*0.38,
              //   child: Text(mate.address.split(',').first),
              // )
            ],
          )
        ),
        onLongPress: () => {},
      ) : const SizedBox.shrink();
    },
  );
}
