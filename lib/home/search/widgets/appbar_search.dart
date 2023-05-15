import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import '../search_controller.dart';


class AppBarSearch extends StatelessWidget implements PreferredSizeWidget {

  final SearchController searchController;
  const AppBarSearch(this.searchController, {Key? key}) : super(key: key);
  
  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        maxLines: 1,
        onChanged: (param) => searchController.setSearchParam(param.trim()),
        decoration: InputDecoration(
          suffixIcon: const Icon(CupertinoIcons.search),
          contentPadding: const EdgeInsets.all(12),
          hintText: AppTranslationConstants.searchPostProfileItemmates.tr,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(4.0),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColor.appBar,
      elevation: 0.0,
    );
  }

}
