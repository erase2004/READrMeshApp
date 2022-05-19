import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:readr/blocs/news/news_cubit.dart';
import 'package:readr/getxServices/environmentService.dart';
import 'package:readr/models/newsListItem.dart';
import 'package:readr/pages/story/newsStoryWidget.dart';
import 'package:readr/pages/story/newsWebviewWidget.dart';
import 'package:readr/pages/story/readrStoryWidget.dart';
import 'package:readr/services/newsStoryService.dart';
import 'package:readr/services/storyService.dart';

class StoryPage extends StatelessWidget {
  final NewsListItem news;

  const StoryPage({
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!news.fullContent) {
      child = NewsWebviewWidget(
        news: news,
      );
    } else if (news.source.id ==
        Get.find<EnvironmentService>().config.readrPublisherId) {
      child = ReadrStoryWidget(
        news: news,
      );
    } else {
      child = NewsStoryWidget(
        news: news,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => NewsCubit(
                newsStoryRepos: NewsStoryService(),
                storyRepos: StoryServices()),
          ),
        ],
        child: child,
      ),
    );
  }
}