import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:readr/controller/collection/addToCollectionPageController.dart';
import 'package:readr/controller/collection/collectionPageController.dart';
import 'package:readr/controller/collection/createAndEdit/descriptionPageController.dart';
import 'package:readr/controller/collection/createAndEdit/titleAndOgPageController.dart';
import 'package:readr/controller/personalFile/collectionTabController.dart';
import 'package:readr/getxServices/pubsubService.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/models/collection.dart';
import 'package:readr/models/timelineCollectionPick.dart';
import 'package:readr/pages/collection/collectionPage.dart';
import 'package:readr/services/collectionService.dart';

enum TimeDimension { yearAndDate, onlyMonth, onlyYear }

class TimeDimensionPageController extends GetxController {
  final CollectionRepos collectionRepos;
  final List<TimelineCollectionPick> timelineStory;
  final Collection? collection;
  TimeDimensionPageController(
    this.collectionRepos,
    this.timelineStory, {
    this.collection,
  });

  final isUpdating = false.obs;
  final hasChange = false.obs;
  bool editItemTime = false;
  final timeDimension = TimeDimension.yearAndDate.obs;
  final timelineStoryList = <TimelineCollectionPick>[].obs;

  //for CustomTimePage
  final year = 1970.obs;
  final month = RxnInt();
  final day = RxnInt();
  final time = Rxn<DateTime>();

  @override
  void onInit() {
    timelineStoryList.assignAll(timelineStory);
    ever<int>(year, (callback) {
      if (month.value != null && day.value != null) {
        if (day.value! > DateTime(callback, month.value! + 1, 0).day) {
          day.value = null;
          time.value = null;
        }
      }
    });
    ever<int?>(
      month,
      (callback) {
        if (callback != null && day.value != null) {
          if (day.value! > DateTime(year.value, callback + 1, 0).day) {
            day.value = null;
            time.value = null;
          }
        }
      },
    );
    ever<int?>(
      day,
      (callback) {
        if (callback == null) {
          time.value = null;
        }
      },
    );
    ever<List<TimelineCollectionPick>>(
      timelineStoryList,
      (callback) {
        if (callback != timelineStory) {
          hasChange.value = true;
        } else {
          hasChange.value = false;
        }
      },
    );
    super.onInit();
  }

  void updateTimeDimension(TimeDimension timeDimension, bool isEdit) {
    for (var element in timelineStoryList) {
      switch (timeDimension) {
        case TimeDimension.yearAndDate:
          if (isEdit) {
            element.month = element.month ?? element.news.publishedDate.month;
            element.day = element.day ?? element.news.publishedDate.day;
          } else {
            element.month = element.news.publishedDate.month;
            element.day = element.news.publishedDate.day;
          }
          element.time = null;
          break;
        case TimeDimension.onlyMonth:
          if (isEdit) {
            element.month = element.month ?? element.news.publishedDate.month;
          } else {
            element.month = element.news.publishedDate.month;
          }
          element.day = null;
          element.time = null;
          break;
        case TimeDimension.onlyYear:
          element.month = null;
          element.day = null;
          element.time = null;
          break;
      }
    }
    sortListByTime();
    this.timeDimension.value = timeDimension;
    timelineStoryList.refresh();
  }

  void sortListByTime() {
    timelineStoryList.sort((a, b) {
      // compare year
      int result = b.year.compareTo(a.year);
      if (result != 0) {
        return result;
      }

      //compare month
      if (a.month == null && b.month == null) {
        return b.news.publishedDate.compareTo(a.news.publishedDate);
      } else if (a.month == null) {
        return 1;
      } else if (b.month == null) {
        return -1;
      } else {
        result = b.month!.compareTo(a.month!);
        if (result != 0) {
          return result;
        }
      }

      // compare day
      if (a.day == null && b.day == null) {
        return b.news.publishedDate.compareTo(a.news.publishedDate);
      } else if (a.day == null) {
        return 1;
      } else if (b.day == null) {
        return -1;
      } else {
        result = b.day!.compareTo(a.day!);
        if (result != 0) {
          return result;
        }
      }

      // compare time
      if (a.time == null && b.time == null) {
        return b.news.publishedDate.compareTo(a.news.publishedDate);
      } else if (a.time == null) {
        return 1;
      } else if (b.time == null) {
        return -1;
      } else {
        result = b.time!.compareTo(a.time!);
        if (result != 0) {
          return result;
        } else {
          return b.news.publishedDate.compareTo(a.news.publishedDate);
        }
      }
    });
  }

