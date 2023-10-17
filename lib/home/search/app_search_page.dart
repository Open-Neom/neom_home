import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import 'app_search_controller.dart';
import 'widgets/appbar_search.dart';
import 'widgets/search_widgets.dart';

class AppSearchPage extends StatelessWidget {

  const AppSearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSearchController>(
      id: AppPageIdConstants.search,
      init: AppSearchController(),
      builder: (_) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarSearch(_)
      ),
      backgroundColor: AppColor.main50,
      body: Obx(() => Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : buildMateSearchList(_)
        ),
      )
    ),
    );
  }

}
