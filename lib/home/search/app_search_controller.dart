import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/mate_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/use_cases/search_service.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/search_type.dart';

class AppSearchController extends GetxController implements SearchService {

  var logger = AppUtilities.logger;  
  final userController = Get.find<UserController>();

  MateController mateController = Get.put(MateController());
  ScrollController scrollController = ScrollController();

  final RxBool isLoading = true.obs;
  final RxString searchParam = "".obs;
  final RxMap<String, AppProfile> filteredProfiles = <String, AppProfile>{}.obs;
  final Rx<SplayTreeMap<double, AppProfile>> sortedProfileLocation = SplayTreeMap<double, AppProfile>().obs;

  SearchType searchType = SearchType.profile;

  @override
  void onInit() async {
    super.onInit();
    logger.i("Search Controller Init");
    try {
      searchType = Get.arguments as SearchType;
      switch(searchType) {
        case SearchType.profile:
          await loadProfiles();
          break;
        case SearchType.band:
          break;
        case SearchType.event:
          break;
        case SearchType.any:
          break;
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      setSearchParam("");
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.search]);
  }

  @override
  void setSearchParam(String param) {
    searchParam.value = param;
    filteredProfiles.value = searchParam.isEmpty ? mateController.totalProfiles
        : mateController.filterByNameOrInstrument(searchParam.value);

    sortByLocation();
    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> loadProfiles() async {
    try {
      await mateController.loadProfiles();
      ///DEPRECATED
      /// await mateController.loadFollowingProfiles();
      /// await mateController.loadFollowersProfiles();
      /// await mateController.loadMates();
      filteredProfiles.value.addAll(mateController.followingProfiles);
      filteredProfiles.value.addAll(mateController.followerProfiles);
      filteredProfiles.value.addAll(mateController.mates);
      filteredProfiles.value.addAll(mateController.profiles);
      sortByLocation();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    isLoading.value = false;
    update([AppPageIdConstants.search]);
  }

  @override
  void sortByLocation() {
    sortedProfileLocation.value.clear();
    filteredProfiles.value.forEach((key, mate) {
      double distanceBetweenProfiles = AppUtilities.distanceBetweenPositions(
          userController.profile.position!,
          mate.position!);

      distanceBetweenProfiles = distanceBetweenProfiles + Random().nextDouble();
      sortedProfileLocation.value[distanceBetweenProfiles] = mate;
    });

    logger.i("Filtered Profiles ${filteredProfiles.value.length}");
    logger.i("Sortered Profiles ${sortedProfileLocation.value.length}");
    update([AppPageIdConstants.search]);
  }

  ///DEPRECATED 1224
  // @override
  // void sortByLocation() {
  //   AppUtilities.startStopwatch(reference: "sortByLocation");
  //   if (userController.profile.position == null) {
  //     logger.w("User position is null. Skipping sorting.");
  //     return;
  //   }
  //
  //   final Map<String, double> distanceCache = {};
  //
  //   // Convertimos el mapa a una lista de pares clave-valor y calculamos distancias
  //   final List<MapEntry<double, AppProfile>> sortedList = filteredProfiles.value.entries
  //       .map((entry) {
  //     double distance;
  //
  //     // Usa una caché para evitar cálculos repetitivos
  //     if (distanceCache.containsKey(entry.key)) {
  //       distance = distanceCache[entry.key]!;
  //     } else {
  //       distance = AppUtilities.distanceBetweenPositions(
  //         userController.profile.position!,
  //         entry.value.position!,
  //       );
  //
  //       distanceCache[entry.key] = distance; // Almacena la distancia calculada
  //     }
  //
  //     return MapEntry(distance, entry.value);
  //   })
  //       .toList();
  //
  //   // Ordenar la lista por distancia
  //   sortedList.sort((a, b) => a.key.compareTo(b.key));
  //
  //   // Limpiar el mapa observable y agregar los elementos ordenados
  //   sortedProfileLocation.value.clear();
  //   for (var entry in sortedList) {
  //     sortedProfileLocation.value[entry.key] = entry.value;
  //   }
  //
  //   logger.i("Filtered Profiles: ${filteredProfiles.value.length}");
  //   logger.i("Sorted Profiles: ${sortedProfileLocation.value.length}");
  //
  //   AppUtilities.stopStopwatch();
  //   update([AppPageIdConstants.search]);
  // }



}
