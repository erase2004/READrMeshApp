import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:readr/controller/personalFile/personalFilePageController.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/helpers/analyticsHelper.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/helpers/dynamicLinkHelper.dart';
import 'package:readr/models/followableItem.dart';
import 'package:readr/models/member.dart';
import 'package:readr/pages/errorPage.dart';
import 'package:readr/pages/personalFile/editPersonalFilePage.dart';
import 'package:readr/pages/personalFile/followerListPage.dart';
import 'package:readr/pages/personalFile/followingListPage.dart';
import 'package:readr/pages/personalFile/personalFileSkeletonScreen.dart';
import 'package:readr/pages/setting/settingPage.dart';
import 'package:readr/pages/shared/ProfilePhotoWidget.dart';
import 'package:readr/pages/shared/follow/followButton.dart';
import 'package:readr/pages/shared/meshToast.dart';
import 'package:readr/services/memberService.dart';
import 'package:readr/services/personalFileService.dart';
import 'package:share_plus/share_plus.dart';
import 'package:validated/validated.dart' as validate;

class PersonalFilePage extends GetView<PersonalFilePageController> {
  final Member viewMember;
  final bool isFromBottomTab;
  const PersonalFilePage({
    required this.viewMember,
    this.isFromBottomTab = false,
  });

  @override
  String get tag => viewMember.memberId;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PersonalFilePageController>(
        tag: viewMember.memberId)) {
      Get.put(
        PersonalFilePageController(
          personalFileRepos: PersonalFileService(),
          memberRepos: MemberService(),
          viewMember: viewMember,
        ),
        tag: viewMember.memberId,
        permanent:
            viewMember.memberId == Get.find<UserService>().currentUser.memberId,
      );
    } else {
      controller.fetchMemberData();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildBar(context),
      body: Obx(
        () {
          if (controller.isError.isTrue) {
            return ErrorPage(
              error: controller.error,
              onPressed: () => controller.initPage(),
              hideAppbar: true,
            );
          }

          if (controller.isLoading.isFalse) {
            return _buildBody();
          }

          return const PersonalFileSkeletonScreen();
        },
      ),
    );
  }

  PreferredSizeWidget _buildBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: isFromBottomTab
          ? IconButton(
              icon: Icon(
                PlatformIcons(context).gearSolid,
                color: readrBlack,
              ),
              onPressed: () {
                Get.to(() => SettingPage());
              },
            )
          : IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: readrBlack87,
              ),
              onPressed: () => Get.back(),
            ),
      title: Obx(
        () {
          String title = '';
          if (Get.find<UserService>().isMember.isFalse && isFromBottomTab) {
            title = 'personalFileTab'.tr;
          } else if (controller.isLoading.isTrue) {
            title = viewMember.customId;
          } else {
            title = controller.viewMemberData.value.customId;
          }
          return Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: readrBlack87,
            ),
          );
        },
      ),
      centerTitle: GetPlatform.isIOS,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      actions: [
        _optionButton(context),
      ],
    );
  }

  Widget _optionButton(BuildContext context) {
    return Obx(
      () {
        String shareButtonText = 'sharePersonalFile'.tr;
        bool showBlock = Get.find<UserService>().isMember.value;
        bool isBlock = controller.isBlock.value;
        if (viewMember.memberId ==
            Get.find<UserService>().currentUser.memberId) {
          shareButtonText = 'shareMyPersonalFile'.tr;
          showBlock = false;
        }

        return PlatformPopupMenu(
          icon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              PlatformIcons(context).ellipsis,
              color: readrBlack87,
              size: 26,
            ),
          ),
          options: [
            PopupMenuOption(
                label: 'copyPersonalFileLink'.tr,
                onTap: (option) async {
                  String url = '';

                  if (controller.isLoading.isTrue) {
                    url = await DynamicLinkHelper.createPersonalFileLink(
                        viewMember);
                  } else {
                    url = await DynamicLinkHelper.createPersonalFileLink(
                        controller.viewMemberData.value);
                  }
                  Clipboard.setData(ClipboardData(text: url));
                  showMeshToast(
                    icon: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    message: 'copiedLink'.tr,
                  );
                }),
            PopupMenuOption(
              label: shareButtonText,
              onTap: (option) async {
                String url = '';

                if (controller.isLoading.isTrue) {
                  url = await DynamicLinkHelper.createPersonalFileLink(
                      viewMember);
                } else {
                  url = await DynamicLinkHelper.createPersonalFileLink(
                      controller.viewMemberData.value);
                }
                Share.shareWithResult(url).then((value) {
                  if (value.status == ShareResultStatus.success) {
                    logShare('member', viewMember.memberId, value.raw);
                  }
                });
              },
            ),
            if (showBlock && !isBlock)
              PopupMenuOption(
                label: 'block'.tr,
                cupertino: (context, platform) => CupertinoPopupMenuOptionData(
                  isDestructiveAction: true,
                ),
                material: (context, platform) => MaterialPopupMenuOptionData(
                  child: Text(
                    'block'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                onTap: (option) async {
                  String title;
                  if (controller.isLoading.isTrue) {
                    title = '${'block'.tr} ${viewMember.customId} ?';
                  } else {
                    title =
                        '${'block'.tr} ${controller.viewMemberData.value.customId} ?';
                  }
                  await showPlatformDialog(
                    context: context,
                    builder: (context) => PlatformAlertDialog(
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      content: Text(
                        'blockAlertContent'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      actions: [
                        PlatformDialogAction(
                          child: Text(
                            'block'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            controller.blockMember();
                            Get.back();
                          },
                        ),
                        PlatformDialogAction(
                          child: Text(
                            'cancel'.tr,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (showBlock && isBlock)
              PopupMenuOption(
                label: 'unBlock'.tr,
                onTap: (option) => controller.unblockMember(),
              ),
          ],
          cupertino: (context, platform) => CupertinoPopupMenuData(
            cancelButtonData: CupertinoPopupMenuCancelButtonData(
              child: Text(
                'cancel'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              isDefaultAction: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return ExtendedNestedScrollView(
      onlyOneScrollInBody: true,
      physics: const AlwaysScrollableScrollPhysics(),
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: _memberDataWidget(),
          ),
          SliverToBoxAdapter(
            child: JustTheTooltip(
              content: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text(
                  'collectionTooltip'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              backgroundColor: const Color(0xFF007AFF),
              preferredDirection: AxisDirection.up,
              tailLength: 8,
              tailBaseWidth: 12,
              tailBuilder: (tip, point2, point3) => Path()
                ..moveTo(tip.dx, tip.dy)
                ..lineTo(point2.dx, point2.dy)
                ..lineTo(point3.dx, point3.dy)
                ..close(),
              controller: controller.tooltipController,
              offset: 4,
              shadow: const Shadow(color: Color.fromRGBO(0, 122, 255, 0.2)),
              barrierDismissible: false,
              triggerMode: TooltipTriggerMode.manual,
              isModal: true,
              child: const Divider(
                color: readrBlack10,
                thickness: 0.5,
                height: 0.5,
              ),
            ),
          ),
          SliverAppBar(
            pinned: true,
            primary: false,
            elevation: 0,
            toolbarHeight: 8,
            backgroundColor: Colors.white,
            bottom: TabBar(
              indicatorColor: tabBarSelectedColor,
              labelColor: readrBlack87,
              unselectedLabelColor: readrBlack30,
              indicatorWeight: 0.5,
              tabs: controller.tabs,
              controller: controller.tabController,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: controller.tabController,
        children: controller.tabWidgets,
      ),
    );
  }

  Widget _memberDataWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 20, 40, 24),
          child: Column(
            children: [
              Obx(
                () => ProfilePhotoWidget(
                  controller.viewMemberData.value,
                  40,
                  textSize: 40,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Obx(
                      () => ExtendedText(
                        controller.viewMemberData.value.nickname,
                        maxLines: 1,
                        joinZeroWidthSpace: true,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: readrBlack87,
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () {
                      if (controller.viewMemberData.value.verified) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: readrBlack87,
                          ),
                        );
                      }
                      return Container();
                    },
                  )
                ],
              ),
              const SizedBox(height: 4),
              Obx(
                () {
                  if (controller.viewMemberData.value.intro != null &&
                      controller.viewMemberData.value.intro!.isNotEmpty) {
                    return _buildIntro(controller.viewMemberData.value.intro!);
                  }

                  return Container();
                },
              ),
              const SizedBox(height: 12),
              Obx(
                () {
                  if (Get.find<UserService>().isMember.isTrue &&
                      controller.viewMemberData.value.memberId ==
                          Get.find<UserService>().currentUser.memberId) {
                    return _editProfileButton();
                  } else if (controller.isBlock.isTrue) {
                    return _blockWidget();
                  }

                  return FollowButton(
                    MemberFollowableItem(controller.viewMemberData.value),
                    expanded: true,
                    textSize: 16,
                  );
                },
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => RichText(
                    text: TextSpan(
                      text: _convertNumberToString(controller.pickCount.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: readrBlack87,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${'pick'.tr}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: readrBlack50,
                          ),
                        ),
                        if (controller.followerCount.value > 1 &&
                            Get.locale?.languageCode == 'en')
                          const TextSpan(
                            text: 's',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: readrBlack50,
                            ),
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 20,
              child: const VerticalDivider(
                color: readrBlack10,
                thickness: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.to(() => FollowerListPage(
                      viewMember: viewMember,
                    ));
              },
              child: Obx(
                () => RichText(
                  text: TextSpan(
                    text:
                        _convertNumberToString(controller.followerCount.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: readrBlack87,
                    ),
                    children: [
                      TextSpan(
                        text: '\n${'follower'.tr}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: readrBlack50,
                        ),
                      ),
                      if (controller.followerCount.value > 1 &&
                          Get.locale?.languageCode == 'en')
                        const TextSpan(
                          text: 's',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: readrBlack50,
                          ),
                        ),
                      const TextSpan(
                        text: ' ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: readrBlack50,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SvgPicture.asset(
                          personalFileArrowSvg,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 20,
              child: const VerticalDivider(
                color: readrBlack10,
                thickness: 0.5,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => FollowingListPage(
                          viewMember: viewMember,
                        ));
                  },
                  child: Obx(
                    () => RichText(
                      text: TextSpan(
                        text: _convertNumberToString(
                            controller.followingCount.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: readrBlack87,
                        ),
                        children: [
                          TextSpan(
                            text: '\n${'following'.tr} ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: readrBlack50,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: SvgPicture.asset(
                              personalFileArrowSvg,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _convertNumberToString(int number) {
    if (number >= 1000 && Get.locale?.languageCode == 'en') {
      double newNumber = number / 1000;
      return '${newNumber.toStringAsFixed(newNumber.truncateToDouble() == newNumber ? 0 : 1)}K';
    } else if (number >= 10000) {
      double newNumber = number / 10000;
      String tenThounsands = '萬';
      if (Get.locale == const Locale('zh', 'CN')) {
        tenThounsands = '万';
      }
      return '${newNumber.toStringAsFixed(newNumber.truncateToDouble() == newNumber ? 0 : 1)}$tenThounsands';
    } else {
      return number.toString();
    }
  }

  Widget _buildIntro(String intro) {
    List<String> introChar = intro.characters.toList();
    return RichText(
      text: TextSpan(
        text: introChar[0],
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: validate.isEmoji(introChar[0]) ? readrBlack : readrBlack50,
        ),
        children: [
          for (int i = 1; i < introChar.length; i++)
            TextSpan(
              text: introChar[i],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color:
                    validate.isEmoji(introChar[i]) ? readrBlack : readrBlack50,
              ),
            )
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _editProfileButton() {
    return OutlinedButton(
      onPressed: () async {
        final needReload = await Get.to(
          () => EditPersonalFilePage(),
          fullscreenDialog: true,
        );

        if (needReload is bool && needReload) {
          controller.fetchMemberData();
        }
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: readrBlack87, width: 1),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      ),
      child: Text(
        'editPersonalFile'.tr,
        softWrap: true,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 16,
          color: readrBlack87,
        ),
      ),
    );
  }

  Widget _blockWidget() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          'blockWidgetText'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: readrBlack50,
          ),
        ),
        GestureDetector(
          onTap: () => controller.unblockMember(),
          child: Text(
            'unBlock'.tr,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
