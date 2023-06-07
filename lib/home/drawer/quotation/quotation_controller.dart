import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:neom_commerce/commerce/utils/constants/app_commerce_constants.dart';
import 'package:neom_commons/core/domain/model/app_phyisical_item.dart';
import 'package:neom_commons/core/utils/enums/app_item_size.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../domain.use_cases/quotation_service.dart';

class QuotationController extends GetxController implements QuotationService {

  var logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isPhysical = true.obs;
  bool get isPhysical => _isPhysical.value;
  set isPhysical(bool isPhysical) => _isPhysical.value = isPhysical;

  final RxBool _processARequired = true.obs;
  bool get processARequired => _processARequired.value;
  set processARequired(bool processARequired) => _processARequired.value = processARequired;

  final RxBool _processBRequired = true.obs;
  bool get processBRequired => _processBRequired.value;
  set processBRequired(bool processBRequired) => _processBRequired.value = processBRequired;

  final RxBool _coverDesignRequired = true.obs;
  bool get coverDesignRequired => _coverDesignRequired.value;
  set coverDesignRequired(bool coverDesignRequired) => _coverDesignRequired.value = coverDesignRequired;


  AppPhysicalItem itemToQuote = AppPhysicalItem();
  int itemQty = 0;
  int proccessACost = 0;
  int proccessBCost = 0;
  int coverDesignCost = 0;
  double pricePerUnit = 0;
  double totalCost = 0;

  TextEditingController itemQtyController = TextEditingController();
  TextEditingController itemDurationController = TextEditingController();
  TextEditingController controllerPhone = TextEditingController();

  final Rx<Country> _phoneCountry = countries[0].obs;
  Country get phoneCountry => _phoneCountry.value;
  set phoneCountry(Country country) => _phoneCountry.value = country;

  String phoneNumber = '';

  @override
  void onInit() async {
    super.onInit();
    itemDurationController.text = AppCommerceConstants.minDuration.toString();
    itemToQuote.duration = (AppCommerceConstants.minDuration*AppCommerceConstants.durationConvertionPerSize).ceil();
    itemQtyController.text = AppCommerceConstants.minQty.toString();
    itemQty = AppCommerceConstants.minQty;
    updateQuotation();
    logger.d("Settings Controller Init");

    for (var country in countries) {
      if(Get.locale!.countryCode == country.code){
        phoneCountry = country; //Mexico
      }
    }

    isLoading = false;
  }

