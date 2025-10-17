import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/bottom_bar_item.dart';
import '../home_controller.dart';

class HomeBottomAppBar extends StatefulWidget {

  final List<BottomAppBarItem> items;
  final String centerItemText;
  final double height;
  final double iconSize;
  final double fontSize;
  final Color? backgroundColor;
  final Color color;
  final Color selectedColor;
  final NotchedShape notchedShape;
  final ValueChanged<int> onTabSelected;
  final bool showText;

  HomeBottomAppBar({
    super.key,
    required this.items,
    required this.color,
    required this.selectedColor,
    required this.notchedShape,
    required this.onTabSelected,
    this.centerItemText = "",
    this.height = 60,
    this.iconSize = 20,
    this.fontSize = 10,
    this.backgroundColor,
    this.showText = true,
  }) {
    assert(items.length > 1 && items.length <= 5);
  }

  @override
  State<StatefulWidget> createState() => HomeBottomAppBarState();
}

class HomeBottomAppBarState extends State<HomeBottomAppBar> {

  final HomeController homeController = Get.find<HomeController>();

  void updateIndex(int index) {
    widget.onTabSelected(index);
    setState(() {
      if(index < 3) homeController.currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=> BottomAppBar(
      height: widget.height,
      shape: widget.notchedShape,
      color: widget.backgroundColor,
      notchMargin: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.items.length, (int index) {
          return _buildTabItem(
            item: widget.items[index],
            index: index,
            onPressed: updateIndex,
            currentIndex: homeController.currentIndex,
          );
        }),
      ),
    ));
  }

  Widget _buildTabItem({
    BottomAppBarItem? item,
    int index = 0,
    ValueChanged<int>? onPressed,
    int currentIndex = 0,
  }) {
    Color color = currentIndex == index ? widget.selectedColor : widget.color;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPressed!(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(item?.animation != null) item!.animation!,
            Icon(item!.iconData, color: color, size: widget.iconSize + (widget.showText ? 0 : 5)),
            if(widget.showText) Text(item.text, style: TextStyle(color: color, fontSize: widget.fontSize),),
          ],
        ),
      ),
    );
  }

}
