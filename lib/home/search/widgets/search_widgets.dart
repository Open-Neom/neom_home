import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
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
            child: FutureBuilder<CachedNetworkImageProvider>(
              future: CoreUtilities.handleCachedImageProvider(mate.photoUrl),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CircleAvatar(backgroundImage: snapshot.data);
                } else {
                  return const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CircularProgressIndicator()
                  );
                }
              },
            )
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