  @override
  void setAppItemSize(String selectedSize){
    logger.d("Setting new locale");
    try {
      itemToQuote.size = EnumToString.fromString(AppItemSize.values, selectedSize)
          ?? AppItemSize.a4;

      setAppItemDuration();
    } catch (e) {
      logger.toString();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemDuration() {
    logger.d("");

    int newDuration = int.parse(itemDurationController.text.trim());

    if(itemToQuote.size == AppItemSize.a4) {
      newDuration = (newDuration*AppCommerceConstants.durationConvertionPerSize).round();
    }

    if(newDuration >= AppCommerceConstants.minDuration){
      itemToQuote.duration = newDuration;
    } else {
      // itemToQuote.duration = AppCommerceConstants.minQty;
      // AppUtilities.showSnackBar("Mínimo de páginas requerido",
      //     "El mínimo de páginas recomendado para iniciar un proceso de publicación es de $itemQty");
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemQty() {
    logger.d("");

    int newItemQty = int.parse(itemQtyController.text.trim());

    if(newItemQty > AppCommerceConstants.minQty){
      itemQty = newItemQty;
    } else {
      // itemQty = AppCommerceConstants.minQty;
      // AppUtilities.showSnackBar("Mínimo de libros requerido", "El mínimo de libros a imprimir es de $itemQty");
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setIsPhysical() async {
    logger.d("");
    isPhysical = !isPhysical;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setProcessARequired() async {
    logger.d("");
    processARequired = !processARequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setProcessBRequired() async {
    logger.d("");
    processBRequired = !processBRequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setCoverDesignRequired() async {
    logger.d("");
    coverDesignRequired = !coverDesignRequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void updateQuotation() {
    pricePerUnit = isPhysical ? (itemToQuote.duration * AppCommerceConstants.costPerDurationUnit).roundToDouble() : 0;
    proccessACost = processARequired ? (itemToQuote.duration * AppCommerceConstants.processACost).round() : 0;
    proccessBCost = processBRequired ? (itemToQuote.duration * AppCommerceConstants.processBCost).round() : 0;
    addRevenuePercentage();
    coverDesignCost = coverDesignRequired ? AppCommerceConstants.coverDesignCost : 0;
    totalCost = proccessACost + proccessBCost + coverDesignCost + (pricePerUnit*itemQty);
    update([AppPageIdConstants.quotation]);
  }

  @override
  void addRevenuePercentage() {
    pricePerUnit = (pricePerUnit * (1+AppCommerceConstants.revenuePercentage)).roundToDouble();
    proccessACost = (proccessACost * (1+AppCommerceConstants.revenuePercentage)).round();
    proccessBCost = (proccessBCost * (1+AppCommerceConstants.revenuePercentage)).round();
  }

  @override
  Future<void> sendWhatsappQuotation() async {

    String message = "";
    String phone = "";
    String validateMsg = "";

    try {

      message = "${userController.user!.userRole == UserRole.subscriber
          ? AppTranslationConstants.subscriberQuotationWhatsappMsg.tr : AppTranslationConstants.adminQuotationWhatsappMsg.tr}\n"
          "${itemToQuote.duration != 0 ? "\n${AppTranslationConstants.appItemDuration.tr}: ${itemToQuote.duration}" : ""}"
          "${(itemQty != 0 && isPhysical) ? "\n${AppTranslationConstants.appItemQty.tr}: $itemQty\n" : ""}"
          "${proccessACost != 0 ? "\n${AppTranslationConstants.processA.tr}: \$$proccessACost MXN" : ""}"
          "${proccessBCost != 0 ? "\n${AppTranslationConstants.processB.tr}: \$$proccessBCost MXN" : ""}"
          "${coverDesignCost != 0 ? "\n${AppTranslationConstants.coverDesign.tr}: \$$coverDesignCost MXN" : ""}"
          "${pricePerUnit != 0 ? "\n${AppTranslationConstants.pricePerUnit.tr}: \$$pricePerUnit MXN\n" : ""}"
          "${totalCost != 0 ? "\n${AppTranslationConstants.totalToPay.tr}: \$${totalCost.toString()} MXN\n\n" : ""}"
          "${AppTranslationConstants.thanksForYourAttention.tr}\n"
          "${userController.profile.name}";

      if(userController.user!.userRole == UserRole.subscriber) {
        phone = AppFlavour.getWhatsappBusinessNumber();
      } else {
        if (controllerPhone.text.isEmpty &&
            (controllerPhone.text.length < phoneCountry.minLength
                || controllerPhone.text.length > phoneCountry.maxLength)
        ) {
          validateMsg = MessageTranslationConstants.pleaseEnterPhone;
          phoneNumber = "";
        } else if (phoneCountry.code.isEmpty) {
          validateMsg = MessageTranslationConstants.pleaseEnterCountryCode;
          phoneNumber = "";
        } else {
          phoneNumber = controllerPhone.text;
          phone = phoneCountry.dialCode + phoneNumber;
        }
      }


      if(phone.isNotEmpty) {
        AppUtilities.logger.i("Sending WhatsApp Quotation to $phone");
        CoreUtilities.launchWhatsappURL(phone, message);
      } else {
        AppUtilities.showSnackBar(AppTranslationConstants.whatsappQuotation, validateMsg);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.quotation]);
  }

}
