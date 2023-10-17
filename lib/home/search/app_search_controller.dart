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
      await mateController.loadFollowingProfiles();
      filteredProfiles.value.addAll(mateController.followingProfiles);
      await mateController.loadFollowersProfiles();
      filteredProfiles.value.addAll(mateController.followerProfiles);
      await mateController.loadMates();
      filteredProfiles.value.addAll(mateController.mates);
      await mateController.loadProfiles();
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

}
