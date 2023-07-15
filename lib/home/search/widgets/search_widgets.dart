import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import '../app_search_controller.dart';


Widget buildMateSearchList(AppSearchController _) {
  return ListView.builder(
    itemCount: _.sortedProfileLocation.length,
    itemBuilder: (context, index) {
      String distanceBetween = _.sortedProfileLocation.keys.elementAt(index).round().toString();
      AppProfile mate = _.sortedProfileLocation.values.elementAt(index);
      return mate.name.isNotEmpty && mate.isActive ? GestureDetector(
        child: ListTile(
          onTap: () => mate.id.isNotEmpty ? Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id) : {},
          leading: Hero(
            tag: mate.photoUrl,
            child: CircleAvatar(backgroundImage: customCachedNetworkImageProvider(mate.photoUrl))
          ),
          title: Text(mate.name.capitalize!),
          subtitle: Row(
              children: [
                Text(mate.appItems?.isNotEmpty ?? false ? (mate.appItems?.length.toString() ?? ""): ""),
                const Icon(Icons.book, color: Colors.blueGrey, size: 15),
                Text(mate.mainFeature.tr.capitalize!),
                Text(" - $distanceBetween KM"),
              ]
          ),
        ),
        onLongPress: () => {},
      ) : Container();
    },
  );
}
