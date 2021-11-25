import 'package:auto_route/auto_route.dart';
import 'package:readr/models/member.dart';
import 'package:readr/pages/errorPage.dart';
import 'package:readr/pages/home/homeWidget.dart';
import 'package:flutter/material.dart';
import 'package:readr/pages/memberCenter/aboutPage.dart';
import 'package:readr/pages/memberCenter/deleteMemberPage.dart';
import 'package:readr/pages/memberCenter/memberCenterPage.dart';
import 'package:readr/pages/story/storyPage.dart';
import 'package:readr/initialApp.dart';
import 'package:readr/pages/tag/tagPage.dart';
import 'package:readr/models/tag.dart';

part 'router.gr.dart';

// Run after edited:
// flutter packages pub run build_runner build --delete-conflicting-outputs
@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(name: 'Initial', page: InitialApp, initial: true, children: [
      AutoRoute(
        path: "homeWidget",
        name: "HomeRouter",
        page: HomeWidget,
      ),
      AutoRoute(
        path: "memberCenter",
        name: "MemberCenterRouter",
        page: MemberCenterPage,
      ),
    ]),
    AutoRoute(page: StoryPage),
    AutoRoute(page: ErrorPage, fullscreenDialog: true),
    AutoRoute(page: TagPage),
    AutoRoute(page: AboutPage),
    AutoRoute(page: DeleteMemberPage),
  ],
)
// extend the generated private router
class AppRouter extends _$AppRouter {}
