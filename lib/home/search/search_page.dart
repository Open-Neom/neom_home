import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import 'search_controller.dart';
import 'widgets/appbar_search.dart';
import 'widgets/search_widgets.dart';

class SearchPage extends StatelessWidget {

  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SearchController>(
      id: AppPageIdConstants.search,
      init: SearchController(),
      builder: (_) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarSearch(_)),
      body: Obx(() => Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.isLoading ? const Center(child: CircularProgressIndicator())
            : buildMateSearchList(_)
        ),
      )
    ),
    );
  }

}