  void createCollection() async {
    isUpdating.value = true;

    try {
      String imageId = await collectionRepos
          .createOgPhoto(
              ogImageUrlOrPath: Get.find<TitleAndOgPageController>()
                  .collectionOgUrlOrPath
                  .value)
          .timeout(
            const Duration(minutes: 1),
          );
      for (int i = 0; i < timelineStoryList.length; i++) {
        timelineStoryList[i].sortOrder = i;
      }
      Collection newCollection = await collectionRepos
          .createCollection(
            title: Get.find<TitleAndOgPageController>().collectionTitle.value,
            ogImageId: imageId,
            collectionPicks: timelineStoryList,
            description: Get.find<DescriptionPageController>()
                .collectionDescription
                .value,
            format: CollectionFormat.timeline,
          )
          .timeout(
            const Duration(minutes: 1),
          );

      Get.find<PubsubService>().addCollection(
        memberId: Get.find<UserService>().currentUser.memberId,
        collectionId: newCollection.id,
      );

      if (Get.isRegistered<CollectionTabController>(
          tag: Get.find<UserService>().currentUser.memberId)) {
        Get.find<CollectionTabController>(
                tag: Get.find<UserService>().currentUser.memberId)
            .fetchCollecitionList();
      }

      if (Get.isRegistered<AddToCollectionPageController>()) {
        Get.until(
          (route) {
            return route.settings.name == '/AddToCollectionPage';
          },
        );
        Get.back();
        _showResultToast();
      } else {
        Get.offUntil<GetPageRoute>(
          GetPageRoute(
            routeName: '/CollectionPage',
            page: () => CollectionPage(
              newCollection,
              isNewCollection: true,
            ),
          ),
          (route) {
            return route.settings.name == '/PersonalFilePage' || route.isFirst;
          },
        );
      }
    } catch (e) {
      print('Create collection error: $e');
      isUpdating.value = false;
      Fluttertoast.showToast(
        msg: "建立失敗 請稍後再試",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    isUpdating.value = false;
  }

  void _showResultToast() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: const Color.fromRGBO(0, 9, 40, 0.66),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(
            width: 6.0,
          ),
          Text(
            '成功加入集錦',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
    showToastWidget(
      toast,
      context: Get.overlayContext,
      animation: StyledToastAnimation.slideFromTop,
      reverseAnimation: StyledToastAnimation.slideToTop,
      position: StyledToastPosition.top,
      startOffset: const Offset(0.0, -3.0),
      reverseEndOffset: const Offset(0.0, -3.0),
      duration: const Duration(seconds: 3),
      //Animation duration   animDuration * 2 <= duration
      animDuration: const Duration(milliseconds: 250),
      curve: Curves.linear,
      reverseCurve: Curves.linear,
    );
  }

  void updateCollectionPicks(bool isAddToEmpty) async {
    isUpdating.value = true;

    try {
      await collectionRepos.updateCollectionPicks(
        collectionId: collection!.id,
        originList: isAddToEmpty ? [] : timelineStory,
        newList: timelineStoryList,
        format: CollectionFormat.timeline,
      );
      await Get.find<CollectionPageController>(tag: collection!.id)
          .fetchCollectionData();
      Get.back();
    } catch (e) {
      print('Update collection picks error: $e');
      Fluttertoast.showToast(
        msg: "更新失敗 請稍後再試",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      isUpdating.value = false;
    }
  }
}
