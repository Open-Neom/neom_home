import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commerce/commerce/ui/subscription/subscription_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_user.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

class AccountSettingsController extends GetxController {

  final userController = Get.find<UserController>();
  late SubscriptionController subscriptionController;
  AppUser user = AppUser();

  bool isLoading = true;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("AccountSettings Controller Init for userId ${userController.user.id}");
    user = userController.user;
    subscriptionController = Get.put(SubscriptionController());
    isLoading = false;

  }

  void getSubscriptionAlert(BuildContext context) {
    subscriptionController.getSubscriptionAlert(context, AppRouteConstants.accountSettings);
  }

}
