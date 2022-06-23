import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';
import 'package:readr/controller/comment/commentInputBoxController.dart';
import 'package:readr/controller/storyPageController.dart';
import 'package:readr/getxServices/environmentService.dart';
import 'package:readr/helpers/analyticsHelper.dart';
import 'package:readr/models/newsListItem.dart';
import 'package:readr/pages/story/newsStoryWidget.dart';
import 'package:readr/pages/story/newsWebviewWidget.dart';
import 'package:readr/pages/story/readrStoryWidget.dart';
import 'package:readr/services/newsStoryService.dart';
import 'package:readr/services/pickService.dart';
import 'package:readr/services/storyService.dart';

class StoryPage extends GetView<StoryPageController> {
  final NewsListItem news;
  const StoryPage({
    required this.news,
  });

  @override
  String get tag => news.id;

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<StoryPageController>(tag: news.id)) {
      Get.find<StoryPageController>(tag: news.id).updateNewsData(news);
    } else {
      Get.put(
        StoryPageController(
          newsStoryRepos: NewsStoryService(),
          storyRepos: StoryServices(),
          pickRepos: PickService(),
          newsListItem: news,
        ),
        tag: news.id,
      );
    }

    logOpenStory(source: news.source?.title);

    Widget child;
    if (!news.fullContent) {
      child = NewsWebviewWidget(news.id);
    } else if (news.source?.id ==
        Get.find<EnvironmentService>().config.readrPublisherId) {
      child = ReadrStoryWidget(news.id);
    } else {
      child = NewsStoryWidget(news.id);
    }
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 0,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: child,
      ),
      onWillPop: () async {
        if (Get.isRegistered<CommentInputBoxController>(
                tag: news.controllerTag) &&
            Get.find<CommentInputBoxController>(tag: news.controllerTag)
                .hasInput
                .isTrue) {
          await showPlatformDialog(
            context: context,
            builder: (_) => PlatformAlertDialog(
              title: const Text(
                '確定要刪除留言？',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: const Text(
                '系統將不會儲存您剛剛輸入的內容',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              actions: [
                PlatformDialogAction(
                  onPressed: () => Get.back(closeOverlays: true),
                  child: PlatformText(
                    '刪除留言',
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.red,
                    ),
                  ),
                ),
                PlatformDialogAction(
                  onPressed: () => Get.back(),
                  child: PlatformText(
                    '繼續輸入',
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return true;
      },
    );
  }
}
