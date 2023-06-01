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

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxString _searchParam = "".obs;
  String get searchParam => _searchParam.value;
  set searchParam(String param) => _searchParam.value = param;

  final RxMap<String, AppProfile> _filteredProfiles = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get filteredProfiles => _filteredProfiles;
  set filteredProfiles(Map<String, AppProfile> filteredProfiles) => _filteredProfiles.value = filteredProfiles;

  final Rx<SplayTreeMap<double, AppProfile>> _sortedProfileLocation = SplayTreeMap<double, AppProfile>().obs;
  SplayTreeMap<double, AppProfile> get sortedProfileLocation => _sortedProfileLocation.value;
  set sortedProfileLocation(SplayTreeMap<double, AppProfile> sortedProfileLocation) => _sortedProfileLocation.value = sortedProfileLocation;

  SearchType searchType = SearchType.profile;

  @override
  void onInit() async {
    super.onInit();
    logger.i("Search Controller Init");
    try {
      searchType = Get.arguments as SearchType ?? SearchType.profile;
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      switch(searchType) {
        case SearchType.profile:
          await loadProfiles();
          setSearchParam("");
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
    isLoading = false;
    update([AppPageIdConstants.search]);
  }

  @override
  void setSearchParam(String param) {
    searchParam = param;
    filteredProfiles = searchParam.isEmpty ? mateController.totalProfiles
        : mateController.filterByNameOrInstrument(searchParam);

    sortByLocation();
    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> loadProfiles() async {
    await mateController.loadFollowingProfiles();
    filteredProfiles.addAll(mateController.followingProfiles);
    await mateController.loadFollowersProfiles();
    filteredProfiles.addAll(mateController.followerProfiles);
    await mateController.loadMates();
    filteredProfiles.addAll(mateController.mates);
    filteredProfiles.addAll(mateController.profiles);
    sortByLocation();
    update([AppPageIdConstants.search]);
  }

  @override
  void sortByLocation() {
    sortedProfileLocation.clear();
    filteredProfiles.forEach((key, mate) {
      double distanceBetweenProfiles = AppUtilities.distanceBetweenPositions(
          userController.profile.position!,
          mate.position!);

      distanceBetweenProfiles = distanceBetweenProfiles + Random().nextDouble();
      sortedProfileLocation[distanceBetweenProfiles] = mate;
    });

    logger.i("Filtered Profiles ${filteredProfiles.length}");
    logger.i("Sortered Profiles ${sortedProfileLocation.length}");
    update([AppPageIdConstants.search]);
  }

}
