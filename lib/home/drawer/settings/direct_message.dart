import 'package:flutter/material.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'widgets/header_widget.dart';
import 'widgets/settings_row_widget.dart';

class DirectMessagesPage extends StatelessWidget {

  const DirectMessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarChild(title: "Inbox Messages"),
      body: Container(
      decoration: AppTheme.appBoxDecoration,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: const <Widget>[
          HeaderWidget('Inbox Message', secondHeader: true,),
          SettingRowWidget(
            "Receive message requests",
            navigateTo: "",
            showDivider: false,
            visibleSwitch: true,
            vPadding: 20,
            subtitle: 'You will be able to receive Direct Message requests from anyone on Gigmeout, even if you don\'t follow them.',
          ),
          SettingRowWidget(
            "Show read receipts",
            navigateTo: "",
            showDivider: false,
            visibleSwitch: true,
            subtitle: 'When someone sends you a message, people in the conversation will know you\'ve seen it. If you turn off this setting, you won\'t be able to see read receipt from others.',
            ),
        ],
      ),),
    );
  }
}
