import 'package:easy_debounce/easy_debounce.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:readr/controller/comment/commentInputBoxController.dart';
import 'package:readr/controller/pick/pickableItemController.dart';
import 'package:readr/controller/storyPageController.dart';
import 'package:readr/getxServices/internetCheckService.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/pages/loginMember/loginPage.dart';
import 'package:share_plus/share_plus.dart';

class StoryAppBar extends GetView<StoryPageController> {
  final String newsId;
  const StoryAppBar(this.newsId);

  @override
  String get tag => newsId;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: ExtendedText(
        controller.newsListItem.url,
        joinZeroWidthSpace: true,
        style: const TextStyle(
          color: readrBlack87,
          fontSize: 13,
        ),
      ),
      actions: <Widget>[
        GetBuilder<StoryPageController>(
          tag: newsId,
          builder: (controller) {
            if (controller.isLoading || controller.isError) {
              return Container();
            }

            return Obx(
              () {
                return IconButton(
                  icon: Icon(
                    Get.find<PickableItemController>(tag: 'News$newsId')
                            .isBookmarked
                            .value
                        ? Icons.bookmark_outlined
                        : Icons.bookmark_border_outlined,
                    color: readrBlack87,
                    size: 26,
                  ),
                  tooltip: Get.find<PickableItemController>(tag: 'News$newsId')
                          .isBookmarked
                          .value
                      ? '移出書籤'
                      : '加入書籤',
                  onPressed: () async {
                    if (Get.find<UserService>().isMember.isFalse) {
                      Get.to(
                        () => const LoginPage(),
                        fullscreenDialog: true,
                      );
                    } else if (await Get.find<InternetCheckService>()
                        .meshCheckInstance
                        .hasConnection) {
                      Get.find<PickableItemController>(tag: 'News$newsId')
                          .isBookmarked
                          .toggle();
                      EasyDebounce.debounce(
                        'UpdateBookmark$newsId',
                        const Duration(milliseconds: 500),
                        () =>
                            Get.find<PickableItemController>(tag: 'News$newsId')
                                .updateBookmark(),
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: "伺服器連接失敗 請稍後再試",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  },
                );
              },
            );
          },
        ),
        GetBuilder<StoryPageController>(
          tag: newsId,
          builder: (controller) {
            if (controller.isLoading || controller.isError) {
              return Container();
            }

            return IconButton(
              icon: Icon(
                GetPlatform.isAndroid
                    ? Icons.share_outlined
                    : Icons.ios_share_outlined,
                color: readrBlack87,
                size: 26,
              ),
              tooltip: '分享',
              onPressed: () {
                Share.share(controller.newsListItem.url);
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.close_outlined,
            color: readrBlack87,
            size: 26,
          ),
          tooltip: '回前頁',
          onPressed: () async {
            if (Get.isRegistered<CommentInputBoxController>(
                    tag: 'News$newsId') &&
                Get.find<CommentInputBoxController>(tag: 'News$newsId')
                    .hasInput
                    .isTrue) {
              Widget dialogTitle = const Text(
                '確定要刪除留言？',
                style: TextStyle(
                  color: readrBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              );
              Widget dialogContent = const Text(
                '系統將不會儲存您剛剛輸入的內容',
                style: TextStyle(
                  color: readrBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              );
              List<Widget> dialogActions = [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '刪除留言',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '繼續輸入',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ];
              if (!GetPlatform.isIOS) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: dialogTitle,
                    content: dialogContent,
                    buttonPadding: const EdgeInsets.only(left: 32, right: 8),
                    actions: dialogActions,
                  ),
                );
              } else {
                await showDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: dialogTitle,
                    content: dialogContent,
                    actions: dialogActions,
                  ),
                );
              }
            } else {
              Get.back();
            }
          },
        ),
      ],
    );
  }
}
