import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/helpers/errorHelper.dart';
import 'package:readr/models/member.dart';
import 'package:readr/pages/personalFile/bookmarkTabContent.dart';
import 'package:readr/pages/personalFile/collectionTabContent.dart';
import 'package:readr/pages/personalFile/pickTabContent.dart';
import 'package:readr/services/personalFileService.dart';

class PersonalFilePageController extends GetxController
    with GetTickerProviderStateMixin {
  final PersonalFileRepos personalFileRepos;
  Member viewMember;
  PersonalFilePageController({
    required this.personalFileRepos,
    required this.viewMember,
  });

  static PersonalFilePageController get to => Get.find();

  late final Rx<Member> viewMemberData;
  final pickCount = 0.obs;
  final followerCount = 0.obs;
  final followingCount = 0.obs;
  final bookmarkCount = 0.obs;

  final isLoading = true.obs;
  final isError = false.obs;
  dynamic error;

  late TabController tabController;
  final List<Tab> tabs = [];
  final List<Widget> tabWidgets = [];

  @override
  void onInit() {
    viewMemberData = Rx<Member>(viewMember);
    initPage();
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void initPage() async {
    isLoading.value = true;
    isError.value = false;
    try {
      await fetchMemberData();
      isLoading.value = false;
    } catch (e) {
      print('Fetch personal file error: $e');
      error = determineException(e);
      isError.value = true;
    }
  }

  Future<void> fetchMemberData() async {
    await Future.wait([
      personalFileRepos
          .fetchMemberData(viewMember)
          .then((value) => viewMemberData.value = value),
      Get.find<UserService>().fetchUserData(),
    ]);

    pickCount.value = viewMemberData.value.pickCount ?? 0;
    followerCount.value = viewMemberData.value.followerCount ?? 0;
    int followingMemberCount = viewMemberData.value.followingCount ?? 0;
    int followingPublisherCount =
        viewMemberData.value.followingPublisherCount ?? 0;
    followingCount.value = followingMemberCount + followingPublisherCount;
    bookmarkCount.value = viewMemberData.value.bookmarkCount ?? 0;
    _initializeTabController();
  }

  void _initializeTabController() {
    tabs.clear();
    tabWidgets.clear();

    tabs.add(
      const Tab(
        child: Text(
          '精選',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );

    tabWidgets.add(PickTabContent(
      viewMember: viewMemberData.value,
    ));

    if (viewMemberData.value.memberId !=
            Get.find<UserService>().currentUser.memberId ||
        bookmarkCount.value + pickCount.value > 0) {
      tabs.add(
        const Tab(
          child: Text(
            '集錦',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      );

      tabWidgets.add(CollectionTabContent(
        viewMember: viewMemberData.value,
      ));
    }

    if (viewMemberData.value.memberId ==
        Get.find<UserService>().currentUser.memberId) {
      tabs.add(
        const Tab(
          child: Text(
            '書籤',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      );

      tabWidgets.add(BookmarkTabContent());
    }

    // set controller
    tabController = TabController(
      vsync: this,
      length: tabs.length,
    );
  }
}
