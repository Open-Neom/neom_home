import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

class AccountSettingsController extends GetxController {

  final userController = Get.find<UserController>();


  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("AccountSettings Controller Init for userId ${userController.user?.id ?? ""}");
    isLoading = false;
  }

}
