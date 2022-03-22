import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readr/blocs/config/bloc.dart';
import 'package:readr/blocs/config/events.dart';
import 'package:readr/blocs/config/states.dart';
import 'package:readr/blocs/personalFile/personalFile_cubit.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/helpers/router/router.dart';
import 'package:readr/helpers/updateMessages.dart';
import 'package:readr/helpers/userHelper.dart';
import 'package:readr/pages/errorPage.dart';
import 'package:readr/pages/shared/profilePhotoWidget.dart';
import 'package:upgrader/upgrader.dart';

class RootPage extends StatefulWidget {
  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  void initState() {
    _loadingConfig();
    super.initState();
  }

  _loadingConfig() async {
    context.read<ConfigBloc>().add(LoadingConfig(context));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is Onboarding) {
          AutoRouter.of(context).push(const WelcomeRoute());
        }
      },
      builder: (BuildContext context, ConfigState state) {
        if (state is ConfigError) {
          final error = state.error;
          print('ConfigError: ${error.message}');
          return ErrorPage(error: error, onPressed: () => _loadingConfig());
        }
        if (state is ConfigLoaded) {
          Widget personalPageIcon;
          if (UserHelper.instance.isVisitor) {
            personalPageIcon = Image.asset(
              visitorAvatarPng,
            );
          } else {
            personalPageIcon =
                ProfilePhotoWidget(UserHelper.instance.currentUser, 11);
          }
          return UpgradeAlert(
            minAppVersion: state.minAppVersion,
            messages: UpdateMessages(),
            dialogStyle: Platform.isAndroid
                ? UpgradeDialogStyle.material
                : UpgradeDialogStyle.cupertino,
            child: AutoTabsScaffold(
              routes: [
                const HomeRouter(),
                const ReadrRouter(),
                PersonalFileWidgetRoute(
                  viewMember: UserHelper.instance.currentUser,
                  isFromBottomTab: true,
                  isMine: true,
                  isVisitor: UserHelper.instance.isVisitor,
                ),
              ],
              bottomNavigationBuilder: (_, tabsRouter) {
                return BottomNavigationBar(
                  elevation: 10,
                  backgroundColor: Colors.white,
                  currentIndex: tabsRouter.activeIndex,
                  onTap: (index) {
                    if (index == 2 && UserHelper.instance.isMember) {
                      context
                          .read<PersonalFileCubit>()
                          .fetchMemberData(UserHelper.instance.currentUser);
                    }
                    tabsRouter.setActiveIndex(index);
                  },
                  selectedItemColor: bottomNavigationBarSelectedColor,
                  unselectedItemColor: bottomNavigationBarUnselectedColor,
                  items: [
                    BottomNavigationBarItem(
                      icon: SizedBox(
                        height: 20,
                        child: Icon(
                          tabsRouter.activeIndex == 0
                              ? Icons.home_sharp
                              : Icons.home_outlined,
                        ),
                      ),
                      label: '首頁',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox(
                        height: 20,
                        child: Image.asset(
                          logoSimplifyPng,
                          color: tabsRouter.activeIndex == 1
                              ? bottomNavigationBarSelectedColor
                              : bottomNavigationBarUnselectedColor,
                        ),
                      ),
                      label: 'READr',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox(
                        height: 20,
                        child: personalPageIcon,
                      ),
                      label: '個人檔案',
                    ),
                  ],
                );
              },
            ),
          );
        }

        // state is Init, loading, or other
        return Container(
          color: Colors.white,
          child: Image.asset(
            logoPng,
            scale: 4,
          ),
        );
      },
    );
  }
}
