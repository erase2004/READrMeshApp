import 'package:get/get.dart';
import 'package:readr/getxServices/graphQLService.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/getxServices/environmentService.dart';
import 'package:readr/models/editorChoiceItem.dart';
import 'package:readr/models/newsListItem.dart';

abstract class EditorChoiceRepos {
  Future<List<EditorChoiceItem>> fetchEditorChoiceList();
  Future<List<EditorChoiceItem>> fetchNewsListItemList();
}

class EditorChoiceService implements EditorChoiceRepos {
  @override
  Future<List<EditorChoiceItem>> fetchEditorChoiceList() async {
    String query = """
    query(
      \$where: EditorChoiceWhereInput, 
      \$first: Int){
      allEditorChoices(
        where: \$where, 
        first: \$first, 
        sortBy: [sortOrder_ASC, createdAt_DESC]
      ) {
        link
        choice {
          id
          style
        }
      }
    }
    """;

    Map<String, dynamic> variables = {
      "where": {"state": "published"},
      "first": 3
    };

    final jsonResponse = await Get.find<GraphQLService>().query(
      api: Api.readr,
      queryBody: query,
      variables: variables,
      cacheDuration: 30.minutes,
    );

    List<EditorChoiceItem> editorChoiceList = [];
    for (int i = 0; i < jsonResponse.data!['allEditorChoices'].length; i++) {
      editorChoiceList.add(
          EditorChoiceItem.fromJson(jsonResponse.data!['allEditorChoices'][i]));
    }
    return editorChoiceList;
  }

  @override
  Future<List<EditorChoiceItem>> fetchNewsListItemList() async {
    const String query = '''
    query(
      \$storyIdList: [String!]
      \$followingMembers: [ID!]
      \$myId: ID
      \$urlList: [String!]
      \$urlFilter: String
      \$readrId: ID
      \$blockAndBlockedIds: [ID!]
    ){
      stories(
        where:{
          source:{
            id:{
              equals: \$readrId
            }
          }
          url:{
            contains: \$urlFilter
          }
          is_active:{
            equals: true
          }
          OR:[
            {
              content:{
                in: \$storyIdList
              }
            }
            {
              url:{
                in: \$urlList
              }
            }
          ]
        }
        orderBy:[
          {
            createdAt: desc
          },
          {
            published_date: desc
          },
        ]
      ){
        id
        title
        url
        content
        source{
          id
          title
          full_content
          full_screen_ad
        }
        full_content
        full_screen_ad
        paywall
        published_date
        createdAt
        og_image
        followingPicks: pick(
          where:{
            member:{
              id:{
                in: \$followingMembers
              }
            }
            state:{
              equals: "public"
            }
            kind:{
              equals: "read"
            }
            is_active:{
              equals: true
            }
          }
          orderBy:{
            picked_date: desc
          }
          take: 4
        ){
          member{
            id
            nickname
            avatar
            customId
            avatar_image{
              id
              resized{
                original
              }
            }
          }
        }
        otherPicks:pick(
          where:{
            member:{
              AND:[
                {
                  id:{
                    notIn: \$followingMembers
                    not:{
                      equals: \$myId
                    }
                  }
                }
                {
                  id:{
                    notIn: \$blockAndBlockedIds
                  }
                }
                {
                  is_active:{
                    equals: true
                  }
                }
              ]
            }
            state:{
              in: "public"
            }
            kind:{
              equals: "read"
            }
            is_active:{
              equals: true
            }
          }
          orderBy:{
            picked_date: desc
          }
          take: 4
        ){
          member{
            id
            nickname
            avatar
            customId
            avatar_image{
              id
              resized{
                original
              }
            }
          }
        }
        pickCount(
          where:{
            state:{
              in: "public"
            }
            is_active:{
              equals: true
            }
            member:{
              id:{
                notIn: \$blockAndBlockedIds
              }
              is_active:{
                equals: true
              }
            }
          }
        )
        commentCount(
          where:{
            state:{
              in: "public"
            }
            is_active:{
              equals: true
            }
            member:{
              id:{
                notIn: \$blockAndBlockedIds
              }
              is_active:{
                equals: true
              }
            }
          }
        )
      }
    }
    ''';

    List<String> followingMemberIds = [];
    for (var memberId in Get.find<UserService>().currentUser.following) {
      followingMemberIds.add(memberId.memberId);
    }

    List<EditorChoiceItem> editorChoiceList = await fetchEditorChoiceList();

    List<String> storyIdList = [];
    List<String> urlList = [];
    for (var element in editorChoiceList) {
      if (element.id != null) {
        storyIdList.add(element.id!);
      }

      if (element.url != null) {
        urlList.add(element.url!);
      }
    }

    Map<String, dynamic> variables = {
      "storyIdList": storyIdList,
      "followingMembers": followingMemberIds,
      "urlList": urlList,
      "myId": Get.find<UserService>().currentUser.memberId,
      "urlFilter": Get.find<EnvironmentService>().config.readrWebsiteLink,
      "readrId": Get.find<EnvironmentService>().config.readrPublisherId,
      "blockAndBlockedIds": Get.find<UserService>().blockAndBlockedIds,
    };

    final jsonResponse = await Get.find<GraphQLService>().query(
      api: Api.mesh,
      queryBody: query,
      variables: variables,
    );

    if (jsonResponse.data!['stories'].isNotEmpty) {
      for (var item in jsonResponse.data!['stories']) {
        NewsListItem news = NewsListItem.fromJson(item);
        int index = editorChoiceList.indexWhere((element) {
          if (element.id != null) {
            return element.id == news.content;
          } else {
            return element.url == news.url;
          }
        });
        if (index != -1) {
          editorChoiceList[index].newsListItem = news;
        }
      }
    }

    editorChoiceList.removeWhere((element) => element.newsListItem == null);
    return editorChoiceList;
  }
}
